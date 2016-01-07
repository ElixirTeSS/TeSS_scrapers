#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api'

$root_url = 'http://edu.isb-sib.ch/'
$owner_org = 'swiss-institute-of-bioinformatics'
$lessons = {}
$debug = false


def parse_data(page)
  # As usual, use a local page for testing to avoid hammering the remote server.
  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("sib.html")
      doc = Nokogiri::HTML(f)
      f.close
    rescue
      puts 'Failed to open sib.html file.'
    end
  else
    puts "Opening: #{$root_url + page}"
    doc = Nokogiri::HTML(open($root_url + page))
  end

  # Now to obtain the exciting course information!
  #links = doc.css('#wiki-content-container').search('li')
  #links.each do |li|
  #  puts "LI: #{li}"
  #end

  links = doc.css("div.coursebox").map do |coursebox|
    course = coursebox.at_css("a")
    if course
        url = course['href']
        name = course.text.strip
        description = coursebox.at_css("p").text.strip
        puts "url: #{url || 'missing'}\nname: #{name || 'missing'}\ndescription: #{description || 'missing'}" if $debug
        $lessons[url] = {}
        $lessons[url]['name'] = name
        $lessons[url]['description'] = description
    end
  end
end

# parse the data
parse_data('course/index.php?categoryid=2')


# Get the details of the content provider
cp_id = Uploader.get_content_provider_id($owner_org)

# Create the new record
$lessons.each_key do |key|
  material = Material.new(title = $lessons[key]['name'],
                          url = key,
                          short_description = $lessons[key]['description'],
                          doi = 'N/A',
                          remote_updated_date = $lessons[key]['updated'],
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

