
require 'icalendar'
require 'google_places'


class PraceEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Prace Events Scraper',
        offline_url_mapping: {},
        root_url: 'https://events.prace-ri.eu',
        ical_path: '/category/2/events.ics',
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "PRACE",
          url: "http://prace.eu/",
          image_url: "https://www.csc.fi/documents/10180/153484/prace-logo.png/1c2d412b-c20c-43b8-926d-6febf042f341?t=1403875523387",
          description: "Partnership for Advanced Computing in Europe",
          content_provider_type: :portal
        }
    ))

    file = open_url(config[:root_url] + config[:ical_path])
    events = Icalendar::Event.parse(file.set_encoding('utf-8'))

    events.each do |event|
      begin
        #@client = GooglePlaces::Client.new(ScraperConfig.google_api_key)
        #google_place = @client.spots_by_query(event.location, :language => 'en')
        #google_place = google_place.first || nil
        #puts google_place
         add_event(Tess::API::Event.new(
              { content_provider: cp,
                title: event.summary,
                url: event.url,
                start: event.dtstart,
                end: event.dtend,
                description: event.description,
                organizer: 'Prace',
                event_types: [:workshops_and_courses]                
              }))
      end
      #   latitude: event.geo.first,
#         longitude: event.geo.last
      #    venue: event.location,
      #    city: google_place.city,
      #    country: google_place.country
    end
  end
end

