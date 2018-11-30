class OpenTargetJsonScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Open Targets Scraper',
        json_feed: 'https://raw.githubusercontent.com/opentargets/live-files/gh-pages/outreach.json'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Open Targets Platform",
          url: "https://www.targetvalidation.org/",
          image_url: "https://www.sanger.ac.uk/sites/default/files/Jul2017/open_targets.png",
          description: "",
          content_provider_type: :organization
        }))


        json = JSON.parse(open(config[:json_feed]).read)

        json = JSON.parse(open('https://raw.githubusercontent.com/opentargets/live-files/gh-pages/outreach.json').read)
        json['sessions'].each do |session|
          startDateString = session['date']
          startDate = Date.parse(session['date'])
          if session['duration']
            endDate = modify_date(startDateString, session['duration'])
          else
            endDate = startDate
          end

          if endDate >= Date.today and session['external'] and
           session['external']['link'] and !session['external']['link'].empty?
            if session['type']
              types = [session['type'].gsub(' ', '_').downcase]
            else
              types = []
            end
            event = Tess::API::Event.new({
              title: session['external']['text'],
              description: session['description'],
              url: session['external']['link'],
              start: startDateString,
              end: "#{modify_date(startDateString, session['duration']) if session['duration']}",
              venue: session['place'].split(',').first,
              country: session['place'].split(',').last,
              keywords: ['Open Targets'],
              event_types: types,
              content_provider: cp
            })
            add_event(event)
          end
        end
  end

  private

    def modify_date(date, duration)
      if date.is_a?(String)
        date = Date.parse(date)
      end
      matches = duration.match(/P([^T]+)T?(.*)/)
      date_period = matches[1]

      date_period.scan(/(\d+)([YMWD])/).each do |match|
        value = match[0].to_i
        case match[1]
          when 'Y'
            date = date >> (12 * value)
          when 'M'
            date = date >> value
          when 'W'
            date = date + (7 * value)
          when 'D'
            date = date + value
        end
      end
        time_period = matches[2]
        
        time_period.scan(/(\d+)([HMS])/).each do |match|
          case match[1]
            when 'H'
            when 'M'
            when 'S'
          end
        end      
      date
    end
end
