

class HungaryEventbriteScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'ELIXIR-Hungary Eventbrite meeting',
        events_endpoint: 'https://www.eventbriteapi.com/v3/events/',
        organizers_endpoint: 'https://www.eventbriteapi.com/v3/organizers/',
        venue_endpoint: 'https://www.eventbriteapi.com/v3/venues/',        
        token: 'ZP2R5TIY5WEG6VKRATVR',
        events: ["51195018679", "51516339759"]
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "ELIXIR Hungary", #name
          url: "http://elixir-hungary.org/", #url
          image_url: "http://elixir-hungary.org/sites/default/files/elixir-hungary.png", #logo
          description: "", #description
          content_provider_type: :organisation,
          node_name: :Hungary
        }))  	

    config[:events].each do |event|
    	event_url = config[:events_endpoint] + event + "/?token=" + config[:token]
    	event_data = JSON.parse(open_url(event_url).read)

    	#organizer_url = config[:organizers_endpoint] + event_data['organizer_id'] + "/?token=" + config[:token]
    	#organizer_data = JSON.parse(open_url(organizer_url).read)

    	venue_url = config[:venue_endpoint] + event_data['venue_id'] + "/?token=" + config[:token]
    	venue_data = JSON.parse(open_url(venue_url).read)

    	add_event(Tess::API::Event.new(
                  content_provider: cp,
                  title: event_data['name']['text'],
                  url: event_data['url'],
                  start: event_data['start']['utc'],
                  end: event_data['end']['utc'],
                  description: event_data['description']['text'],
                  organizer: 'ELIXIR Hungary',
                  event_types: [:workshops_and_courses],
                  latitude: venue_data['address']['latitude'],
                  longitude: venue_data['address']['longitude'],
                  venue: /(.*)\sGPS/.match(venue_data['address']['address_1']).to_a.last,
                  postcode: venue_data['address']['postal_code'],
                  city: venue_data['address']['city'],
                  country: venue_data['address']['country']
                 ))
       
    end

  end

end

