require 'tess_api_client'
# require 'open-uri'
# bmtc_mat = open 'https://tess-old.elixir-uk.org/api/3/action/organization_show?id=bmtc', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}
# bmtc_mats = JSON.parse(tgac_mat.read)

json = '{"help": "https://tess-old.elixir-uk.org/api/3/action/help_show?name=organization_show", "success": true, "result": {"display_name": "Birmingham Metabolomics Training Centre", "approval_status": "approved", "image_display_url": "https://tess-old.elixir-uk.org/uploads/group/2015-11-06-133537.647231BMTC.jpg", "type": "organization", "title": "Birmingham Metabolomics Training Centre", "name": "bmtc", "is_organization": true, "state": "active", "node_id": "united-kingdom", "image_url": "2015-11-06-133537.647231BMTC.jpg", "groups": [], "users": [{"capacity": "admin", "name": "ralfweber"}], "packages": [{"name": "metabolomics-understanding-metabolism-in-the-21st-century", "title": "Metabolomics: Understanding Metabolism in the 21st Century"}], "homepage": "http://www.birmingham.ac.uk/facilities/metabolomics-training-centre/index.aspx", "id": "c1846463-4b20-4897-8747-713374341b1d", "tags": [], "description": "Providing training to empower the next generation of metabolomics researchers.\r\n\r\nThe Birmingham Metabolomics Training Centre will provide training to the metabolomics community in both analytical and computational methods. The training centre will partner with both the Phenome Centre Birmingham and the NERC Biomolecular Analysis Facility to provide vocational training courses in clinical and environmental metabolomics. A combination of both face-to-face and online courses will be provided.\r\n\r\nThe training centre is directed by Professor Mark Viant, Dr Warwick Dunn, Dr Ralf Weber and Dr Catherine Winder."}}'
bmtc_mats = JSON.parse(json)

provider = bmtc_mats['result']
materials = provider['packages']

cp = ContentProvider.new({
                             title: provider['display_name'], #name
                             url: provider['homepage'], #url
                             image_url: "http://preview.birmingham.ac.uk/Images/College-LES-only/biosciences/facilities/bmtc/12106-BMTC-lock-up-AW-02-small.png", #logo
                             description: provider['description'], #description
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION],
                             node: Node::NODE_NAMES[:GB]
                         })
cp = Uploader.create_or_update_content_provider(cp)

packages = ['{"help": "https://tess-old.elixir-uk.org/api/3/action/help_show?name=package_show", "success": true, "result": {"license_title": "License not specified", "maintainer": null, "relationships_as_object": [], "private": false, "maintainer_email": null, "num_tags": 0, "id": "184f36a2-80a8-4ef1-a8ac-4fdc5dadf3e7", "metadata_created": "2015-11-06T13:38:55.937106", "metadata_modified": "2015-12-15T13:28:10.771514", "author": "", "author_email": null, "state": "active", "version": null, "license_id": "notspecified", "type": "dataset", "resources": [], "num_resources": 0, "tags": [], "tracking_summary": {"total": 0, "recent": 0}, "node_id": "united-kingdom", "groups": [], "creator_user_id": "a9290bc7-5207-4e8f-bb8c-53781fa8524b", "relationships_as_subject": [], "organization": {"description": "Providing training to empower the next generation of metabolomics researchers.\r\n\r\nThe Birmingham Metabolomics Training Centre will provide training to the metabolomics community in both analytical and computational methods. The training centre will partner with both the Phenome Centre Birmingham and the NERC Biomolecular Analysis Facility to provide vocational training courses in clinical and environmental metabolomics. A combination of both face-to-face and online courses will be provided.\r\n\r\nThe training centre is directed by Professor Mark Viant, Dr Warwick Dunn, Dr Ralf Weber and Dr Catherine Winder.", "created": "2015-11-06T13:34:12.168960", "title": "Birmingham Metabolomics Training Centre", "name": "bmtc", "is_organization": true, "state": "active", "image_url": "2015-11-06-133537.647231BMTC.jpg", "revision_id": "2ad9b87c-f8d2-4f05-a268-8b50401f7d21", "type": "organization", "id": "c1846463-4b20-4897-8747-713374341b1d", "approval_status": "approved"}, "name": "metabolomics-understanding-metabolism-in-the-21st-century", "isopen": false, "url": "https://www.futurelearn.com/courses/metabolomics", "notes": "Discover how metabolomics is revolutionising our understanding of metabolism with this free online course.\r\n\r\nMetabolomics is an emerging field that aims to measure the complement of metabolites (the intermediates and products of metabolism) in living organisms. The complement of metabolites in a biological system is known as the metabolome and represents the downstream effect of an organism\u2019s genome and its interaction with the environment. Metabolomics has a wide application area across the medical and biological sciences and is attractive to both new and established scientists. In this course we will provide an introduction to metabolomics, explain why we want to study the metabolome and describe the current challenges in analysing the complement of metabolites in a biological system. We will describe the interdisciplinary approaches adopted in the metabolomics workflow and demonstrate how the combined efforts of scientist\u2019s from different disciplines is advancing this exciting field. By the end of the course the learner will understand how metabolomics can revolutionise our understanding of metabolism.\r\n\r\nThe course will be targeted towards final year undergraduate students from biology / chemical disciplines and medical students, but will also provide a valuable introduction to the metabolomics field for MSc and PhD students, and scientists at any stage in their careers. Metabolomics is a new tool to the scientific community and has widespread applications across the medical and biological sciences in academia and industry.\r\n", "owner_org": "c1846463-4b20-4897-8747-713374341b1d", "title": "Metabolomics: Understanding Metabolism in the 21st Century", "revision_id": "d060f7a0-3ec5-4f2f-b4b8-4424404493e1"}}']

packages.each do |package|
  # material = open "https://tess-old.elixir-uk.org/api/3/action/package_show?id=#{package['name']}", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}
  # material = JSON.parse(package) if material
  material = JSON.parse(package)
  material = material['result']
  new_material = Material.new
  new_material.title = material['title']  
  new_material.url = material['url']
  new_material.short_description = material['notes']
  new_material.keywords = material['tags']
  new_material.content_provider_id = cp['id']
  Uploader.create_or_update_material(new_material)
end

