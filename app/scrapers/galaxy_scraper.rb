require 'yaml'

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
    base_url = "http://galaxyproject.github.io/training-material"
    cp = add_content_provider(Tess::API::ContentProvider.new(
                                title: 'Galaxy Training',
                                url: base_url,
                                image_url: 'https://raw.githubusercontent.com/galaxyproject/training-material/master/shared/images/GTNLogo1000.png',
                                description: 'GitHub repository and its website companion containing a collection of training materials for teaching next generation sequencing data analysis uing Galaxy.',
                                content_provider_type: :project#,
                                # node_name: [:FR, :DE]
    ))
    git_setup
    files = Dir["#{cache_file_path('git')}/metadata/*.yaml"]
    files.each do |file|
      yaml = YAML.load_file(file)
      if yaml['material']
        yaml['material'].each do |material|
          new_material = Tess::API::Material.new
          name = "#{yaml['title']} - #{material['title']}" if material['title']
          description = yaml['summary']
          extra_slides = nil
          if material['enable'] == 'false'
            url = nil
          elsif material['type'] == 'tutorial'
            if material['hands_on']
              url = base_url + '/topics/' + yaml['name'] + '/tutorials/' + material['name'] + '/tutorial.html'
              new_material.resource_type = ['Tutorial']
              if material['slides']
                extra_slides = base_url + '/topics/' + yaml['name'] + '/tutorials/' + material['name'] + '/slides.html'
              end
            else
              url = base_url + '/topics/' + yaml['name'] + '/tutorials/' + material['name'] + '/slides.html'
              new_material.resource_type = ['Slides']
            end
            if material['questions']
              description += "\n\nQuestions of the tutorial:\n\n"
              material['questions'].each do |question|
                description += "- "  + question + "\n"
              end
            end
            if material['objectives']
              description += "\n\nObjectives of the tutorial:\n\n"
              material['objectives'].each do |objective|
                description += "- " + objective + "\n"
              end
            end
          elsif material['type'] == 'introduction'
            url = base_url + '/topics/' + yaml['name'] + '/slides/introduction.html'
          else
            url = ''
          end
          if url
            new_material.url = url
            new_material.title = name
            new_material.authors = material["contributors"]
            new_material.short_description = description
            new_material.content_provider = cp
            #new_material.authors = material['contributors'].collect{|x| x['name']}
            externals = []
            #externals << {title: "#{yaml['name']} Docker image", url: "https://github.com/#{yaml['docker_image']}"} unless yaml['docker_image'].nil? || yaml['docker_image'].empty?
            externals << {title: "#{yaml['title']} dataset", url: material['zenodo_link']} unless material['zenodo_link'].nil? || material['zenodo_link'].empty?
            externals << {title: "#{yaml['title']} slides", url: extra_slides} unless extra_slides.nil?
            new_material.external_resources_attributes = externals
            add_material(new_material)
          end
        end
      else
        puts "No material for #{file}"
      end
    end
  end
end
