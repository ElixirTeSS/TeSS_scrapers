class GalaxyScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Galaxy Scraper',
        offline_url_mapping: {},
        root_url: 'https://microasp.upsc.se/ngs_trainers/Materials/tree/master',
        git_endpoint: 'https://github.com/galaxyproject/training-material.git',
        folder_path: 'metadata/'
    }
  end

  def git_setup
    git_path = cache_file_path('git', true)
    unless File.exists?(git_path)
      puts "Cloning git repo..."
      %x{git clone #{config[:git_endpoint]} #{git_path}}
    end
    %x{cd #{git_path} && git pull} unless offline
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

      git_setup
      files = Dir["#{cache_file_path('git')}/metadata/*.yml"]
      files.each do |file|
          yaml = YAML.load_file(file)
          yaml['material'].each do |material|
            material = Tess::API::Material.new
            if material['name']
                url = 'http://galaxyproject.github.io/training-material/' + yaml['name'] + '/' + material['type'] + 's/' + material['name']
                puts url
            end
            add_material(material)
          end
      end
      #material = Tess::API::Event.new
  end
end
