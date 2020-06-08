class CvlEventbriteScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'CVL Eventbrite scraper',
        search_endpoint: 'https://www.eventbriteapi.com/v3/events/search/',
        # Note the following endpoint is not documented anywhere, I found it here:
        # https://groups.google.com/forum/#!searchin/eventbrite-api/organization|sort:date/eventbrite-api/uubABbdYLOg/ySFGRNN_AgAJ
        # Also note that an `organizer` is not an `organization`
        organizers_events_endpoint: 'https://www.eventbriteapi.com/v3/organizers/%{organizer_id}/events/',
        venue_endpoint: 'https://www.eventbriteapi.com/v3/venues/',
        organizer: '20185254580',
    }
  end

  def scrape

    if !Tess::API.config['eventbrite_key'].nil?
      token = Tess::API.config['eventbrite_key']
      cp = add_content_provider(Tess::API::ContentProvider.new(
          { title: "Characterisation Virtual Laboratory", #name
            url: "https://characterisation-virtual-laboratory.github.io/CVL_Community/", #url
            image_url: "eat https://characterisation-virtual-laboratory.github.io/CVL_Community/assets/images/logo.png", #logo
            description: "The Characterisation Virtual Laboratory (CVL) community is a group of researchers, university lecturers, and health professionals who engage in developing and maintaining materials for training and practice and encourage best data practices, including the use of the CVL infrastructure.", #description
            content_provider_type: :organisation
          }))

      # Get the events by the organizer
      organizer_events_url = (config[:organizers_events_endpoint] % { organizer_id: config[:organizer] }) + "?token=" + token
      event_data = JSON.parse(open_url(organizer_events_url).read)

      #Loop through each event, creating a new event and looking up the venue
      event_data['events'].each do |event_data|
        new_event = Tess::API::Event.new(
            content_provider: cp,
            title: event_data['name']['text'],
            url: event_data['url'],
            start: event_data['start']['local'],
            end: event_data['end']['local'],
            description: event_data['description']['text'],
            organizer: 'CVL',
            event_types: [:workshops_and_courses]
        )

        if event_data['venue_id']
          venue_url = config[:venue_endpoint] + event_data['venue_id'] + "/?token=" + token
          venue_data = JSON.parse(open_url(venue_url).read)

          new_event.latitude = venue_data['address']['latitude']
          new_event.longitude = venue_data['address']['longitude']
          new_event.venue = /(.*)\sGPS/.match(venue_data['address']['address_1']).to_a.last
          new_event.postcode = venue_data['address']['postal_code']
          new_event.city = venue_data['address']['city']
          new_event.country = venue_data['address']['country']
        end

        add_event(new_event)
      end
    else
      puts 'Please enter an eventbrite_key into the uploader_config.txt'
    end
  end
end
