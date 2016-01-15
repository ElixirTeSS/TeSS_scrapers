#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api'
require 'httparty'

$root_url = 'https://www.bits.vib.be/training'
$owner_org = 'bioinformatics-training-and-services'
$lessons = {}
$debug = false

def parse_data()
  #upcoming_match = Regexp.new('upcoming-trainings')
  previous_match = Regexp.new('previous-trainings')
  #custom_match = Regexp.new('custom-trainings')

  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("bitsvib.html")
      doc = Nokogiri::HTML(f)
      f.close
    rescue
      puts "Failed to open bitsvib.html file."
    end
  else
    puts "Opening: #{$root_url}"
    doc = Nokogiri::HTML(open($root_url))
  end

  # <div class="moduletable-collapsible">
  # List of all materials
  first = doc.css('div.moduletable-collapsible')
  first.each do |f|
    links = f.search('a')
    links.each do |l|
      url = l['href']
      if previous_match.match(url)
        puts "Skipping old material: #{url}"
        next
      end
      title = l.text.strip
      $lessons[url] = title
    end
  end

end

parse_data

# Get the details of the content provider
cp_id = Uploader.get_content_provider_id($owner_org)

$lessons.each_key do |key|
  material = Material.new(title = $lessons[key],
                          url = $root_url + key,
                          short_description = "#{$lessons[key]} from #{$root_url + key}, added automatically.",
                          doi = 'N/A',
                          remote_updated_date = Time.now,
                          remote_created_date = nil,
                          content_provider_id = cp_id,
                          scientific_topic = [],
                          keywords = [])

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
