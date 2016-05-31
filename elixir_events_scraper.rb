#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'
require 'geocoder'


$root_url = 'https://www.elixir-europe.org'
$owner_org = 'elixir'
$events = {}
$debug = ScraperConfig.debug?

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


cp = ContentProvider.new(
    "ELIXIR",
    "https://www.elixir-europe.org/",
    "http://media.eurekalert.org/multimedia_prod/pub/web/38675_web.jpg",
    "Building a sustainable European infrastructure for biological information, supporting life science research and its translation to medicine, agriculture, bioindustries and society.
ELIXIR unites Europe’s leading life science organisations in managing and safeguarding the massive amounts of data being generated every day by publicly funded research. It is a pan-European research infrastructure for biological information.
ELIXIR provides the facilities necessary for life science researchers - from bench biologists to cheminformaticians - to make the most of our rapidly growing store of information about living systems, which is the foundation on which our understanding of life is built."
    )
cp = Uploader.create_or_update_content_provider(cp)


# Create the new record
coord_match = Regexp.new('\"coordinates\":\[([\-\.\d]+),([\-\.\d]+)\]')

$events.each_key do |key|
  loc = Geocoder.search($events[key]['location'])
  puts "LOC: #{$events[key]['location']}, #{loc.inspect}"

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

  # Attempts to clean up the venue string
  venue = nil
  if $events[key]['location']
    venue = $events[key]['location'].gsub(/-/,'').gsub(/,,/,',')
    if venue =~ /Wellcome Trust Conference Centre/
      venue = 'Wellcome Trust Conference Centre, Wellcome Genome Campus, Hinxton, CB10 1SD, United Kingdom.'
    end
  end

  event = Event.new(nil,cp['id'],nil,$events[key]['title'],nil,$root_url + key,'Elixir',nil,nil,nil,$events[key]['category'],
                    $events[key]['start_date'], $events[key]['end_date'],nil,venue,nil,nil,nil,nil,lat,lon)

  #puts "E: #{event.inspect}"

  Uploader.create_or_update_event(event)

end


