#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'

$root_url = 'https://www.bits.vib.be/training-list'
$owner_org = 'bioinformatics-training-and-services'
$lessons = {}
$debug = ScraperConfig.debug?

def parse_data()
  #upcoming_match = Regexp.new('upcoming-trainings')
  previous_match = Regexp.new('previous-trainings')
  #custom_match = Regexp.new('custom-trainings')

  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("html/bitsvib.html")
      doc = Nokogiri::HTML(f)
      f.close
    rescue
      puts "Failed to open bitsvib.html file."
      exit
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

cp = ContentProvider.new({
                             title: "VIB Bioinformatics Training and Services",
                             url: "https://www.bits.vib.be/",
                             image_url: "http://www.vib.be/VIBMediaLibrary/Logos/Service_facilities/BITS_website.jpg",
                             description: "Provider of Bioinformatics and software training, plus informatics services and resource management support.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION],
                             node: Node::NODE_NAMES[:BE]
                         })
cp = Uploader.create_or_update_content_provider(cp)


$lessons.each_key do |key|
  material = Material.new({title: $lessons[key],
                          url: $root_url + key,
                          short_description: "#{$lessons[key]} from #{$root_url + key}.",
                          doi: nil,
                          remote_updated_date: Time.now,
                          remote_created_date: nil,
                          content_provider_id: cp['id'],
                          keywords: []})
  puts "URL: #{$root_url}#{key}"
  Uploader.create_or_update_material(material)
end
