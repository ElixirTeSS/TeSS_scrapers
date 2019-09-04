require 'nokogiri'

class EbiJsonScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'EBI Scraper',
        root_url: 'http://www.ebi.ac.uk',
        json_url: 'https://www.ebi.ac.uk/sites/ebi.ac.uk/files/data/ebi-events-tess-all.json'
    }
  end

  def scrape
      cp = add_content_provider(Tess::API::ContentProvider.new(
                                  title: "European Bioinformatics Institute (EBI)", #name
                                  url: "http://ebi.ac.uk/training", #url
                                  image_url: "http://www.ebi.ac.uk/miriam/static/main/img/EBI_logo.png", #logo
                                  description: "EMBL-EBI provides freely available data from life science experiments, performs basic research in computational biology and offers an extensive user training programme, supporting researchers in academia and industry.", #description
                                  content_provider_type: :organisation,
                                  node_name: :'EMBL-EBI',
                                  keywords: ["HDRUK"]
                                ))

      json_events = JSON::load(open(config[:json_url]))
      events = []
      json_events.each do |event|
        events += Tess::Rdf::EventExtractor.new(event.to_json, :jsonld).extract { |p| Tess::API::Event.new(p) }
      end
      
      events.each do |event|
        event.content_provider = cp
        event.keywords = ["HDRUK"]
        add_event(event)
      end
    end


end
