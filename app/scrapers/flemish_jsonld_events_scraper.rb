require 'nokogiri'

class FlemishJsonldEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Flemish Super Computing Events Scraper',
        root_url: 'http://dev.bits.vib.be/eulife/all_events-vrc.json'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new({ url: "https://www.vscentrum.be"})) #Metadata handled manually
	jsonld = open(config[:root_url]).read
	events = Tess::Rdf::EventExtractor.new(jsonld, :jsonld).extract { |p| Tess::API::Event.new(p) }
	events.each do |event|
		event.content_provider = cp
	    add_event(event)
	end
  end
end
