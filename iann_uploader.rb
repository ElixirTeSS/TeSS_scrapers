# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api'
require 'Nokogiri'

iann_dir = 'iann'
Dir.mkdir(iann_dir) unless Dir.exists?(iann_dir) 
iann_file = iann_dir + '/iann_events_' +Time.now.strftime("%Y%m%d.txt")

if File.exists?(iann_file)
  iann_content = File.open(iann_file).read
  puts "Already have a copy of todays iAnn events so loaded from file: '#{iann_filee}'."
else
  iann_content = Net::HTTP.get('iann.pro', '/solr/select/?q=*&rows=20000&start=0')
  File.write(iann_file, iann_content)
  puts "Retrieved new iAnn dump for today. Saved in file #{File.absolute_path(iann_file)}."
end


docs = Nokogiri::HTML(iann_content).xpath('//doc')

docs.each do |event|
  new_event = Event.new
  event.children.each do |element|
    case element.values
      when ['id']
        new_event.external_id = element.text
      when ['public'],
          ['submission_comment'], ['submission_date'], ['submission_name'],
          ['submission_organization'], ['_version_'], ['submission_email'], ['image']
        puts "Ignored for element type #{element.values}"
      when ['category'], ['field'], ['keyword']
        new_event.send("#{element.values.first}=", element.children.collect{|children| children.text})
      else
        puts "Set event.#{element.values.first} to #{ element.text}"
        new_event.send("#{element.values.first}=", element.text)
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

