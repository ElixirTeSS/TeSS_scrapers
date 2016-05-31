#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'

# This scraper should use the XML API to get the URL of each course, then go to each individual
# course page to scrape the details. This will be improved when proper markup is added to
# each page, expected soon.


$courses = 'http://www.mygoblet.org/training-portal/courses-xml'
$materials = 'http://www.mygoblet.org/training-portal/materials-xml'
$owner_org = 'goblet'
$lessons = {}
$debug = ScraperConfig.debug?

# Get all URLs from XML
def get_urls(page,type)
  if $debug
    urls = IO.readlines("html/goblet_#{type}.txt").collect {|x| x.chomp!}
  else
    doc = Nokogiri::XML(open(page))
    urls = []

    doc.search('nodes > node').each do |node|
      url = nil
      node.search('URL').each do |t|
        url = t.inner_text
      end
      if url
        urls << url
      end
    end
  end

  return urls
end

# Scrape pages for course info.
def parse_url(u,type)
  u
end

# The material below is just a stub of the html parsing which will take place
# once the proper labels have been applied to the html

# courses
get_urls($courses,'courses').each do |url|
  # Get the page
  if $debug
    f = File.open("html/#{url.split(/\//)[-1]}")
    doc = Nokogiri::HTML(f)
    f.close
  else
    doc = Nokogiri::HTML(open(url))
  end

  # Parse the HTML
  doc.search('h1').each do |title|
    puts "TITLE: #{title.text}"
  end

end

# materials
get_urls($materials,'materials').each do |url|
  # Get the page
  if $debug
    f = File.open("html/#{url.split(/\//)[-1]}")
    doc = Nokogiri::HTML(f)
    f.close
  else
    doc = Nokogiri::HTML(open(url))
  end

  # Parse the HTML
  doc.search('h1').each do |title|
    puts "TITLE: #{title.text}"
  end

end
