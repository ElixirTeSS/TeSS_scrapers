#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'


def parse_date(date_string)
  puts date_string
   if (match_data = /([0-9]+)\-([0-9]+)\s([a-zA-Z]+)/.match(date_string))
     start_date = Date.parse(match_data[1].to_s + '-' + match_data[3].to_s + '-' + Time.now.year.to_s)
     end_date = Date.parse(match_data[2].to_s + '-' + match_data[3].to_s + '-' + Time.now.year.to_s)
   elsif (match_data = /^([0-9]+)\s([a-zA-Z]+)$/.match(date_string))
     start_date = Date.parse(match_data[1].to_s + '-' + match_data[2].to_s + '-' + Time.now.year.to_s)
     end_date = Date.parse(match_data[1].to_s + '-' + match_data[2].to_s + '-' + Time.now.year.to_s)
    else
      start_date = nil
      end_date = nil
   end    
   return [start_date, end_date]
end

$root_url = 'https://www.denbi.de'
index_page = 'https://www.denbi.de/index.php/training-courses'
$owner_org = 'denbi'
$lessons = {}
$debug = ScraperConfig.debug?

cp = ContentProvider.new({
                             title: "de.NBI", #name
                             url: "https://www.denbi.de", #url
                             image_url: "http://www.openms.de/wp-content/uploads/2016/06/deNBI_Logo_rgb.jpg", #logo
                             description: "The 'German Network for Bioinformatics Infrastructure – de.NBI' is a national infrastructure supported by the Federal Ministry of Education and Research providing comprehensive, high-quality bioinformatics services to users in life sciences research and biomedicine. The partners organize training events, courses and summer schools on tools, standards and compute services provided by de.NBI to assist researchers to more effectively exploit their data.", #description
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION],
                             node: Node::NODE_NAMES[:'DE']
                         })

cp = Uploader.create_or_update_content_provider(cp)

# Scrape all the pages.

doc = Nokogiri::HTML(open(index_page))

table = doc.xpath('//*[@id="content"]/div[2]/div[2]/div[3]/table[1]/tbody/tr')
table.each do |row|
  column = row.children.select{|x| x.name == 'td'}
  url = column[1].children.first['href']
  if url
       date = parse_date(column[0].text)
       name = column[1].text
       city = column[2].text
       event = Event.new({title: name,
                          url: $root_url + url,
                          short_description: nil,
                          content_provider_id: cp['id'],
                          start_date: date[0],
                          end_date: date[1]
                          })

       Uploader.create_or_update_event(event)
  end
end
