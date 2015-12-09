#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api'

$root_url = 'http://genome3d.eu/'
$owner_org = 'genome-3d'
$lessons = {}
$debug = false


def parse_data(page)
  # As usual, use a local page for testing to avoid hammering the remote server.
  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("genome3d.html")
      doc = Nokogiri::HTML(f)
      f.close
    rescue
      puts 'Failed to open genome3d.html file.'
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

  links = doc.css('#wiki-content-container').search('ul').search('li')
  links.each do |link|
     if !(a = link.search('a')).empty?
        href = a[0]['href'].chomp
        name = a.text
        puts "Name = #{a.text}" if $debug
        puts "URL = #{a[0]['href'].chomp}" if $debug
        description = nil
        if !(li = link.search('li')).empty?
             description = li.text
             puts "Description = #{li.text}" if $debug
        end
        $lessons[href] = {}
        $lessons[href]['name'] = name
        $lessons[href]['description'] = description
     end
  end
end

# parse the data
parse_data('tutorials/page/Public/Page/Tutorial/Index')

# Get the details of the content provider
cp_id = Uploader.get_content_provider_id($owner_org)

# Create the new record
$lessons.each_key do |key|
  material = Material.new(title = $lessons[key]['name'],
                          url = $root_url + key,
                          short_description = "#{$lessons[key]['name']} from #{$root_url + key}, added automatically.",
                          doi = 'N/A',
                          remote_updated_date = Time.now,
                          remote_created_date = $lessons[key]['last_modified'],
                          content_provider_id = cp_id)

  check = Uploader.check_material(material)
  puts check.inspect

  if check.empty?
    puts 'No record by this name found. Creating it...'
    result = Uploader.create_material(material)
    puts result.inspect
  else
    puts 'A record by this name already exists.'
  end
end


