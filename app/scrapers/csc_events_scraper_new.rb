class CscEventsScraperNew < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'CSC Events Scraper (New)',
        root_url: 'https://www.csc.fi/en/training/',
        json_api_url: 'https://www.csc.fi/o/events'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "CSC - IT Center for Science",
          url: "https://www.csc.fi",
          image_url: "https://www.csc.fi/documents/10180/161914/CSC_2012_LOGO_RGB_72dpi.jpg/c65ddc42-63fc-44da-8d0f-9f88c54779d7?t=1411391121769",
          description: "CSC - IT Center for Science Ltd. is a non-profit, state-owned company administered by the Finnish Ministry of Education and Culture. CSC maintains and develops the state-owned centralised IT infrastructure and uses it to provide nationwide IT services for research, libraries, archives, museums and culture as well as information, education and research management.
    CSC has the task of promoting the operational framework of Finnish research, education, culture and administration. As a non-profit, government organisation, it is our duty to foster exemplary transparency, honesty and responsibility. Trust is the foundation of CSC's success. Customers, suppliers, owners and personnel alike must feel certain that we will fulfil our commitments and promises in an ethically sustainable manner.
    CSC has offices in Espoo's Keilaniemi and in the Renforsin Ranta business park in Kajaani.",
          content_provider_type: :organisation,
          node_name: :FI
        }))

    events = parse_data(config[:json_api_url])

    events.each do |event|
      if for_tess?(event['keywords'])

        add_event(Tess::API::Event.new(
          content_provider: cp,
          title: event['title'],
          url: event['url'],
          start: event['start'],
          end: event['end'],
          organizer: event['organizer'],
          description: event['organization']&.gsub(/<\/?[^>]*>/, ""), # strip HTML tags
          event_types: [:workshops_and_courses],
          # latitude: event['latitude'],
          # longitude: event['longitude'],
          venue: event['venue'],
          postcode: event['postcode'],
          city: event['city'],
          country: event['country'],
          keywords: event['keywords']
      ))

      end
    end
  end

  private

  def parse_data(url)
    JSON.parse(open_url(url).read)
  end

  def for_tess? keywords
    return keywords.select{|x| x.upcase.include? "TESS"}.any?
  end

end
