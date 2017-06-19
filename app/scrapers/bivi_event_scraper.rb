class BiviEventScraper < Tess::Scrapers::Scraper

  def self.config
  {
    root_url: 'http://bivi.co',
    index_path: '/event-feed'
  }
  end

  def scrape
    client = GooglePlaces::Client.new(Tess::API.config['google_api_key'])
    cp = add_content_provider(Tess::API::ContentProvider.new(title: "Bioinformatics Visualization",
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

    puts "Got #{items.length} events."

    0.upto(items.length - 1) do |n|
      # Main fields
      title,link,date,creator = ''
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
        creator = creators[n].inner_text()
      end


      # Description fields: These seem always to appear in the same order and so one can match up e.g.
      # titles[0] with links[0] to create each record, then split descriptions[0] to get the various
      # parts thereof in the same order.
      desc =  Sanitize.fragment(descriptions[n].inner_text(), :elements => ['html'])
      raw_dates = desc.scan(/#Dates:\s+(\d{4}-\d{2}-\d{2})\s+\d{2}:\d{2}:\d{2}\s+to\s+(\d{4}-\d{2}-\d{2})/).flatten
      if raw_dates.length == 0
        raw_dates = desc.scan(/#Dates:\s+(\d{4}-\d{2}-\d{2})\s+\d{2}:\d{2}:\d{2}/).flatten
        start = raw_dates[0]
      else
        start = raw_dates[0]
        stop = raw_dates[1]
      end
      location = desc.scan(/#Location:\s+([A-Za-z0-9\(\)\,\s]+)/).flatten.to_s
      darray = desc.split(/\n/)
      darray.delete_at(0)
      darray.pop(2)
      desc = darray.join('\n')


      begin
        unless location.blank?
          google_place = client.spots_by_query(location, language: 'en')
          google_place = google_place.first
          if google_place
            latitude = google_place.lat
            longitude = google_place.lng
          else
            latitude,longitude = nil
          end
        end
      rescue Exception => e
        puts "Failed to connect to Google places for '#{location}': #{e}"
      end

      new_event = Tess::API::Event.new(content_provider: cp,
                                       title: title,
                                       url: link,
                                       start: start,
                                       end: stop,
                                       description: desc,
                                       latitude: latitude,
                                       longitude: longitude,
                                       organizer: creator,
                                       event_types: [:workshops_and_courses]
                                      )
      add_event(new_event)


    end

  end
end