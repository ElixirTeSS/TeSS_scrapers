require 'nokogiri'
require 'geocoder'
require 'google_places'

class ElixirEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Elixir Events Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.elixir-europe.org'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "ELIXIR", #name
          url: "https://www.elixir-europe.org/", #url
          image_url: "https://media.eurekalert.org/multimedia_prod/pub/web/38675_web.jpg",
          description: "Building a sustainable European infrastructure for biological information, supporting life science research and its translation to medicine, agriculture, bioindustries and society.
ELIXIR unites Europe’s leading life science organisations in managing and safeguarding the massive amounts of data being generated every day by publicly funded research. It is a pan-European research infrastructure for biological information.
ELIXIR provides the facilities necessary for life science researchers - from bench biologists to cheminformaticians - to make the most of our rapidly growing store of information about living systems, which is the foundation on which our understanding of life is built.", #description
          content_provider_type: Tess::API::ContentProvider::PROVIDER_TYPE[:ORGANISATION]
        }))

    events = {}

    0.upto(1) do |page_number|
      doc = Nokogiri::HTML(open_url(config[:root_url] + "/events/workshops/upcoming?page=#{page_number}"))

      doc.search('tbody > tr').each do |row|
        oldlink = nil
        row.css("div.custom-right").map do |node|
          name = node.at_css("h3 a").text.strip
          link = node.at_css("h3 a")['href']
          events[link] = {'title' => name}
          oldlink =  link
        end
        row.css("div.date-display-range").search('span').each do |span|
          if span['class'] == 'date-display-start'
            events[oldlink]['start_date'] = span.text.strip
          elsif span['class'] == 'date-display-end'
            events[oldlink]['end_date'] = span.text.strip
          end
        end
        row.css("div.date-location").search('.icon').each do |icon|
          if icon['data-icon'] == 'i'
            events[oldlink]['category'] = icon.text.strip
          elsif icon['data-icon'] == 'r'
            # Nothing to do here...
          elsif icon['data-icon'] == '['
            events[oldlink]['location'] = icon.text.strip
          end
        end
      end
    end

    events.each do |path, data|
      client = GooglePlaces::Client.new(Tess::API.config['google_api_key'])
      if data['location']
        location = data['location'].split(',').first
        if location and !location.empty?
          google_place = client.spots_by_query(location, :language => 'en')
          google_place = google_place.first || nil
        end
      end
      event = Tess::API::Event.new(
          { content_provider: cp,
            title: data['title'],
            url: config[:root_url] + path,
            start: data['start_date'],
            end: data['end_date'],
            event_types: [Tess::API::Event::EVENT_TYPE[:workshops_and_courses]]
          })
      if google_place
        event.venue = google_place.name
        event.latitude = google_place.lat
        event.longitude = google_place.lng
        event.city = google_place.city
        event.country = google_place.country
        event.postcode = google_place.postal_code
      else
        event.venue = data['location']
      end

      add_event(event)
    end
  end

end
