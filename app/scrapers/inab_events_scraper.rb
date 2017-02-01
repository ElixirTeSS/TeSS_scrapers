require 'icalendar'
require 'google_places'

class InabEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'INAB',
        offline_url_mapping: {},
        root_url: 'http://www.inab.org/training',
        ical_path: '/calendar/export_execute.php?userid=2&authtoken=245644be1420086102e7c7a8d6ebe11c4515d405&preset_what=all&preset_time=custom',
        geocoder_cache: {} # A little cache to stop duplicate queries
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "INAB",
          url: "http://inab.org/",
          image_url: "http://www.inab.org/training/theme/image.php/mytheme/theme/1387625532/images/logo_inb",
          description: "Espanol Instituto Nacional de Bioinformatica",
          content_provider_type: :organisation
        }))

    file = open_url(config[:root_url] + config[:ical_path])
    events = Icalendar::Event.parse(file.set_encoding('utf-8'))

    events.each_slice(40) do |batch|
      batch.each do |event|
        begin
=begin
		  city = nil
          country = nil
          lat = event.geo.first
          lon = event.geo.last
          unless geo_cache(lat, lon).nil?
            city = geo_cache(lat, lon).address_components.select { |c| c['types'].include?('locality') }.first
            city = city['long_name'] if city
            country = geo_cache(lat, lon).address_components.select { |c| c['types'].include?('country') }.first
            country = country['long_name'] if country
           end
=end
      
            add_event(Tess::API::Event.new(
                { content_provider: cp,
                  title: event.summary,
                  url: config[:root_url],
                  start: event.dtstart,
                  end: event.dtend,
                  description: event.description,
                  organizer: 'INAB',
                  event_types: [:workshops_and_courses]
                }))

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


