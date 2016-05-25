require 'tess_api'

url = "https://www.futurelearn.com/courses/collections/genomics"
rdfa = RDF::Graph.load(url, format: :rdfa)
events = RdfaExtractor.parse_rdfa(rdfa, 'Event')

bioinformatics_search = 'https://www.futurelearn.com/search?utf8=%E2%9C%93&q=bioinformatics'
rdfa = RDF::Graph.load(bioinformatics_search, format: :rdfa)
events.concat(RdfaExtractor.parse_rdfa(rdfa, 'Event'))

#Format such as P4W
def duration_in_days duration
    parsed = /P(?<value>\d+)(?<unit>\w+)/.match(duration)
    if parsed 
        case parsed['unit']
        when 'W'
            return parsed['value'].to_i * 7 #no of days
        when 'D'
            return parsed['value'].to_i
        end
    end
    return nil
end

cp = ContentProvider.new(
    "Future Learn",
    "https://www.futurelearn.com/courses/collections/genomics",
    "http://static.tumblr.com/1f4d7873a6ff8a8c0d571adf0d4e867f/ejyensv/ubIn1b1rl/tumblr_static_fl_logo_white.jpg",
    "Discover the growing importance of genomics in healthcare research, diagnosis and treatment, with these free online courses. Learn with researchers and clinicians from leading universities and medical schools."
    )
cp = Uploader.create_or_update_content_provider(cp)

events.each do |event|
    begin
        rdfa = RDF::Graph.load(event['schema:url'], format: :rdfa)
        event = RdfaExtractor.parse_rdfa(rdfa, 'Event')
        event = event.first
        
        unless event['schema:startDate'].nil? or event['schema:startDate'].empty?
            start_date = DateTime.parse(event['schema:startDate'])     
            if start_date and start_date.is_a?(DateTime)
                upload_event = Event.new(
                    id=nil,
                    content_provider_id = cp['id'],
                    external_id = nil,
                    title = event['schema:name'], 
                    subtitle = nil,
                    url = event['schema:url'],
                    provider = event['schema:organizer'],
                    field = nil,
                    description = event['schema:description'],
                    keywords = [],
                    category = nil,
                    start_date = start_date,
                    end_date = (start_date + duration_in_days(event['schema:duration'])).to_s
                  ) 
            end
            Uploader.create_or_update_event(upload_event)
        end
    rescue => ex
      puts ex.message
   end
end






=begin

puts events.count
events.each do |event|
 #   begin
        rdfa = RDF::Graph.load(event['schema:url'], format: :rdfa)
        event = RdfaExtractor.parse_rdfa(rdfa, 'Event')
        event = event.first
        
        unless event['schema:startDate'].nil? or event['schema:startDate'].empty?
            start_date = DateTime.parse(event['schema:startDate'])             
            if start_date and start_date.is_a?(DateTime)
                upload_event = Event.new(
                    id=nil,
                    content_provider_id = cp['id'],
                    external_id = nil,
                    title = event['schema:name'], 
                    subtitle = nil,
                    url = event['schema:url'],
                    provider = event['schema:organizer'],
                    field = nil,
                    description = event['schema:description'],
                    keywords = [],
                    category = nil,
                    start_date = start_date,
                    end_date = (start_date + duration_in_days(event['schema:duration'])).to_s
                  ) 
            Uploader.create_or_update_event(upload_event)
            end
        end
   # rescue => ex
  #    puts ex.message
  #  end
end
=end
