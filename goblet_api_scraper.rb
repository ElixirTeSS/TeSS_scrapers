#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api'


$courses = 'http://www.mygoblet.org/training-portal/courses-xml'
$materials = 'http://www.mygoblet.org/training-portal/materials-xml'
$owner_org = 'goblet'
$lessons = {}
$debug = Config.debug?

def parse_data(page)
  doc = Nokogiri::XML(open(page))

  doc.search('nodes > node').each do |node|

    url = nil
    title = nil
    updated = nil
    rating = nil
    topics = nil

    node.search('Title').each do |t|
      title = t.inner_text
    end
    node.search('Updated-data').each do |t|
      updated = t.inner_text
    end
    node.search('Rating').each do |t|
      rating = t.inner_text
    end
    node.search('Topic').each do |t|
      if t.inner_text
        topics = t.inner_text.split(',')
      end
    end
    node.search('URL').each do |t|
      url = t.inner_text
    end

    if url
      $lessons[url] = {'title' => title,
                       'updated' => updated,
                       'rating' => rating,
                       'topics' => topics}
    else
      puts "No URL found for #{title}"
    end

  end
end


##################################################
# Main body of the script below, functions above #
##################################################

# Actually run the code here...
parse_data($courses)
parse_data($materials)

cp = ContentProvider.new(
    "GOBLET",
    "http://www.mygoblet.org",
    "http://www.mygoblet.org/sites/default/files/logo_goblet_trans.png",
    "GOBLET, the Global Organisation for Bioinformatics Learning, Education and Training, is a legally registered foundation providing a global, sustainable support and networking structure for bioinformatics educators/trainers and students/trainees."
    )
cp = Uploader.create_or_update_content_provider(cp)

# Create the new record
$lessons.each_key do |key|
  material = Material.new(title = $lessons[key]['title'],
                          url = key,
                          short_description = "#{$lessons[key]['title']} from #{$root_url}.",
                          doi = nil,
                          remote_updated_date = $lessons[key]['updated'],
                          remote_created_date = nil,
                          content_provider_id = cp['id'],
                          scientific_topic = $lessons[key]['topics'],
                          keywords = $lessons[key]['topics'])
  Uploader.create_or_update_material(material)
end

