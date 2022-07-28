class IntermineScraper < Tess::Scrapers::Scraper
  def self.config
    {
      name: "Intermine Scraper",
      index_page: "http://intermine.org/tutorials/",
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
      title: "InterMine", #name
      url: "http://intermine.org", #url
      image_url: "https://cdn.rawgit.com/intermine/design-materials/ff1ec6bf/logos/intermine/intermine-300x37.png", #logo
      description: "nterMine integrates biological data sources, making it easy to query and analyse data.", #description
      content_provider_type: :project,
      node_name: :'UK',
    ))

    #page = Nokogiri::HTML.parse(open_url(config[:index_page]).read)
    index = "http://intermine.org/tutorials/"
    page = Nokogiri::HTML.parse(open_url(index).read)
    tutorials = page.xpath("/html/body/main/ul/li")

    tutorials.each do |tutorial|
      if !tutorial.children.first.attributes["href"].nil?
        url = tutorial.children.first.attributes["href"].value
        title = tutorial.text.split("-").first
        description = tutorial.text
        event = Tess::API::Material.new(
          title: title,
          url: url,
          content_provider: cp,
          description: description,
          keywords: title.split(" ").first,
        )
        add_material(event)
      end
    end

    #page = Nokogiri::HTML.parse(open_url(config[:index_page]).read)
    index = "http://intermine.org/training-workshops/"
    page = Nokogiri::HTML.parse(open_url(index).read)
    tutorials = page.xpath("/html/body/div/section/ul/li/a")
    tutorials.each do |tutorial|
      if !tutorial.attributes["href"].nil?
        url = tutorial.attributes["href"].value
        # Complete relative URL paths
        if !url.include? "http"
          url = index + url
        end
        title = tutorial.children.text
        description = title
        event = Tess::API::Material.new(
          title: title,
          url: url,
          content_provider: cp,
          description: description,
          keywords: title.split(" ").first,
        )
        add_material(event)
      end
    end
  end
end
