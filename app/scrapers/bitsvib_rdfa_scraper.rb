require 'rdf/rdfa'
require 'nokogiri'

class BitsvibRdfaScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'VIB Bioinformatics Training and Services RDFa Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.bits.vib.be',
        materials_path: '/training-list'
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

    get_urls(config[:root_url] + config[:materials_path]).each do |url|
      materials = Tess::Rdf::MaterialExtractor.new(open_url(url), :rdfa).extract { |p| Tess::API::Material.new(p) }

      materials.each do |material|
        material.url = url
        material.remote_updated_date = Time.now
        material.content_provider = cp

        add_material(material)
      end
    end
  end

  private

  def get_urls(index_page)
    doc = Nokogiri::HTML(open_url(index_page))
    urls = []
    first = doc.css('div.moduletable')
    first.each do |f|
      links = f.search('a')
      links.each do |l|
        urls << config[:root_url] + l['href']
      end
    end

    urls
  end
end
