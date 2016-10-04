# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api_client'
require 'nokogiri'

$debug = ScraperConfig.debug?

cp = ContentProvider.new({
                             title: "DTLS - Dutch Techcentre For Life Sciences", #name
                             url: "http://www.dtls.nl", #url
                             image_url: "http://www.dtls.nl/wp-content/themes/dtls/images/logo.png", #logo
                             description: "DTL focuses on the great potential of high-end technologies in pioneering life science research, and on the skills and solutions to professionally use computers to deal with the ever-growing data streams in research.", #description
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION],
                             node: Node::NODE_NAMES[:NL]
                         })
cp = Uploader.create_or_update_content_provider(cp)

dtls_dir = 'dtls'
Dir.mkdir(dtls_dir) unless Dir.exists?(dtls_dir) 
dtls_file = dtls_dir + '/dtls_events_' +Time.now.strftime("%Y%m%d.txt")

if File.exists?(dtls_file)
  dtls_content = File.open(dtls_file).read
  puts "Already have a copy of todays dtls events so loaded from file: '#{dtls_file}'."
else
  dtls_content = Net::HTTP.get('www.dtls.nl', '/courses/feed/?filter_course=active')
  File.write(dtls_file, dtls_content)
  puts "Retrieved new dtls dump for today. Saved in file #{File.absolute_path(dtls_file)}."
end

docs = Nokogiri::XML(dtls_content).xpath('//item')

#fields = docs.first.element_children.collect{|x| x.name}
#locations = docs.collect{|x| x.element_children.collect{|x| x.text if x.name == 'location'}.compact}.flatten  

docs.each do |event_item|
  event = Event.new
  event_item.element_children.each do |element|
    event.content_provider_id = cp['id']
  	event.event_types = [Event::EVENT_TYPE[:workshops_and_courses]]
  	case element.name
      when 'title'
        event.title = element.text
      when 'link'
        #Use GUID field as probably more stable
      	#event.url = element.text
      when 'creator'
        #event.creator = element.text
        # no creator field. Not sure needs one
      when 'guid'
        event.url = element.text
      when 'description'
      	event.description = element.text
      when 'location'
        event.venue = element.text
      when 'provider'
        event.organizer = element.text
      when 'courseDate'
        event.start = element.text
      when 'courseEndDate'
        event.end = element.text
      when 'latitude'
        event.latitude = element.text
      when 'longitude'
        event.longitude = element.text
      when 'pubDate'
        # Not really needed
      else
      	#chuck away
    end
    if event.end.nil? or event.end.empty?
      event.end = event.start
    end

  end
   Uploader.create_or_update_event(event)
   #puts event.inspect
end

