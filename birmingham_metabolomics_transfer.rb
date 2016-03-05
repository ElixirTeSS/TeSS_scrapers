require 'tess_api'
require 'open-uri'
tgac_mat = open 'https://tess.elixir-uk.org/api/3/action/organization_show?id=bmtc', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}
tgac_mats = JSON.parse(tgac_mat.read)

provider = tgac_mats['result']
materials = provider['packages']

cp = ContentProvider.new(
  provider['display_name'], #name
  provider['homepage'], #url
  provider['image_display_url'], #logo
  provider['description'], #description
)
cp = Uploader.create_or_update_content_provider(cp)

provider['packages'].each do |package|
  material = open "https://tess.elixir-uk.org/api/3/action/package_show?id=#{package['name']}", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE} 
  material = JSON.parse(material.read) if material 
  material = material['result']
  new_material = Material.new
  new_material.title = material['title']  
  new_material.url = material['url']
  new_material.short_description = material['notes']
  new_material.keywords = material['tags']
  new_material.content_provider_id = cp['id']
  Uploader.create_or_update_material(new_material)
end

