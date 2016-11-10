require 'nokogiri'

class GobletRdfaScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Goblet RDFa Scraper',
        offline_url_mapping: {},
        root_url: 'http://www.mygoblet.org',
        courses_path: '/training-portal/courses-xml', # Unused?
        materials_path: '/training-portal/materials-xml'

    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "GOBLET",
          url: "http://www.mygoblet.org",
          image_url: "http://www.mygoblet.org/sites/default/files/logo_goblet_trans.png",
          description: "GOBLET, the Global Organisation for Bioinformatics Learning, Education and Training, is a legally registered foundation providing a global, sustainable support and networking structure for bioinformatics educators/trainers and students/trainees.",
          content_provider_type: :portal
        }))

    get_urls(config[:root_url] + config[:materials_path]).each do |url|
      # Have to provide a base_uri here or the RDF parser breaks when parsing a cached file.
      materials = Tess::Scrapers::RdfMaterialExtractor.new(open_url(url), :rdfa, base_uri: config[:root_url]).extract

      materials.each do |material|
        material.url = url
        material.remote_updated_date = Time.now
        material.content_provider = cp

        add_material(material)
      end
    end
  end

  private

  # Get all URLs from XML
  def get_urls(page)
    doc = Nokogiri::XML(open_url(page))
    urls = []

    doc.search('nodes > node').each do |node|
      url = nil
      node.search('URL').each do |t|
        url = t.inner_text
      end
      if url
        urls << url
      end
    end

    urls
  end

end
