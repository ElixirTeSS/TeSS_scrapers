#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api'


$root_url = 'https://www.csc.fi/web/training/'
$owner_org = 'csc'
$events = {}
$debug = true

def parse_data()

    if $debug
      puts 'Opening local file.'
      begin
        f = File.open("html/csc_events.html")
        doc = Nokogiri::HTML(f)
        f.close
      rescue
        puts "Failed to open csc_events.html file."
      end
    else
      puts "Opening: #{$root_url}"
      doc = Nokogiri::HTML(open($root_url))
    end

    doc.css('div.csc-article').each do |article|
      categories = article.search('.koulutus-category').collect {|x| x.text.strip}.reject(&:empty?)
      header = article.search('h3 > a')[0]
      link = header['href']
      title = header.text
      description = article.search('.article-summary')[0].text

      $events[link] = {'title' => title,
                       'description' => description,
                       'categories' => categories,
                       'keywords' => categories}
    end



end


##################################################
# Main body of the script below, functions above #
##################################################

# Actually run the code here...
parse_data

# Get the details of the content provider
cp_id = Uploader.get_content_provider_id($owner_org)


$events.each_key do |key|
  lat,lon = nil # Can't seem to get these out of the Google maps URL
  start_date, end_date, venue = nil

  if $debug
    next unless $events[key]['title'] == 'Python in High-Performance Computing'
    puts 'Opening local file.'
    begin
      f = File.open("html/csc_event_detail.html")
      newpage = Nokogiri::HTML(f)
      f.close
    rescue
      puts "Failed to open csc_events.html file."
    end
  else
    newpage = Nokogiri::HTML(open(key))
  end

  newpage.search('table > tr').each do |row|
    fieldname = row.css('td')[0].text.strip
    if fieldname == 'Date:'
      datefield = row.css('td')[1].text.strip
      start_date,end_date = datefield.split(/ - /)
    elsif fieldname == 'Location details:'
      venue = row.css('td')[1].text.strip
    end
  end

  event = Event.new(nil,cp_id,nil,$events[key]['title'],nil,key,'CSC',nil,$events[key]['description'],$events[key]['category'],
                    $events[key]['category'],start_date,end_date,nil,venue,nil,nil,nil,nil,lat,lon)


  check = Uploader.check_event(event)
  puts check.inspect

  if check.empty?
    puts 'No record by this name found. Creating it...'
    result = Uploader.create_event(event)
    puts result.inspect
  else
    puts 'A record by this name already exists. Updating!'
    event.id = check['id']
    result = Uploader.update_event(event)
    puts result.inspect
  end


end


