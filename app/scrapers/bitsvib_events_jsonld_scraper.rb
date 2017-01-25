require 'nokogiri'

class BitsvibEventsJsonldScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'VIB Bioinformatics Training and Services Events Scraper',
        root_url: 'http://dev.bits.vib.be/eulife/all_events.json'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "VIB Bioinformatics Training and Services",
          url: "https://www.bits.vib.be/",
          image_url: "http://www.vib.be/VIBMediaLibrary/Logos/Service_facilities/BITS_website.jpg",
          description: "Provider of Bioinformatics and software training, plus informatics services and resource management support.",
          content_provider_type: :organisation,
          node_name: :BE
        }))

    parsed_json = JSON.load(open(config[:root_url]))
    json_ld = StringIO.new(parsed_json['list'].to_json)

    events = Tess::Scrapers::RdfEventExtractor.new(json_ld, :jsonld).extract

    events.each do |event|
      event.content_provider = cp
      add_event(event)
    end
  end
end
