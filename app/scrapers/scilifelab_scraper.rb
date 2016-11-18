class ScilifelabScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'SciLifeLab Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.scilifelab.se/',
        events_path: 'education/courses/',
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "SciLifeLab",
          url: "https://www.scilifelab.se",
          image_url: "https://www.scilifelab.se/wp-content/themes/wpbootstrap/images/logotype-scilifelab.png",
          description: "Science for Life Laboratory, SciLifeLab, is a national center for molecular biosciences with focus on health and environmental research. SciLifeLab is a national resource and a collaboration between four universities: Karolinska Institutet, KTH Royal Institute of Technology, Stockholm University and Uppsala University.",
          content_provider_type: :organisation,
          node_name: :SE
        }))


    events = parse_data(config[:events_path])

    events.each do |url, data|
      event = Tess::API::Event.new(
          { title: data['title'],
            url: url,
            content_provider: cp,
            start: data['start_date'],
            end: data['end_date'],
            event_types: [:workshops_and_courses],
          })
      if data['location']
        location = data['location']
        if location == 'Internet'
          event.online = true
        else
          client = GooglePlaces::Client.new(Tess::API.config['google_api_key'])
          if !location.empty?
            google_place = client.spots_by_query(location, :language => 'en').first || nil
            event.latitude = google_place.lat
            event.longitude = google_place.lng
            event.city = location
          end
        end
      end
      #print event.inspect
      add_event(event)
    end
  end

  private

  def parse_data(page)
    events = {}

    doc = Nokogiri::HTML(open_url("#{config[:root_url]}/#{page}"))

    links = doc.css("div.archive-entry").map do |lesson|
      #puts "LESSON: #{lesson.inspect}"
      url = lesson.css('a')[0]['href'].strip
      title = lesson.css('h4').text.strip
      details = lesson.css('p')[0].text.strip
      description = lesson.css('p')[1].text.strip
      parts = details.split(/,/)
      dates = parts[0].split(/ - /)
      location = parts[1].split(/ \| /)[1]
      type = parts[1].split(/ \| /)[0]
      start_date = dates[0]
      end_date = dates[0]

      events[url] = {}
      events[url]['title'] = title
      events[url]['description'] = description
      events[url]['location'] = location
      events[url]['start_date'] = start_date
      events[url]['end_date'] = end_date
      events[url]['type'] = type

    end


    events

  end

end