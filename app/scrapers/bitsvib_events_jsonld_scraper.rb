require 'nokogiri'

class BitsvibEventsJsonldScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'VIB Bioinformatics Training and Services Events Scraper',
        root_url: 'https://dev.bits.vib.be/eulife/all_events.php'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "VIB Bioinformatics Training and Services",
          url: "https://www.bits.vib.be/",
          image_url: "http://www.vib.be/Style%20Library/VIB%20Styles/Images/Logo.gif",
          description: "Provider of Bioinformatics and software training, plus informatics services and resource management support.",
          content_provider_type: :organization,
          node_name: :BE
        }))

    jsonld = open(config[:root_url]).read
    events = Tess::Rdf::EventExtractor.new(jsonld, :jsonld).extract { |p| Tess::API::Event.new(p) }

    events.each do |event|
      event.content_provider = cp
      add_event(event)
    end
  end
end
