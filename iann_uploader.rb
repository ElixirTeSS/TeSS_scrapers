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
      when ['category']
        new_event.category = element.text
      when ['title']
        new_event.title = element.text
      when ['link']
        new_event.link = element.text
      when ['keyword'], ['public'],
          ['submission_comment'], ['submission_date'], ['submission_name'],
          ['submission_organization'], ['_version_']
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


=begin
event = Event.new(external_id='ae10fc5c-ba6a-4be8-85c6-24e5310c96b3',
                  title='Cambridge Computational Biology Institute Annual Symposium',
                  subtitle='',
                  link="http://www.ccbi.cam.ac.uk/Events/Workshops/symp_12.php",
                  provider='CCBI',
                  field='Bioinformatics',
                  description='',
                  category=["meeting", "event"],
                  start_date='2012-05-24T23:00:00Z',
                  end_date='2012-05-24T23:00:00Z',
                  sponsor='CCBI',
                  venue='Centre for Mathematical Sciences',
                  city='Cambridge',
                  county='',
                  country='United Kingdom',
                  postcode='',
                  latitude=52.2101038,
                  longitude=0.1019566)


=begin

false_material = Material.new(title = 'No such material has yet been uploaded',
                              url = 'https://www.elixir-europe.org/',
                              short_description = 'So this should fail',
                              doi = 'N/A',
                              remote_updated_date = Time.now,
                              remote_created_date = nil)

=end
=begin

check = Uploader.check_event(event)
#check = Uploader.check_material(false_material)
puts check.inspect

if check.empty?
  puts 'No record by this name found. Creating it...'
  result = Uploader.create_event(event)
  puts result.inspect
else
  puts 'A record by this name already exists.'
end

=end
