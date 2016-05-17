
require 'rdf/rdfa'
require 'open-uri'
require 'nokogiri'
require 'tess_api'
require 'digest/sha1'


url = "https://www.futurelearn.com/courses/collections/genomics"
rdfa = RDF::Graph.load(url, format: :rdfa)
events = RdfaExtractor.parse_rdfa(rdfa, 'Event')


cp = ContentProvider.new(
    "Future Learn",
    "https://www.futurelearn.com/courses/collections/genomics",
    "http://static.tumblr.com/1f4d7873a6ff8a8c0d571adf0d4e867f/ejyensv/ubIn1b1rl/tumblr_static_fl_logo_white.jpg",
    "Discover the growing importance of genomics in healthcare research, diagnosis and treatment, with these free online courses. Learn with researchers and clinicians from leading universities and medical schools."
    )
cp = Uploader.create_or_update_content_provider(cp)


events.each do |event|
    rdfa = RDF::Graph.load(event['schema:url'], format: :rdfa)
    event = RdfaExtractor.parse_rdfa(rdfa, 'Event')
    begin
        event = event.first
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
            start_date = event['schema:startDate'],
            end_date = event['schema:startDate'] # + event['schema:duration']
          ) 
        Uploader.create_or_update_event(upload_event)
        rescue => ex
          puts ex.message
       end
end
