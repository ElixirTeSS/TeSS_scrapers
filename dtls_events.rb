# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api'
require 'Nokogiri'

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


docs.each do |event|
  new_event = Event.new
  event.element_children.each do |element|
  	new_event.category = 'course'
  	new_event.provider = 'DTLS'
  	case element.name
      when 'title'
        new_event.title = element.text
      when 'link'
      	new_event.link = element.text
      when 'description'
      	new_event.description = element.text
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
  check = Uploader.check_event(new_event)
  puts check.inspect

  if check.empty?
    puts 'No record by this name found. Creating it...'
    result = Uploader.create_event(new_event)
    puts result.inspect
  else
    puts 'A record by this name already exists. Updating!'
    new_event.id = check['id']
    result = Uploader.update_event(new_event)
    puts result.inspect
  end
end

