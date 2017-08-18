require 'nokogiri'
require 'linkeddata'
require 'geocoder'

class BmtcJsonldScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'BMTC JSON-LD Scraper',
        offline_url_mapping: {},
        root_url: 'http://www.birmingham.ac.uk',
        materials_path: '/facilities/metabolomics-training-centre/index.aspx'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Birmingham metabolomics Training Centre",
          url: "http://www.birmingham.ac.uk/facilities/metabolomics-training-centre/index.aspx",
          image_url: "",
          description: "Providing training to empower the next generation of metabolomics researchers. The Birmingham Metabolomics Training Centre will provide training to the metabolomics community in both analytical and computational methods. The training centre will partner with both the Phenome Centre Birmingham and the NERC Biomolecular Analysis Facility to provide vocational training courses in clinical and environmental metabolomics. A combination of both face-to-face and online courses will be provided.The training centre is directed by Professor Mark Viant, Dr Warwick Dunn, Dr Ralf Weber and Dr Catherine Winder.",
          content_provider_type: :organisation,
          node_name: :GB
        }))

    get_urls(config[:root_url] + config[:materials_path]).each do |url|
      begin
        doc = Nokogiri::HTML(open(url))
        events = []
        doc.search('//script[@type="application/ld+json"]').each do |element|
          begin
            events += Tess::Rdf::EventExtractor.new(element.text, :jsonld).extract { |p| Tess::API::Event.new(p) }
          rescue MultiJson::ParseError # Some invalid JSON in one of the script tags
          end
        end 
      rescue OpenURI::HTTPError
      end
      if events
        events.each do |event|
          event.url = url
          event.content_provider = cp
          event.latitude, event.longitude = get_location(event.postcode)
          add_event(event)
        end
      end
    end

  end

  private

  def get_urls(index_page)
    doc = Nokogiri::HTML(open(index_page))
    links_div = doc.search('//*[@id="form1"]/main/div/div/div/div[1]/ul[1]')
    return links_div.search('a').collect{|x| config[:root_url] + x['href']}
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
