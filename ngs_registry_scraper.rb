#!/usr/bin/env ruby
require 'open-uri'
require 'tess_api'


$lessons = {}
$debug = false
$json_file = 'https://bioinformatics.upsc.se/trainers/details.json'
$owner_org = 'ngs_registry'
$topics = {}
$root_url = 'https://microasp.upsc.se/ngs_trainers/Materials/tree/master/'

$lessons = JSON.parse(open($json_file).read)

# Create or update the organisation.
cp = ContentProvider.new(
    "NGS Registry",
    "https://microasp.upsc.se/ngs_trainers/Materials/wikis/home",
    "",
    "Git repository that contains various teaching materials and describes the usages of them")
cp = Uploader.create_or_update_content_provider(cp)


# do the uploads

#TODO: Exclusion list - 'Guidelines for this folder'
exclude_list_urls = %w(
 https://microasp.upsc.se/ngs_trainers/Materials/tree/master/Content/RNA-Seq/Nicolas_Delhomme/EMBO-Oct-2014/01_EMBO-October-2014-Introduction.md
 https://microasp.upsc.se/ngs_trainers/Materials/tree/master/Content/README.md
 https://microasp.upsc.se/ngs_trainers/Materials/tree/master/Content/Prerequisite/201505-RNA-Seq-ChIP-Seq-Data-Analysis.md
 https://microasp.upsc.se/ngs_trainers/Materials/tree/master/Content/RNA-Seq/Benilton_Carvalho/SimpleRNASeqExample.md
)
$lessons.each do |lesson|
  relative_path = lesson[0]
  unless exclude_list_urls.include?($root_url + relative_path)
    ngs_material = lesson[1]
    
    material = Material.new
      material.title = ngs_material['title']
      material.url = $root_url + relative_path
      material.content_provider_id = cp['id']
      full_md_description = ngs_material['full']

      sections = ["## Keywords\n", "## Target audience (at least beginner/advanced)\n", "## Description\n"]

      if full_md_description.nil?
        material.short_description = ngs_material['title']
      else
        keywords_index = ngs_material['full'].find_index(sections[0])
        if !keywords_index.nil?
          puts ngs_material['full'][keywords_index+1]
          a = ngs_material['full'][keywords_index+1].split(',')
          material.keywords = a
        end

        audience_index = ngs_material['full'].find_index(sections[1])
        if !audience_index.nil?
          material.target_audience = ngs_material['full'][audience_index+2]
        end

=begin
#Not sure about this. Maybe should just use the FULL description rather than succinct.
      description_index = ngs_material['full'].find_index(sections[2])
      if !description_index.nil?
        material.short_description = ngs_material['full'][description_index+1]
      else
        material.short_description = ngs_material['full'].join('')
      end
=end
        material.short_description = ngs_material['full'].join('')

        material.authors = ngs_material['authors']

        material.scientific_topic_names = [ngs_material['ontologies'] + material.keywords].flatten
      end
      material['title']
    Uploader.create_or_update_material(material)
  end
end