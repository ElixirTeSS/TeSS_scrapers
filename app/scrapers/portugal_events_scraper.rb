require 'nokogiri'

class PortugalEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'ELIXIR Portugal',
        root_url: 'http://elixir-portugal.org/events',
        base_url: 'http://elixir-portugal.org'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "ELIXIR Portugal",
          url: "https://elixir-portugal.org",
          image_url: "https://tess.elixir-europe.org/assets/nodes/logos/PT-9f2611b1953f3109fa81668d960e7068390f4ef69be8f4b950ec0e8d7b106503.png",
          description: "ELIXIR Portugal is organized as a consortium of Portuguese research institutions which are part of the national biological information network, BioData.pt. Like ELIXIR itself, the Portuguese node is a decentralized network of specialized centers, under a common hardware and software infrastructure, and with shared training and industry/entrepreneurship programmes.",
          content_provider_type: :organisation,
          node_name: :PT
        }))



	index = Nokogiri::HTML(open(config[:root_url]))
    urls = index.search('tbody a').map{|x| x.values}.flatten

    urls.each do |url|
	   	#url = 
	    html = open(config[:base_url] + url).read
		 #extract JSON with regex because passing whole JSON to RDFEventExtractor throws errors up.
	    a = /<script type="application\/ld\+json">(.*)<\/script>/m.match(html)

      if a
	      events = Tess::Rdf::EventExtractor.new(a[1], :jsonld).extract { |p| Tess::API::Event.new(p) }

	      events.each do |event|
	        event.content_provider = cp
	        add_event(event)
        end
      end
    end
  end
end