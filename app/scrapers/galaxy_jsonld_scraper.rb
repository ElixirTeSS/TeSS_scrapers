require 'yaml'

class GalaxyJsonldScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Galaxy Scraper'
    }
  end

  def scrape
    base_url = "http://galaxyproject.github.io/training-material"
    cp = add_content_provider(Tess::API::ContentProvider.new(
                                title: 'Galaxy Training',
                                url: base_url,
                                image_url: 'https://raw.githubusercontent.com/galaxyproject/training-material/master/shared/images/GTNLogo1000.png',
                                description: 'GitHub repository and its website companion containing a collection of training materials for teaching next generation sequencing data analysis uing Galaxy.',
                                content_provider_type: :project#,
                                # node_name: [:FR, :DE]
    ))
    test = "https://training.galaxyproject.org/training-material/topics/introduction/"

    
    
        courses = Tess::Rdf::CourseExtractor.new(open(test).read, :jsonld).extract do |course|
            Tess::API::Material.new(course) 
        end
        courses.each do |course|
            course.content_provider = cp
            add_material(course)
            puts course.inspect
        end
    
end
end
