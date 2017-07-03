class BiviMaterialScraper < Tess::Scrapers::Scraper
  def self.config
  {
    name: 'BiVi Material Scraper',
    root_url: 'http://bivi.co',
    index_path: '/presentation-feed'
  }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new( title: "Bioinformatics Visualization",
                                                             url: config[:root_url],
                                                             image_url: "http://bivi.co/sites/default/files/logo.png",
                                                             description: "The Biological Visualisation Network (BiVi) provides a forum for dissemination, training and discussion for life-scientists to discover and promote complex data visualisation ideas and solutions. BiVi, funded by the BBSRC, is a central resource for information on bio-visualisation and is supplemented with annual meetings for networking and educational purposes, focussed around emerging trends in visualisation and challenges facing biology.",
                                                             content_provider_type: :organisation,
                                                             node_name: :UK
                                                             ))

    doc = Nokogiri::XML(open_url(config[:root_url] + config[:index_path]))

    items = doc.xpath('//channel/item')
    titles = doc.xpath('//channel/item/title')
    links = doc.xpath('//channel/item/link')
    descriptions = doc.xpath('//channel/item/description')
    pubDates = doc.xpath('//channel/item/pubDate')
    creators = doc.xpath('//channel/item/creator')

    0.upto(items.length - 1) do |n|
      # Main fields
      title,link,date = ''
      creator = []
      if titles[n]
        title = titles[n].inner_text()
      end
      if links[n]
        link = links[n].inner_text()
      end
      if pubDates[n]
        date = pubDates[n].inner_text()
      end
      if creators[n]
        creator = creators[n].inner_text().split(",").collect {|x| x.strip}
      end


      # Description fields: These seem always to appear in the same order and so one can match up e.g.
      # titles[0] with links[0] to create each record, then split descriptions[0] to get the various
      # parts thereof in the same order.
      descs =  descriptions[n].inner_text().split("<br />").collect {|y| y.gsub(/\n/,"")}.reject(&:empty?)
      short_description,event = ''
      presentation_type,bio_keywords,comp_keywords,presenter = []
      descs.each do |d|
        if d =~ /^#Presenter/
          presenter = d.gsub(/#Presenter:\s+/i,"").split(",").collect {|x| x.strip}
        elsif d =~ /^#Presentation/
          presentation_type = d.gsub(/#Presentation Type:\s+/i,"").split(",").collect {|x| x.strip}
        elsif d =~ /^#Event/
          event = d.gsub(/#Event:\s+/i,"")
        elsif d =~ /^#Biological/
          bio_keywords = d.gsub(/#Biological Keywords:\s+/i,"").split(",").collect {|x| x.strip}
        elsif d =~ /^#Computing/
          comp_keywords = d.gsub(/#Computing Keywords:\s+/i,"").split(",").collect {|x| x.strip}
        else
          short_description += d
        end
      end
      if event
        short_description += "\nCreated at: #{event}."
      end

      # Create the material from the information above
      m = add_material(Tess::API::Material.new(title: title,
                                               url: link,
                                               short_description: short_description,
                                               remote_updated_date: date,
                                               content_provider: cp,
                                               scientific_topic_names: bio_keywords + comp_keywords,
                                               keywords: bio_keywords + comp_keywords,
                                               resource_type: presentation_type,
                                               authors: [creator],
                                               contributors: [presenter]
                                              ))

    end
  end
end

__END__
  def parse_data(page)
    events = {}

    rss_feed = open_url(page)
    items = Nokogiri::XML(rss_feed).xpath('//item')
    items.each do |item|
      url = item.children.find{|x| x.name == 'link'}.text
      title_element = item.children.find{|x| x.name == 'title'}
      description = item.children.find{|x| x.name == 'description'}.text
      date, title = parse_title title_element.text
      start_date =  Time.parse(date)
      end_date = (start_date + duration_offset(description))
      events[url] = {
          title: title,
          description: description,
          start: start_date.to_s,
          end: end_date.to_s
      }
    end

    events
  end
