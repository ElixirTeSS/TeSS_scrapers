
class SheffieldScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Sheffield Bioinformatics Core',
        repo: 'https://github.com/sheffield-bioinformatics-core/sheffield-bioinformatics-core.github.io',
        gh_events_path: 'training',
        site_base: 'http://sbc.shef.ac.uk/training',
        git_repo: '/bc.git'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Sheffield Bioinformatics Core",
          url: "http://sbc.shef.ac.uk//training/",
          image_url: "http://sheffield-bioinformatics-core.github.io//images/site-logo.png",
          description: "The Sheffield Bioinformatics Core Facility aims to develop and advance the training and application of bioinformatics and computational biology to biological research, biomedical research and public health in Sheffield",
          content_provider_type: :organisation
        }))

    git_setup
    
    cache_file_path('git')
    files = Dir["#{cache_file_path('git')}/#{config[:gh_events_path]}/*.md"]
    files.reject!{|x|x.include?('index.md')}
    
    files.each do |file|
      begin 
        eventyaml = YAML.load_file(file)
        event = Tess::API::Event.new({
          description: eventyaml['description'],
          content_provider: cp,
          event_types: [:workshops_and_courses],
          url: "#{config[:site_base]}/#{File.basename(file).chomp('.md')}",
          title: eventyaml['title'],

          start: formatted_time(eventyaml['startTime'], eventyaml['startDate']),
          end: formatted_time(eventyaml['endTime'], eventyaml['endDate']),
          venue: eventyaml['venue'],
          city: "#{eventyaml['city'].capitalize if !eventyaml['city'].nil?}",
          country: eventyaml['country'],
          postcode: eventyaml['postcode'],          

          contact: eventyaml['contact'],
          #difficulty_level: [eventyaml['difficulty']],
          keywords: eventyaml['keywords']
         })
         add_event(event)
       rescue
       end

    end
  end

  private

  #Horrible Hacks. Date formatted as time: 18.3, date: 2018-04-20. 
  #Need to add a 0 to time string and replace period for colon to get Time.parse to work
  def formatted_time time,date 
    if time and date
      hours = (time.to_s + '0').gsub('.',':')
      Time.parse("#{date} #{hours}")
    else
      return nil
    end
  end

  def git_setup
    git_path = cache_file_path('git', true)
    unless File.exists?(git_path)
      puts "Cloning git repo..."
      %x{git clone #{config[:repo]}.git #{git_path}}
    end
    %x{cd #{git_path} && git pull} unless offline
  end

  def parse_data
  end

end
