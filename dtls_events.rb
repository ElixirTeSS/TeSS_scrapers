# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api'
require 'Nokogiri'

$debug = Config.debug?

cp = ContentProvider.new(
    "DTLS - Dutch Techcentre For Life Sciences",
    "https://www.dtls.nl",
    "http://www.dtls.nl/wp-content/themes/dtls/images/logo.png",
    "DTL focuses on the great potential of high-end technologies in pioneering life science research, and on the skills and solutions to professionally use computers to deal with the ever-growing data streams in research."
    )
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

docs.first.element_children.each{|x| x.name}

docs.each do |event_item|
  event = Event.new
  event_item.element_children.each do |element|
    event.content_provider_id = cp['id']
  	event.category = 'course'
  	event.provider = 'DTLS'
  	case element.name
      when 'title'
        event.title = element.text
      when 'link'
      	event.link = element.text
      when 'description'
      	event.description = element.text
      when 'creator'
      	# no creator field. Not sure needs one
      when 'guid'
      	# Same as link?
      when 'pubDate'
      	# Not really needed
      else
      	#chuck away
    end
  end
  Uploader.create_or_update_event(event)
end

