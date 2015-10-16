# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api'

material = Material.new(title = 'More Test Material',
                        url = 'https://www.elixir-europe.org/',
                        short_description = 'This record is awesome',
                        doi = 'N/A',
                        remote_updated_date = Time.now,
                        remote_created_date = nil)


result = Uploader.create_material(material)

puts result.inspect
