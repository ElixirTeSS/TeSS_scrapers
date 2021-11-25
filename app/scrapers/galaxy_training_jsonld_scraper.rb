require 'nokogiri'
require 'yaml'

class GalaxyJsonldScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Galaxy Training network JSONLD scraper',
        sitemap: "https://training.galaxyproject.org/training-material/sitemap.xml"
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
      { title: 'Galaxy Training',
        url: "https://training.galaxyproject.org/training-material/sitemap.xml",
        image_url: 'https://raw.githubusercontent.com/galaxyproject/training-material/master/shared/images/GTNLogo1000.png',
        description: 'Collection of tutorials developed and maintained by the worldwide Galaxy community ',
        content_provider_type: :project#,
        # node_name: [:FR, :DE]
      }
    ))

    sitemap = open(config[:sitemap]).read
    locations = sitemap.scan(/<loc>([^<]*)<\/loc>/)
    locations = locations.to_a.flatten
    # Currently we'll just filter for slides/tutorials
    locations = locations.select{|x| x =~ /(slides|tutorial).html$/}

    locations.each do |location|
      puts location
      doc = Nokogiri::HTML(open(location))
      doc.search('//script[@type="application/ld+json"]').each do |element|
        materials = Tess::Rdf::MaterialExtractor.new(element.text, :jsonld).extract { |p| Tess::API::Material.new(p) }
        materials.each{|material|
          material.content_provider = cp
          add_material(material)
        }
      end
    end
  end
end
