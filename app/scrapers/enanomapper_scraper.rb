require 'yaml'
require 'nokogiri'


class EnanomapperScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'ENanoMapper Scraper',
        root_url: 'https://enanomapper.github.io/tutorials',
        repo: 'https://github.com/enanomapper/tutorials',
    }
  end


  def scrape

    cp = add_content_provider(Tess::API::ContentProvider.new({
                                title: 'eNanoMapper',
                                url: "http://enanomapper.net/",
                                image_url: 'http://www.enanomapper.net/sites/all/themes/theme807/logo.png',
                                description: 'eNanoMapper developed a computational infrastructure for toxicological data management of engineered nanomaterials (ENMs) based on open standards, ontologies and an interoperable design to enable a more effective, integrated approach to European research in nanotechnology. eNanoMapper supports the collaborative safety assessment for ENMs by creating a modular, extensible infrastructure for transparent data sharing, data analysis, and the creation of computational toxicology models for ENMs. eNanoMapper was funded by the European Union’s Seventh Framework Programme for research, technological development and demonstration under grant agreement no 604134.',
                                content_provider_type: :project
    }))
 

    sitemap_url = 'https://raw.githubusercontent.com/enanomapper/tutorials/master/sitemap.xml'
    sitemap = Nokogiri::XML.parse(open(sitemap_url).read)
    ns = {"ns" => "http://www.sitemaps.org/schemas/sitemap/0.9"}
    locs = sitemap.xpath('/ns:urlset/ns:url/ns:loc', ns)

    materials = []

    locs.collect{|x| x.text}.each do |file|
    	tutorial = open(file).read
    	json = (/<script type="application\/ld\+json">(.*?)<\/script>/m.match(tutorial))[1]
      json = JSON.parse(json)
      json['url'] = json['url'][0]['url'] if json['url'].is_a?(Array)
    	materials += Tess::Rdf::MaterialExtractor.new(json.to_json, :jsonld).extract { |p| Tess::API::Material.new(p) }
    end

    materials.each do |material|
      material.content_provider = cp

      add_material(material)
    end

=begin

    # This does a manual extraction rather than using MaterialExtractor as had issues. May try again later, this:
    # Loads the markdown, extracts just YAML, parses YAML, and sets-up Material object with each YAML key 

     events_page = open_url(config[:root_url]).read
	 

 	git_setup
 	files = Dir["#{cache_file_path('git')}/*/*.md"]
     puts files 

	 site_url = 'https://enanomapper.github.io/tutorials/'
	 file_path = 'BrowseOntology/Tutorial%20browsing%20eNM%20ontology'



	 github_url = 'https://raw.githubusercontent.com/enanomapper/tutorials/master/'
	 

	 page = open("#{github_url}#{file_path}.md").read
	 yaml_data = page.match /---(.*?)---*./m 
	 yaml = YAML.load(yaml_data.to_s)
	 tm = yaml['trainingMaterial'] 
	 material = Tess::API::Material.new()
 	 material.target_audience = tm['audience'].collect{|x| x['name']}
 	 material.scientific_topic_names = tm['genre'].collect{|x| x['url']}
 	 material.title = tm['name'] 	 
 	 material.authors = tm['author'].collect{|x| x['name']}
 	 material.difficulty_level = tm['difficultyLevel']
 	 material.keywords = tm['keywords'].split(',')
 	 #material.licence = tm['license']
 	 material.description = "Training resource for eNanomapper"
 	 material.url = "#{site_url}#{file_path}.html"
 	 material.content_provider = cp
 	 puts material.inspect
 	 add_material(material)
  end

  def git_setup
    git_path = cache_file_path('git', true)
    unless File.exists?(git_path)
      puts "Cloning git repo..."
      %x{git clone #{config[:repo]}.git #{git_path}}
    end
    %x{cd #{git_path} && git pull} unless offline
  end

=end
end

end


