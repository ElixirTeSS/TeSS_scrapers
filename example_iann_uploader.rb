# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api_client'

event = Event.new({external_id:'ae10fc5c-ba6a-4be8-85c6-24e5310c96b3',
                  title:'Cambridge Computational Biology Institute Annual Symposium',
                  subtitle:'',
                  link:"http://www.ccbi.cam.ac.uk/Events/Workshops/symp_12.php",
                  provider:'CCBI',
                  field:'Bioinformatics',
                  description:'',
                  category:["meeting", "event"],
                  start_date:'2012-05-24T23:00:00Z',
                  end_date:'2012-05-24T23:00:00Z',
                  sponsor:'CCBI',
                  venue:'Centre for Mathematical Sciences',
                  city:'Cambridge',
                  county:'',
                  country:'United Kingdom',
                  postcode:'',
                  latitude:52.2101038,
                  longitude:0.1019566})


=begin
false_material = Material.new(title = 'No such material has yet been uploaded',
                              url = 'https://www.elixir-europe.org/',
                              short_description = 'So this should fail',
                              doi = 'N/A',
                              remote_updated_date = Time.now,
                              remote_created_date = nil)
=end

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

