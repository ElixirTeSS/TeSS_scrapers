require 'open-uri'
tgac_mat = open 'https://tess.elixir-uk.org/api/3/action/organization_show?id=the-genome-analysis-centre&include_datasets=true', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}
tgac_mats = JSON.parse(tgac_mat.read)

provider = tgac_mats['result']
materials = provider['packages']

cp = ContentProvider.new(
  provider['display_name'], #name
  provider['homepage'], #url
  provider['image_display_url'], #logo
  provider['description'], #description
)
cp.Uploader.create_or_update_content_provider(cp)
