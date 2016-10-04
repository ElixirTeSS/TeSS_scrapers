#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'
require 'geocoder'
require 'google_places'


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
    parse_data('//events/workshops/upcoming?page=' + p.to_s)
  end
end

cp = ContentProvider.new({
                             title: "ELIXIR", #name
                             url: "https://www.elixir-europe.org/", #url
                             image_url: "https://media.eurekalert.org/multimedia_prod/pub/web/38675_web.jpg",
                             description: "Building a sustainable European infrastructure for biological information, supporting life science research and its translation to medicine, agriculture, bioindustries and society.
ELIXIR unites Europe’s leading life science organisations in managing and safeguarding the massive amounts of data being generated every day by publicly funded research. It is a pan-European research infrastructure for biological information.
ELIXIR provides the facilities necessary for life science researchers - from bench biologists to cheminformaticians - to make the most of our rapidly growing store of information about living systems, which is the foundation on which our understanding of life is built.", #description
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION]
                         })

cp = Uploader.create_or_update_content_provider(cp)

# Create the new record
coord_match = Regexp.new('\"coordinates\":\[([\-\.\d]+),([\-\.\d]+)\]')

$events.each_key do |key|
  @client = GooglePlaces::Client.new(ScraperConfig.google_api_key)
  if $events[key]['location']
    location = $events[key]['location'].split(',').first
    if location and !location.empty?
      google_place = @client.spots_by_query(location, :language => 'en')
      google_place = google_place.first || nil
    end
  end
  event = Event.new({
      content_provider_id: cp['id'],
      title: $events[key]['title'],
      url: $root_url + key,
      category: $events[key]['category'],
      start_date: $events[key]['start_date'],
      end_date: $events[key]['end_date'],
      event_types: [Event::EVENT_TYPE[:workshops_and_courses]]
  })
  if google_place 
      event.venue = google_place.name
      event.latitude = google_place.lat
      event.longitude = google_place.lng
      event.city = google_place.city
      event.country = google_place.country
      event.postcode = google_place.postal_code
    else
      event.venue = $events[key]['location']
  end

  Uploader.create_or_update_event(event)
end


