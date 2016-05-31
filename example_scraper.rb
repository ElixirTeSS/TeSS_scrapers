# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api_client'

material = Material.new(title = 'New and Exciting Test Material',
                        url = 'https://www.elixir-europe.org/',
                        short_description = 'This record is totally awesome',
                        doi = 'N/A',
                        remote_updated_date = Time.now,
                        remote_created_date = nil)

false_material = Material.new(title = 'No such material has yet been uploaded',
                              url = 'https://www.elixir-europe.org/',
                              short_description = 'So this should fail',
                              doi = 'N/A',
                              remote_updated_date = Time.now,
                              remote_created_date = nil)

check = Uploader.check_material(material)
#check = Uploader.check_material(false_material)
puts check.inspect

if check.empty?
  puts 'No record by this name found. Creating it...'
  result = Uploader.create_material(material)
  puts result.inspect
else
  puts 'A record by this name already exists.'
end

