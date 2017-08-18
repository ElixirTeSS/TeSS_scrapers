require 'nokogiri'
require 'geocoder'

class EbiJsonScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'EBI Scraper',
        offline_url_mapping: {},
        root_url: 'http://www.ebi.ac.uk',
        json_url: 'http://www.ebi.ac.uk/sites/ebi.ac.uk/files/data/ebi-events-tess-all.json'
    }
  end

  def scrape
      cp = add_content_provider(Tess::API::ContentProvider.new(
         { title: "European Bioinformatics Institute (EBI)", #name
          url: "http://ebi.ac.uk/training", #url
          image_url: "http://www.ebi.ac.uk/miriam/static/main/img/EBI_logo.png", #logo
          description: "EMBL-EBI provides freely available data from life science experiments, performs basic research in computational biology and offers an extensive user training programme, supporting researchers in academia and industry.", #description
          content_provider_type: :organisation,
          node_name: :'EMBL-EBI'
      }))

      json_events = JSON::load(open(config[:json_url]))
      events = []
      json_events.each do |event|
        events += Tess::Rdf::EventExtractor.new(event.to_json, :jsonld).extract { |p| Tess::API::Event.new(p) }
      end
      
      events.each do |event|
        event.content_provider = cp
        unless event.latitude and event.longitude
          event.latitude, event.longitude = get_location("#{event.venue || ''} #{event.postcode || ''}")
        end
        add_event(event)
      end
    end


  def get_location(venue)
    lat, lon = nil
    unless (loc = Geocoder.search(venue)).empty?
      lat = loc[0].data['geometry']['location']['lat']
      lon = loc[0].data['geometry']['location']['lng']
    end
    [lat, lon]
  end
end
