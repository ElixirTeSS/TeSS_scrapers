class GalaxyScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Galaxy Scraper',
        offline_url_mapping: {},
        root_url: 'https://microasp.upsc.se/ngs_trainers/Materials/tree/master',
        repo_url: 'https://github.com/galaxyproject/training-material/',
        folder_path: 'metadata/'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Galaxy Training",
          url: "http://galaxyproject.github.io/",
          image_url: "https://raw.githubusercontent.com/galaxyproject/training-material/master/shared/images/GTNLogo1000.png",
          description: "GitLab repository and its Wiki companion containing a collection of training materials for teaching next generation sequencing data analysis.",
          content_provider_type: :project,
          node_name: :FR
        }))

      material = Tess::API::Event.new
      add_material(material)

  end
end
