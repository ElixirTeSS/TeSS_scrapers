#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'

def parse_audience text
  if text.nil? or text.empty?
    return nil
  else
    # split list, remove weird 3 apostrophe strings, remove extra note text, chuck away the empties
    parsed_text = text.split(',').collect{|x| x.gsub("\'\'\'", "").split('*').first}.reject{|x| x.empty?}
    # Remove URLs in target audience
    parsed_text
    return parsed_text.collect do |x|
      if x.match(/\[(http[^\[]+)\s([^\[]+)\]/)
        x.gsub!(/\[(http[^\[]+)\s([^\[]+)\]/, '\2')
      else
        x
      end
    end
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



$root_url = 'http://csx.cam.ac.uk'
index_page = 'http://training.csx.cam.ac.uk/bioinformatics/event-timetable?startDate=02-09-2011&endDate=16-12-2017&group=&period=range'
$owner_org = 'cambridge'
$lessons = {}
$debug = ScraperConfig.debug?

cp = ContentProvider.new({
                             title: "University of Cambridge Bioinformatics Training", #name
                             url: "http://training.csx.cam.ac.uk/bioinformatics/", #url
                             image_url: "http://www.crim.cam.ac.uk/global/test/images/logo.png", #logo
                             description: "We offer a broad range of undergraduate and postgraduate hands-on training courses focused on bioinformatics and computational biology. These training activities aim at enabling life scientists to effectively handle and interpret biological data.", #description
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION],
                             node: Node::NODE_NAMES[:'UK']
                         })

cp = Uploader.create_or_update_content_provider(cp)

root_url = 'http://training.csx.cam.ac.uk/bioinformatics/event/'
json = JSON.parse(open('http://www.training.cam.ac.uk/api/v1/provider/BIOINFO/programmes?fetch=events.sessions&format=json').read)
programmes = json['result']['programmes']

#programmes.each{|y| y['events'].each{|x| puts "#{Time.at(x['startDate'].to_f/1000)}\n"}}

#Events are separated into years. There are three programmes: bioinfo-2015, bioinfo-2016, bioinfo-2017. Last one currently doesn't have dates - check for startDate before adding
programmes.each do |programme|
  programme['events'].last(30).each do |event|
    if !event['startDate'].nil? and
        if event['title'].match(/^[CRUK:]/)
          puts "Skipping Cancer Research UK event"
        else
          event = Event.new({
                                title: event['title'],
                                content_provider_id: cp['id'],
                                url: root_url + event['eventId'].to_s,
                                description: markdownify_urls(event['description']),
                                start_date: Time.at(event['startDate'].to_f/1000), #Remove milliseconds before parsing
                                end_date: Time.at(event['endDate'].to_f/1000),
                                target_audience: parse_audience(event['targetAudience']),
                                event_types: [Event::EVENT_TYPE[:workshops_and_courses]],
                                organizer: "University of Cambridge",
                                host_institutions: ['University of Cambridge Bioinformatics Training'],
                                venue: 'Craik-Marshall Building',
                                city: 'Cambridge',
                                country: 'United Kingdom',
                                postcode: 'CB2 3AR',
                                latitude: 52.2019652,
                                longitude: 0.1224858
                            })
          event = Uploader.create_or_update_event(event)
        end
    end
  end
end

