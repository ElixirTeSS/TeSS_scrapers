require 'nokogiri'
require 'geocoder'
require 'google_places'

class ElixirEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Elixir Events Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.elixir-europe.org',
        meetings_path: '/events/meetings/upcoming',
        workshops_path: '/events/workshops/upcoming',
        webinars_path: '/events/webinars/upcoming'
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
          content_provider_type: :organisation
        }))

    client = GooglePlaces::Client.new(Tess::API.config['google_api_key'])

    [[config[:meetings_path], :meetings_and_conferences],
     [config[:workshops_path], :workshops_and_courses],
     [config[:webinars_path], nil]].each do |path, event_type|
      0.upto(1) do |page_number|
        doc = Nokogiri::HTML(open_url(config[:root_url] + path + "?page=#{page_number}"))
        doc.css('.views-table tbody tr td:first a').map { |e| e['href'] }.each do |event_path|
          url = config[:root_url] + event_path
          events = Tess::Rdf::EventExtractor.new(open_url(url), :rdfa).extract { |p| Tess::API::Event.new(p) }

          events.each do |event|
            event.content_provider = cp
            event.event_types = [event_type] if event_type
            event.online = true if path == config[:webinars_path]
            event.url = url

            get_google_place_info(client, event)

            add_event(event)
          end
        end
      end
    end
  end

  private

  def get_google_place_info(client, event)
    location = [event.venue, event.city, event.country].reject(&:blank?).join(',')
    unless location.blank?
      google_place = client.spots_by_query(location, language: 'en')
      google_place = google_place.first
      if google_place
        event.latitude = google_place.lat
        event.longitude = google_place.lng
        event.postcode = google_place.postal_code
      end
    end
    puts "G: #{event.title}, #{event.latitude}, #{event.longitude}, #{event.postcode}"
  end

end
