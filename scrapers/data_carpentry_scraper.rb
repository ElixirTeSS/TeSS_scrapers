#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'

$root_url = 'http://www.datacarpentry.org'
$lessons = {}
$debug = ScraperConfig.debug?
$exclude = [' Feeling Responsive']

def parse_data(page)
  doc = Nokogiri::HTML(open($root_url + page))
  doc = Nokogiri::HTML(open('http://www.datacarpentry.org/lessons'))
  #first = doc.css('div.item-list').search('li')
  lesson_urls = doc.css('td > a').collect { |x| x.values }.flatten.select { |x| x.include?('github.io') }

  lesson_urls.each do |lesson_url|
    lesson = Nokogiri::HTML(open(lesson_url))
    title = lesson.css('h1').text
    unless $exclude.include?(title)
      if title.empty?
        title = lesson.css('p').first.text.gsub('<p>#', '').gsub('</p>', '').gsub('#', '')
        $description = lesson.css('p')[2]
      else
        $description = lesson.css('p')[0].text
        if $description == '======='
          $description = lesson.css('p')[1].text
        end
      end
      descriptions = []
      index = 0
      while !$description.include?('Content Contributors') and index < 5 do
        $descripton = lesson.css('p')[index=index+1]
        descriptions << lesson.css('p')[index]
      end
      $lessons[lesson_url] = {}
      $lessons[lesson_url]['short_description'] = descriptions.join(' ')
      $lessons[lesson_url]['long_description'] = lesson.css('p h1 a')
      $lessons[lesson_url]['title'] = title
    end
  end
end

parse_data('/lessons')

cp = ContentProvider.new({
                             title: "Data Carpentry",
                             url: "http://www.datacarpentry.org",
                             image_url: "http://www.datacarpentry.org/assets/img/DC_logo_vision.png",
                             description: "Data Carpentry's aim is to teach researchers basic concepts, skills, and tools for working with data so that they can get more done in less time, and with less pain.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION]
                         })

cp = Uploader.create_or_update_content_provider(cp)

# Create the new record
$lessons.each_key do |key|

  material = Material.new({title: $lessons[key]['title'],
                           url: key,
                           short_description: $lessons[key]['short_description'],
                           doi: nil,
                           remote_updated_date: Time.now,
                           remote_created_date: nil,
                           content_provider_id: cp['id'],
                           scientific_topic: nil,
                           keywords: nil,
                           licence: nil,
                           difficulty_level: nil,
                           contributors: [],
                           authors: [],
                           target_audience: [],
                           id: nil,
                           long_description: $lessons[key]['long_description']})

  Uploader.create_or_update_material(material)

end
