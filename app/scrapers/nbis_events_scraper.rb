class NbisEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        content_url: "https://www.googleapis.com/calendar/v3/calendars/bils.elixir%40gmail.com/events?key=AIzaSyA7tQAGCL4d8mNBSUZRBhedexrswhzgY6s&orderBy=startTime&singleEvents=true&timeMin=#{Time.now.strftime('%Y-%m-%dT%H:%M:%S')}.124Z"
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "NBIS",
          url: "http://nbis.se",
          image_url: "http://nbis.se/assets/img/logos/nbislogo-orange-txt.svg",
          description: "NBIS is a distributed national bioinformatics infrastructure, supporting life sciences in Sweden",
          content_provider_type: :institution,
          node_name: [:SE]
        })
    )

    #file = JSON.parse(open config[:content_url])
    puts config[:content_url]
    json = JSON.parse(open(config[:content_url],{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)
    json['items'].each do |item|
      event = Tess::API::Event.new
      unless item['description'].nil? || (item["start"]["date"].nil? && item["start"]["dateTime"].nil?)
        desc = Sanitize.clean(item['description'].sub /(^|\s)#(\w[\w-]*)(?=\s|$)/, '').gsub(/\s+/,' ')
        tags = /(^|\s)#(\w[\w-]*)(?=\s|$)/.match(desc)
        # get city and country, exclude postal number
        location = /(.*, [0-9 ]* )?([\p{L} ]+), (.*)/
        unless item['location'].nil? || item["location"] !~ location
          event.city = item['location'].match(location)[2]
          if ["Sweden", "Sverige"].include? item['location'].match(location)[3]
              # ignore other country names (need to be translated from Swedish)
              event.country = "Sweden"
          end
        end
        event.keywords = tags.to_a
        event.description = desc
        if(u = desc.match(/\s#url:\s*(\S*)/))
          event.url = u[1]
        else
          event.url = item['htmlLink']
        end
        event.title = item['summary']
        event.contact = "#{[item['creator']['displayName'], item['creator']['email']].reject{|x| x.nil? || x.empty?}.join(' - ')}"
        event.organizer = "#{item['organizer']['displayName']}"
        event.content_provider = cp

        event.start = item['start']['date'] unless item['start']['date'].nil?
        event.start = item['start']['dateTime'] unless item['start']['dateTime'].nil?
        event.end = item['end']['date'] unless item['end']['date'].nil?
        event.end = item['end']['dateTime'] unless item['end']['dateTime'].nil?

        add_event(event)
      end
    end
  end
end
