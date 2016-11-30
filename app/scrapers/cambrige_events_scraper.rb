require 'nokogiri'

class CambridgeEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Cambridge Events Scraper',
        offline_url_mapping: {},
        root_url: 'http://training.csx.cam.ac.uk/bioinformatics/event/',
        json_api_url: 'http://www.training.cam.ac.uk/api/v1/provider/BIOINFO/programmes?fetch=events.sessions,events.topics&format=json',
        training_base_url: 'http://training.csx.cam.ac.uk/bioinformatics/event/'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "University of Cambridge Bioinformatics Training", #name
          url: "http://training.csx.cam.ac.uk/bioinformatics/", #url
          image_url: "http://www.crim.cam.ac.uk/global/test/images/logo.png", #logo
          description: "We offer a broad range of undergraduate and postgraduate hands-on training courses focused on bioinformatics and computational biology. These training activities aim at enabling life scientists to effectively handle and interpret biological data.", #description
          content_provider_type: :organisation,
          node_name: :GB
        }))

    json = JSON.parse(open_url(config[:json_api_url]).read)
    programmes = json['result']['programmes']

#programmes.each{|y| y['events'].each{|x| puts "#{Time.at(x['startDate'].to_f/1000)}\n"}}

#Events are separated into years. There are three programmes: bioinfo-2015, bioinfo-2016, bioinfo-2017. Last one currently doesn't have dates - check for startDate before adding
    programmes.each do |programme|
      programme['events'].last(30).each do |event|
        if !event['startDate'].nil? and
            if event['title'].match(/^[CRUK:]/)
              puts "Skipping Cancer Research UK event" if verbose
            else
              add_event(Tess::API::Event.new(
                  { title: event['title'],
                    content_provider: cp,
                    url: config[:root_url] + event['eventId'].to_s,
                    description: markdownify_urls(event['description']),
                    start: Time.at(event['startDate'].to_f/1000), #Remove milliseconds before parsing
                    end: Time.at(event['endDate'].to_f/1000),
                    target_audience: parse_audience(event['targetAudience']),
                    scientific_topic_names: scientific_topics_for(event['topics']),
                    event_types: [:workshops_and_courses],
                    organizer: "University of Cambridge",
                    host_institutions: ['University of Cambridge Bioinformatics Training'],
                    venue: 'Craik-Marshall Building',
                    city: 'Cambridge',
                    country: 'United Kingdom',
                    postcode: 'CB2 3AR',
                    latitude: 52.2019652,
                    longitude: 0.1224858
                  })
)
            end
        end
      end
    end
  end

  private

  def parse_audience text
    if text.nil? or text.empty?
      return nil
    else
      # split list, remove weird 3 apostrophe strings, separate out extra note text
      parsed_text = text.split(',').collect{|x| x.gsub("\'\'\'", "").split('*')}
      # chuck away any empty strings
      parsed_text = parsed_text.flatten.reject{|x| x.empty?}
      # Some sentences need getting rid of like 'Further details regarding the charging policy are available here"'
      parsed_text = parsed_text.reject{|x| x.start_with?('Further details')}
      # Remove URLs - so things like this:
      #  [http://www.training.cam.ac.uk/bioinformatics/info/eligibility Affiliated Institutions]
      # Will read like this 
      #  Affiliated Institutions
      return parsed_text.collect do |x|
        if x.match(/\[(http[^\[]+)\s([^\[]+)\]/)
          x.gsub!(/\[(http[^\[]+)\s([^\[]+)\]/, '\2')
        else
          x
        end.strip
      end

    end
  end

  # Scientific topics are in <em data-iri='topic_0001'>Bioinformatics,</em><em data-i... etc form
  # Convert to hash to get value, parse as HTML and send extract the text. 
  def scientific_topics_for text
    a = text.collect{|x| x.to_hash['value'] unless x.nil?}
    parsed_topic = Nokogiri::HTML.parse(a.first) unless a.first.nil?
    topics = parsed_topic.search('em') unless parsed_topic.nil?
    if topics.nil?
      return []
    else
      return topics.collect{|x| x.text}
    end
  end

  def markdownify_urls description
    if description.nil? or description.empty?
      return description
    else
      #remove weird ''' apostrophe notation
      description.gsub!("\'\'\'", "")
      #URLs listed as [http://google.com this is the link text]. Find them and recode as markdown URL
      description.gsub!(/\[(http[^\]\s]+)\s([^\]]+)\]/, '[\2](\1)')
    end
  end

end
