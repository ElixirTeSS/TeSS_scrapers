#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api'

$root_url = 'http://www.ebi.ac.uk'
$owner_org = 'european-bioinformatics-institute-ebi'
$lessons = {}
$debug = false


def parse_data(page)
  doc = Nokogiri::HTML(open($root_url + page))

  #first = doc.css('div.item-list').search('li')
  first = doc.css('li.views-row')
  first.each do |f|
    titles = f.css('div.views-field-title').css('span.field-content').search('a')
    desc = f.css('div.views-field-field-course-desc-value').css('div.field-content').search('p')
    topics = f.css('div.views-field-tid').css('span.field-content').search('a')

    #puts "TITLES: #{titles.css('a')[0]['href']}, #{titles.text}"
    #puts "DESC: #{desc.text}"
    puts "TOPICS: #{topics.collect{|t| t.text }}"

    href = titles.css('a')[0]['href']
    $lessons[href] = {}
    $lessons[href]['description'] = desc.text.strip
    $lessons[href]['text'] = titles.css('a')[0].text
    topic_text =  topics.collect{|t| t.text }
    if !topic_text.empty?
      $lessons[href]['topics'] = topic_text.map{|t| {'name' => t.gsub(/[^0-9a-z ]/i, ' ')} } # Replaces extract_keywords
    end                                                                             # Non-alphanumeric purged

  end

end


def last_page_number
  # This method needs to be updated to find the actual final page.
  return 2
end


# Scrape all the pages.
first_page = '/training/online/course-list'
parse_data(first_page)
1.upto(last_page_number) do |num|
    page = first_page + '?page=' + num.to_s
    puts "Scraping page: #{num.to_s}"
    parse_data(page)
end

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
