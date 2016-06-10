#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'

$root_url = 'http://edu.isb-sib.ch/'
$owner_org = 'swiss-institute-of-bioinformatics'
$lessons = {}
$debug = ScraperConfig.debug?


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

cp = ContentProvider.new(
    "Swiss Institute of Bioinformatics",
    "http://edu.isb-sib.ch/",
    "http://bcf.isb-sib.ch/img/sib.png",
    "The SIB Swiss Institute of Bioinformatics is an academic, non-profit foundation recognised of public utility and established in 1998. SIB coordinates research and education in bioinformatics throughout Switzerland and provides high quality bioinformatics services to the national and international research community."
    )
cp = Uploader.create_or_update_content_provider(cp)
# Create the new record
$lessons.each_key do |key|
  material = Material.new({title: $lessons[key]['name'],
                          url: key,
                          short_description: $lessons[key]['description'],
                          doi: nil,
                          remote_updated_date: $lessons[key]['updated'],
                          remote_created_date: nil,
                          content_provider_id: cp['id'],
                          scientific_topic: [],
                          keywords: []})

  Uploader.create_or_update_material(material)
end

