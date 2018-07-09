require 'nokogiri'

class GobletRdfaScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Goblet RDFa Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.mygoblet.org',
        courses_path: '/training-portal/courses-xml', # Unused?
        materials_path: '/training-portal/materials-xml'

    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "GOBLET",
          url: "https://www.mygoblet.org",
          image_url: "https://www.mygoblet.org/sites/default/files/logo_goblet_trans.png",
          description: "GOBLET, the Global Organisation for Bioinformatics Learning, Education and Training, is a legally registered foundation providing a global, sustainable support and networking structure for bioinformatics educators/trainers and students/trainees.",
          content_provider_type: :portal
        }))

    get_urls(config[:root_url] + config[:materials_path]).each do |url|
      # Have to provide a base_uri here or the RDF parser breaks when parsing a cached file.
      materials = Tess::Rdf::MaterialExtractor.new(open_url(url), :rdfa, base_uri: config[:root_url]).extract { |p| Tess::API::Material.new(p) }

      materials.each do |material|
        material.url = url
        material.content_provider = cp
        material.keywords = format_keywords(material.keywords)
        add_material(material)
      end
    end
  end

  private

  def format_keywords(keywords)
    return keywords.collect do |keyword|
      if keyword.include?(config[:root_url])
        keyword = keyword.gsub("#{config[:root_url]}/topic-tags/", "")
        keyword = keyword.gsub('-', ' ')
        keyword = keyword.humanize
      end
    end
  end

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
