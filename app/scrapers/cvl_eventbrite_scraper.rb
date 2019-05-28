class CvlEventbriteScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'CVL Eventbrite scraper',
        events_endpoint: 'https://www.eventbriteapi.com/v3/events/',
        organizers_endpoint: 'https://www.eventbriteapi.com/v3/organizers/',
        organizers_events_endpoint: 'https://www.eventbriteapi.com/v3/organizers/%ID%/events/',
        venue_endpoint: 'https://www.eventbriteapi.com/v3/venues/',        
        token: 'ZP2R5TIY5WEG6VKRATVR',
        organizer: '20185254580',
        events: ["62037032434", "61767611589", "62037121701", "62036833840", "61482164810"]

    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Characterisation Virtual Laboratory", #name
          url: "https://characterisation-virtual-laboratory.github.io/CVL_Community/", #url
          image_url: " https://characterisation-virtual-laboratory.github.io/CVL_Community/assets/images/logo.png", #logo
          description: "The Characterisation Virtual Laboratory (CVL) community is a group of researchers, university lecturers, and health professionals who engage in developing and maintaining materials for training and practice and encourage best data practices, including the use of the CVL infrastructure.", #description
          content_provider_type: :organisation
        }))  	

    config[:events].each do |event|
    	event_url = config[:events_endpoint] + event + "/?token=" + config[:token]
    	event_data = JSON.parse(open_url(event_url).read)

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

      if event_data['organizer_id']
        organizer_url = config[:organizers_endpoint] + event_data['organizer_id'] + "/?token=" + config[:token]
        organizer_data = JSON.parse(open_url(organizer_url).read)
      end

    	if event_data['venue_id']
        venue_url = config[:venue_endpoint] + event_data['venue_id'] + "/?token=" + config[:token]
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

  end

end

=begin

{"name"=>
     {"text"=>"10 FAIR things for Imaging - Working document",
      "html"=>"10 FAIR things for Imaging - Working document"
     },
 "description"=>
     {"text"=>"This is a collaborative hackathon.",
      "html"=>"This is a collaborative hackathon."
     },
 "id"=>"62037032434",
 "url"=>"https://www.eventbrite.com.au/e/10-fair-things-for-imaging-working-document-tickets-62037032434",
 "start"=>
     {"timezone"=>"Australia/Brisbane",
      "local"=>"2019-05-30T09:00:00",
      "utc"=>"2019-05-29T23:00:00Z"
     },
 "end"=>
     {"timezone"=>"Australia/Brisbane",
      "local"=>"2019-05-31T17:00:00",
      "utc"=>"2019-05-31T07:00:00Z"},
 "organization_id"=>"306206996129",
 "created"=>"2019-05-17T08:11:37Z",
 "changed"=>"2019-05-17T08:15:55Z",
 "published"=>"2019-05-17T08:14:52Z",
 "capacity"=>nil,
 "capacity_is_custom"=>nil,
 "status"=>"live",
 "currency"=>"AUD",
 "listed"=>true,
 "shareable"=>false, "online_event"=>true, "tx_time_limit"=>480,
 "hide_start_date"=>false, "hide_end_date"=>false, "locale"=>"en_AU",
 "is_locked"=>false, "privacy_setting"=>"unlocked", "is_series"=>false,
 "is_series_parent"=>false, "inventory_type"=>"limited", "is_reserved_seating"=>false,
 "show_pick_a_seat"=>false, "show_seatmap_thumbnail"=>false, "show_colors_in_seatmap_thumbnail"=>false,
 "source"=>"coyote", "is_free"=>true, "version"=>"3.7.0",
 "summary"=>"This is a collaborative hackathon.", "logo_id"=>"62450401",
 "organizer_id"=>"20185254580", "venue_id"=>nil, "category_id"=>"102", "subcategory_id"=>nil,
 "format_id"=>"2", "resource_uri"=>"https://www.eventbriteapi.com/v3/events/62037032434/",
 "is_externally_ticketed"=>false,
 "logo"=>
     {"crop_mask"=>
          {"top_left"=>{"x"=>55, "y"=>0},
           "width"=>636, "height"=>318},
      "original"=>
          {"url"=>"https://img.evbuc.com/https%3A%2F%2Fcdn.evbuc.com%2Fimages%2F62450401%2F306206996129%2F1%2Foriginal.20190517-081245?auto=compress&s=0c94a3e52218749f9f2abb8c42a3a684",
           "width"=>750,
           "height"=>320},
      "id"=>"62450401",
      "url"=>"https://img.evbuc.com/https%3A%2F%2Fcdn.evbuc.com%2Fimages%2F62450401%2F306206996129%2F1%2Foriginal.20190517-081245?h=200&w=450&auto=compress&rect=55%2C0%2C636%2C318&s=c197934ff7cafb2a880d43777b0d7860",
      "aspect_ratio"=>"2",
      "edge_color"=>nil,
      "edge_color_set"=>true}
}

=end