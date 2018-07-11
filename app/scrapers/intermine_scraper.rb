
class IntermineScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Intermine Scraper',
		index_page: 'http://intermine.org/tutorials/'
    }
  end

  def scrape
      cp = add_content_provider(Tess::API::ContentProvider.new(
                                  title: "InterMine", #name
                                  url: "http://intermine.org", #url
                                  image_url: "https://cdn.rawgit.com/intermine/design-materials/ff1ec6bf/logos/intermine/intermine-300x37.png", #logo
                                  description: "nterMine integrates biological data sources, making it easy to query and analyse data.", #description
                                  content_provider_type: :project,
                                  node_name: :'UK'
                                ))  	

      #page = Nokogiri::HTML.parse(open(config[:index_page]).read)
      index = 'http://intermine.org/tutorials/'
      page = Nokogiri::HTML.parse(open(index).read)
      tutorials = page.xpath('/html/body/main/ul/li')
      
      tutorials.each do |tutorial|
	      	url = tutorial.children.first.attributes['href'].value
	      	title = tutorial.text.split('-').first
	      	description = tutorial.text
	      	event = Tess::API::Material.new(
	      		title: title,
	            url: url,
	            content_provider: cp,
	            short_description: description,
	            keywords: title.split(' ').first
	       )
			add_material(event)
	  end
	end
end
