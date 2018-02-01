require 'nokogiri'

class CscEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'CSC Events Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.csc.fi/web/training/'
    }
  end

  def scrape
    events = {}

    doc = Nokogiri::HTML(open(config[:root_url]).read)

    doc.css('div.csc-article').each do |article|
      categories = article.search('.koulutus-category').collect {|x| x.text.strip}.reject(&:empty?)
      header = article.search('h3 > a')[0]
      link = header['href']
      title = header.text
      description = article.search('.article-summary')[0].text

      events[link] = {'title' => title,
                      'description' => description,
                      'event_types' => categories,
                      'keywords' => categories} if for_tess?(categories)
    end

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

    events.each do |url, event_info|
        lat,lon = nil # Can't seem to get these out of the Google maps URL
        start_date, end_date, venue = nil

        newpage = Nokogiri::HTML(open_url(url))

        newpage.search('table > tr').each do |row|
          fieldname = row.css('td')[0].text.strip
          if fieldname == 'Date:'
            datefield = row.css('td')[1].text.strip
            start_date,end_date = datefield.split(/ - /)
          elsif fieldname == 'Location details:'
            venue = row.css('td')[1].text.strip
            # Strip out certain long strings we don't need in the venue.
            venue.gsub!(/^The event is organised at the /,"")
            venue.gsub!(/^The event is organised at /,"")
            venue.gsub!(/ The best way to reach us is by public transportation; more detailed travel tips(\)?) are available.$/,"")
          end
        end


        add_event(Tess::API::Event.new(
                    content_provider: cp,
                    title: event_info['title'],
                    url: url,
                    description: event_info['description'],
                    event_types: get_event_type(event_info['event_types']),
                    start: start_date,
                    end: end_date,
                    venue: venue
                  ))
    end
  end

  def for_tess? keywords
    return keywords.select{|x| x.include? "tess"}.any?
  end

  def get_event_type text
    type = []
    if text.include?('Courses and workshops')
      type << :workshops_and_courses
    end
    return type
  end
end