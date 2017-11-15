require 'icalendar'
require 'google_places'

class SoftwareCarpentryEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Software Carpentry Events Scraper',
        offline_url_mapping: {},
        root_url: 'https://software-carpentry.org',
        ical_path: '/workshops.ics',
        geocoder_cache: {} # A little cache to stop duplicate queries
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Software Carpentry",
          url: "https://software-carpentry.org/",
          image_url: "https://software-carpentry.org/img/software-carpentry-banner.png",
          description: "The Software Carpentry Foundation is a non-profit organization whose members teach researchers basic software skills.",
          content_provider_type: :organisation
        }))

    file = open_url(config[:root_url] + config[:ical_path])
    events = Icalendar::Event.parse(file.set_encoding('utf-8'))

    events.each_slice(40) do |batch|
      batch.each do |event|
        begin
          city = nil
          country = nil
          lat = event.geo.first
          lon = event.geo.last
          unless (geo = geo_cache(lat, lon)).nil?
            city = geo.address_components.select { |c| c['types'].include?('locality') }.first
            city = city['long_name'] if city
            country = geo.address_components.select { |c| c['types'].include?('country') }.first
            country = country['long_name'] if country
          end
          if event.description.start_with?('http://cannot.find.url/') && verbose
            puts "skipping #{event.summary} - no URL"
          else
            summary = [event.summary].flatten.join(' ')
            description = [event.description].flatten.join(' ')
            add_event(Tess::API::Event.new(
                { content_provider: cp,
                  title: "Software Carpentry - #{summary}",
                  url: description,
                  start: event.dtstart,
                  end: event.dtend,
                  description: "Find out more at #{description}",
                  organizer: 'Software Carpentry',
                  event_types: [:workshops_and_courses],
                  latitude: lat,
                  longitude: lon,
                  venue: event.location,
                  city: city,
                  country: country
                }))
          end
        end
      end
      sleep 1.5 # Sleep between batches to avoid hitting Google's API rate limit (temporarily until we can find a better way)
    end
  end

  private

  def geo_cache(lat, lon)
    config[:geocoder_cache]["#{lat},#{lon}"] ||= Geocoder.search([lat, lon]).first
  end
end
