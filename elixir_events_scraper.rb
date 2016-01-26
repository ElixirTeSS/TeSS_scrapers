#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api'
require 'geocoder'


$root_url = 'http://www.elixir-europe.org'
$owner_org = 'elixir'
$events = {}
$debug = false

def parse_data(page)

    if $debug
        puts 'Opening local file.'
        begin
          f = File.open("html/elixir_events.html")
          doc = Nokogiri::HTML(f)
          f.close
        rescue
          puts "Failed to open elixir_events.html file."
        end
    else
        puts "Opening: #{$root_url + page}"
        doc = Nokogiri::HTML(open($root_url + page))
    end

    doc.search('tbody > tr').each do |row|
        oldlink = nil
        row.css("div.custom-right").map do |node|
          name = node.at_css("h3 a").text.strip
          link = node.at_css("h3 a")['href']
          $events[link] = {'title' => name}
          oldlink =  link
        end
        row.css("div.date-display-range").search('span').each do |span|
            if span['class'] == 'date-display-start'
              $events[oldlink]['start_date'] = span.text.strip
            elsif span['class'] == 'date-display-end'
              $events[oldlink]['end_date'] = span.text.strip
            end
        end
        row.css("div.date-location").search('.icon').each do |icon|
          if icon['data-icon'] == 'i'
           $events[oldlink]['category'] = icon.text.strip
          elsif icon['data-icon'] == 'r'
            # Nothing to do here...
          elsif icon['data-icon'] == '['
            $events[oldlink]['location'] = icon.text.strip
          end
        end
    end
end



##################################################
# Main body of the script below, functions above #
##################################################

# Actually run the code here...
if $debug
  parse_data('a random string')
else
  0.upto(1) do |p|
    parse_data('/events/upcoming?page=' + p.to_s)
  end
end

# Get the details of the content provider
cp_id = Uploader.get_content_provider_id($owner_org)

# Create the new record
coord_match = Regexp.new('\"coordinates\":\[([\-\.\d]+),([\-\.\d]+)\]')

$events.each_key do |key|
  #loc = Geocoder.search($events[key]['location'])
  #puts "LOC: #{$events[key]['location']}, #{loc.inspect}"

  # Open another page mainly to look for the coordinates of the venue,
  # and hack one's way through it:

  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("html/elixir_single_event.html")
      newpage = Nokogiri::HTML(f)
      f.close
    rescue
      puts "Failed to open elixir_events.html file."
    end
  else
    newpage = Nokogiri::HTML(open($root_url + key))
  end
  lat,lon = nil
  newpage.css('script').each do |script|
    begin
      lat,lon = coord_match.match(script).captures
      if lat and lon
        break
      end
      print "LAT: #{lat}, LON: #{lon}"
    rescue
    end
  end

  event = Event.new(nil,nil,$events[key]['title'],nil,$root_url + key,cp_id,nil,nil,nil,$events[key]['category'],
                    $events[key]['start_date'], $events[key]['end_date'],nil,$events[key]['location'],nil,nil,nil,nil,lat,lon)

  puts "E: #{event.inspect}"


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


