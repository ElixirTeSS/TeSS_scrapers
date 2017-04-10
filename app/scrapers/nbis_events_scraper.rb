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
            event = parse_description(event, json["description"])
            puts event.inspect unless event.nil?
            unless (event.nil? or (json["start"]["date"].nil? and json["start"]["datetime"].nil?))
                event.title = json['summary']
                event.contact = "#{[json['creator']['displayName'], json['creator']['email']].reject{|x| x.nil? or x.empty?}.join(' - ')}"
                event.organizer = "#{json['organizer']['displayName']}"
                event.content_provider = cp
                #or !((/(^|\s)#(\w[\w-]*)(?=\s|$)/).match(event.description).nil?
                
                event.start = json["start"]["date"] unless json["start"]["date"].nil?
                event.start = json["start"]["datetime"] unless json["start"]["datetime"].nil?   
                event.end = json["end"]["date"] unless json["end"]["date"].nil?
                event.end = json["end"]["datetime"] unless json["end"]["datetime"].nil?
                add_event(event)
            end
        end
    end
    private

    def parse_description(event, desc)
        url = desc.match /#url: (https?:\/\/\S+?)(\.?([\s\n]|$))/
        desc = desc.sub /#url: (https?:\/\/\S+?)(\.?([\s\n]|$))/, '' 
        tags = /(^|\s)#(\w[\w-]*)(?=\s|$)/.match(event.description)
        desc = desc.sub /(^|\s)#(\w[\w-]*)(?=\s|$)/, ''
        if url 
            event.description = desc 
            event.url = url[1]
            event.keywords = tags
            return event
        else
            return nil
        end    
    end
end
