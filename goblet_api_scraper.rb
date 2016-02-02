#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api'


$courses = 'http://www.mygoblet.org/training-portal/courses-xml'
$materials = 'http://www.mygoblet.org/training-portal/materials-xml'
$owner_org = 'goblet'
$lessons = {}
$debug = false

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

cp = ContentProvider.new('Goblet',
 'http://mygoblet.org',
 'http://1.bp.blogspot.com/-j5qAvFKaJPc/VUO-vE4ZiII/AAAAAAAAEog/6ldLHrM0ges/s1600/GobletLogo.png', 
 'This is GOBLET!!!!')
cp = Uploader.create_or_update_content_provider(cp)

# Get the details of the content provider
cp_id = cp['id']#Uploader.get_content_provider_id($owner_org)

# Create the new record
$lessons.each_key do |key|
  material = Material.new(title = $lessons[key]['title'],
                          url = key,
                          short_description = "#{$lessons[key]['title']} from #{$root_url}, added automatically.",
                          doi = nil,
                          remote_updated_date = $lessons[key]['updated'],
                          remote_created_date = nil,
                          content_provider_id = cp_id,
                          scientific_topic = $lessons[key]['topics'],
                          keywords = $lessons[key]['topics'])

  check = Uploader.check_material(material)
  puts check.inspect

  if check.empty?
    puts 'No record by this name found. Creating it...'
    result = Uploader.create_material(material)
    puts result.inspect
  else
    puts 'A record by this name already exists. Updating!'
    material.id = check['id']
    result = Uploader.update_material(material)
    puts result.inspect
  end
end

