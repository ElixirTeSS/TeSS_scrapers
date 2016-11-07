require 'icalendar'
require 'google_places'

class SoftwareCarpentryEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Software Carpentry Events Scraper',
        offline_url_mapping: {},
        root_url: 'http://software-carpentry.org',
        ical_path: '/workshops.ics',
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Software Carpentry",
          url: "http://software-carpentry.org/",
          image_url: "http://software-carpentry.org/img/software-carpentry-banner.png",
          description: "The Software Carpentry Foundation is a non-profit organization whose members teach researchers basic software skills.",
          content_provider_type: Tess::API::ContentProvider::PROVIDER_TYPE[:ORGANISATION]
        }))

    events = Icalendar::Event.parse(open_url(config[:root_url] + config[:ical_path]))

    events.each do |event|
      begin
        #@client = GooglePlaces::Client.new(ScraperConfig.google_api_key)
        #google_place = @client.spots_by_query(event.location, :language => 'en')
        #google_place = google_place.first || nil
        if event.description.start_with?('http://cannot.find.url/')
          puts "skipping #{event.summary} - no URL"
        else
          #HAX! A polish character was causing issues as it was being interpreted as ASCII. This forces everything into UTF-8 but loses the bad characters.
          summary = [event.summary].flatten.join(' ').force_encoding("ASCII-8BIT").encode('UTF-8', undef: :replace, replace: '')
          description = [event.description].flatten.join(' ').force_encoding("ASCII-8BIT").encode('UTF-8', undef: :replace, replace: '')
          add_event(Tess::API::Event.new(
              { content_provider: cp,
                title: "Software Carpentry - #{summary}",
                url: description,
                start_date: event.dtstart,
                end_date: event.dtend,
                description: "Find out more at #{description}",
                organizer: 'Software Carpentry',
                event_types: [Tess::API::Event::EVENT_TYPE[:workshops_and_courses]],
                latitude: event.geo.first,
                longitude: event.geo.last
              }))
        end
      end
      #,
      #    venue: event.location,
      #    city: google_place.city,
      #    country: google_place.country
    end
  end
end
