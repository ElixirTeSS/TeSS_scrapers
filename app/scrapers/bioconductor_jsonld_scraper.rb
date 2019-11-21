
require 'yaml'

class BioconductorJsonldScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Bioconductor JSONLD scraper',
        sitemap: "https://raw.githubusercontent.com/BiGCAT-UM/ELIXIR-Tox/master/tutorials/sitemap.xml"
    }
  end



  def scrape

    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: 'Bioconductor',
          url: 'https://www.bioconductor.org/help/course-materials/',
          image_url: 'https://www.bioconductor.org/images/logo_bioconductor.gif',
          description: 'Open development software project, based on the R programming language,
                        providing tools for the analysis of high-throughput genomic data. The project aims to enable
                        interdisciplinary research, collaboration and rapid development of scientific software.',
          content_provider_type: :project
        }))

    sitemap = open(config[:sitemap]).read
    
    locations = /<loc>(.*)<\/loc>/m.match sitemap 
    locations = locations.to_a
    locations = locations.drop(1) #remove match data
    locations.each do |location|
        location = location[0..-2] #strip trailing / character
        json = /<script type="application\/ld\+json">(.*?)<\/script>/m.match(open(location).read)
        materials = Tess::Rdf::MaterialExtractor.new(json, :jsonld).extract { |p| Tess::API::Material.new(p) }
        materials.each do |material|
            material.content_provider = cp
            add_material(material)
        end
    end

        
  end
end

