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
          content_provider_type: :project#,
          # node_name: [:FR, :DE]
        })
    )   
    git_setup
    files = Dir["#{cache_file_path('git')}/metadata/*.yml"]
    files.each do |file|
      yaml = YAML.load_file(file)
      yaml['material'].each do |material|
        new_material = Tess::API::Material.new
        name = yaml['name']
        if material['slides'] == 'no'
          url = 'http://galaxyproject.github.io/training-material/' + yaml['name'] + '/' + material['type'] + 's/' + material['name']
          name = "#{name} - #{material['title']}" if material['title']
        elsif material['slides'] == 'yes'
          url = 'http://galaxyproject.github.io/training-material/' + yaml['name'] + '/slides/#1' 
          name = "#{name} - #{material['title']}" if material['title']
        else
          url = nil
        end
        if url
          new_material.url = url
          new_material.title = name
          new_material.short_description = yaml['summary']
          new_material.content_provider = cp
          new_material.doi = material['zenodo_link'] unless material['zenodo_link'].nil? || material['zenodo_link'].empty?
          new_material.authors = yaml['maintainers'].collect{|x| x['name']}
          #externals = []
          #externals << {title: "#{yaml['name']} Docker image", url: "https://github.com/#{yaml['docker_image']}"} unless yaml['docker_image'].nil? || yaml['docker_image'].empty?
          #externals << {title: "#{yaml['name']} Datasets", url: material['zenodo_link']} unless material['zenodo_link'].nil? || material['zenodo_link'].empty?
          #new_material.external_resources_attributes = externals
          puts add_material(new_material).inspect
        end
      end
    end
      #material = Tess::API::Event.new
  end
end
