require 'icalendar'
require 'google_places'
require 'tess_api_client'

ics = Net::HTTP.get('software-carpentry.org', '/workshops.ics')
events = Icalendar::Event.parse(ics)
#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
cp = ContentProvider.new({
                             title: "Software Carpentry",
                             url: "http://software-carpentry.org/",
                             image_url: "http://software-carpentry.org/img/software-carpentry-banner.png",
                             description: "The Software Carpentry Foundation is a non-profit organization whose members teach researchers basic software skills.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION]
                         })

cp = Uploader.create_or_update_content_provider(cp)

events.each do |event|
  begin
	  #@client = GooglePlaces::Client.new(ScraperConfig.google_api_key)
	  #google_place = @client.spots_by_query(event.location, :language => 'en')
	  #google_place = google_place.first || nil
	  if event.description.start_with?('http://cannot.find.url/')
	  	puts "skipping #{event.summary} - no URL"
	  else
	  	#HAX! A polish character was causing issues as it was being interpreted as ASCII. This forces everything into UTF-8 but loses the bad characters.
	  	summary = [event.summary].flatten.join(' ').force_encoding("ASCII-8BIT").encode('UTF-8', undef: :replace, replace: '')
	  	description = [event.description].flatten.join(' ').force_encoding("ASCII-8BIT").encode('UTF-8', undef: :replace, replace: '')
		  	event = Event.new({
			      content_provider_id: cp['id'],
			      title: "Software Carpentry - #{summary}",
			      url: description,
			      start_date: event.dtstart,
			      end_date: event.dtend,
			      description: "Find out more at #{description}",
			      organizer: 'Software Carpentry',
			      event_types: [Event::EVENT_TYPE[:workshops_and_courses]],
			      latitude: event.geo.first,
			      longitude: event.geo.last
			    })
			  Uploader.create_or_update_event(event)
		end
  end
  #,
  #    venue: event.location,
  #    city: google_place.city,
  #    country: google_place.country
end
