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
        json["items"].each do |json|
            event = Tess::API::Event.new
            unless (json["start"]["date"].nil? and json["start"]["datetime"].nil?)
                desc = Sanitize.clean(json['description'].sub /(^|\s)#(\w[\w-]*)(?=\s|$)/, '').gsub(/\s+/,' ')
                tags = /(^|\s)#(\w[\w-]*)(?=\s|$)/.match(desc)
                event.keywords = tags
                event.description = desc
                event.url = json['htmlLink']
                event.title = json['summary']
                event.contact = "#{[json['creator']['displayName'], json['creator']['email']].reject{|x| x.nil? or x.empty?}.join(' - ')}"
                event.organizer = "#{json['organizer']['displayName']}"
                event.content_provider = cp

                event.start = json["start"]["date"] unless json["start"]["date"].nil?
                event.start = json["start"]["datetime"] unless json["start"]["datetime"].nil?   
                event.end = json["end"]["date"] unless json["end"]["date"].nil?
                event.end = json["end"]["datetime"] unless json["end"]["datetime"].nil?

                add_event(event)
            end
        end
    end
end
