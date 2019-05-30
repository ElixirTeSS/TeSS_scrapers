require 'nokogiri'

class FlemishJsonldEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Flemish Super Computing Events Scraper',
        root_url: 'https://dev.bits.vib.be/eulife/all_events-vrc.json'
    }
  end

  def scrape

    cp = add_content_provider(Tess::API::ContentProvider.new(
      {
        "title":"Flemish Supercomputer Centre",
        "description":"The Flemish Supercomputer Centre (VSC) is a virtual centre making supercomputer 
                   infrastructure available for both the academic and industrial world. This centre 
                  is managed by the Research Foundation - Flanders (FWO) in partnership with the five Flemish university associations.",
        "url":"https://www.vscentrum.be",
        "keywords":["Computing"]
     }
     )) #Metadata handled manually
  	jsonld = open(config[:root_url]).read
  	events = Tess::Rdf::EventExtractor.new(jsonld, :jsonld).extract { |p| Tess::API::Event.new(p) }
  	events.each do |event|
  	    event.content_provider_id = cp.id
  	    add_event(event)
  	end
  end
end
