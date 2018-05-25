require 'yaml'

class GalaxyEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Galaxy Events Scraper',
        root_url: 'https://galaxyproject.org/events'
    }
  end


  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new({
                                title: 'Galaxy Project',
                                url: "#{config[:root_url]}",
                                #image_url: 'https://galaxyproject.org/images/galaxy_logo_hub_white.svg',
                                description: 'There are many approaches to learning how to use Galaxy. The most popular is probably to just dive in and use it. Galaxy is simple enough to use that you can do many analyses just by exploring the interface. However, you may miss much of the power this way.',
                                content_provider_type: :project#,
                                # node_name: [:FR, :DE]
    }))

      events_page = open_url(config[:root_url]).read
      events_json = events_page.scan(/<script type="application\/ld\+json">(.*?)<\/script>/m)

      events_json.each do |event|
        begin
          event = Tess::Rdf::EventExtractor.new(event.first, :jsonld).extract { |p| Tess::API::Event.new(p) }.first
          unless URI.extract(event.url)
            event.url = "#{config[:root_url]}#{event.url}"
          end
          event.content_provider = cp
          add_event(event) if event
        rescue
          next
        end
      end
    #Tess::Rdf::EventExtractor.new(events_page, :jsonld).extract { |p| Tess::API::Event.new(p) }
  end
end


