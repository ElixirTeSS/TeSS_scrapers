#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'

$root_url = 'https://www.statslife.org.uk/'

index_page = Nokogiri::HTML(open 'https://www.statslife.org.uk/events/events-calendar/eventsbycategory/12')
events = doc.search('li.ev_td_li') 
events.each do |event| 
    event_metadata = event.children.select{|x| x.name == 'p'}
    title = event_metadata[0].text
    link = event_metadata[0].first_element_child.attr('href')
    #event_page = Nokogiri::HTML(open($root_url + link))
    event_metadata[1] #contains the location and date. 
    begin
        upload_material = Material.new(
            title = material['schema:name'],
              url = url,
              short_description = material['schema:description'],
              doi = nil,
              remote_updated_date = Time.now,
              remote_created_date = material['dc:date'],
              content_provider_id = cp['id'],
              scientific_topic = material['schema:genre'],
              keywords = material['schema:keywords'],
              licence = nil,
              difficulty_level = nil,
              contributors = [],
              authors = material['sioc:has_creator'],
              target_audience = material['schema:audience']
          ) 
        Uploader.create_or_update_material(upload_material)
    rescue => ex
      puts ex.message
   end
end
