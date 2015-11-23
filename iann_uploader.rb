# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api'

require 'Nokogiri'


file_name = Time.now.strftime("%Y%m%d.txt")

if File.exists?(file_name)
  iann_content = File.open(file_name).read
  puts "Already have a copy of todays iAnn events so loaded from file: '#{file_name}'"
else
  iann_content = Net::HTTP.get('iann.pro', '/solr/select/?q=*&rows=20000&start=0')
  File.write(file_name, iann_content)
  puts "Retrieved new iAnn dump for today. Saved in file #{file_name}"
end


docs = Nokogiri::HTML(iann_content).xpath('//doc')

docs.each do |event|
  new_event = Event.new
  event.children.each do |element|
    case element.values
      when ['id']
        new_event.external_id = element.text
      when ['keyword'], ['public'],
          ['submission_comment'], ['submission_date'], ['submission_name'],
          ['submission_organization'], ['_version_'], ['submission_email'], ['image']
        puts "Ignored for element type #{element.values}"
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
    puts 'A record by this name already exists.'
  end
end

