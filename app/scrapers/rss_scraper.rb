class RssScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'RSS RSS Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.statslife.org.uk',
        events_path: '/index.php?option=com_jevents&task=modlatest.rss&format=feed&type=rss&modid=284',
        location: {
            organizer: 'Royal Statistical Society',
            venue: 'The Royal Statistical Society',
            city: 'London',
            country: 'United Kingdom',
            postcode: 'EC1Y 8LX',
            latitude: 51.5225237,
            longitude: -0.0909223
        }
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Royal Statistical Society",
          url: "https://www.statslife.org.uk/",
          image_url: "https://www2.warwick.ac.uk/fac/sci/statistics/courses/rss/rss-strapline-logo-360x180.jpg",
          description: "Royal Statistical Society is a world-leading organisation promoting the importance of statistics and data - and a professional body for all statisticians and data analysts.",
          content_provider_type: Tess::API::ContentProvider::PROVIDER_TYPE[:ORGANISATION]
        }))

    events = parse_data(config[:root_url] + config[:events_path])

    events.each do |url, data|
      event = Tess::API::Event.new(
          { content_provider: cp,
            title: data[:title],
            url: url,
            start_date: data[:start_date],
            end_date: data[:end_date],
            description: data[:description],
            organizer: 'Royal Statistical Society',
            event_types: [Tess::API::Event::EVENT_TYPE[:workshops_and_courses]]
          }.merge(config[:location]))
      add_event(event)
    end
  end

  private

  #separate date and title
  #presented in format: "23 Jun 2016 10:00 : Presenting Data"
  def parse_title string
    return string.split(' : ')
  end

  #Parse the HTML of the description to extract the duration. Return this as number of seconds
  # to offset from start date
  def duration_offset text
    match_data = text.match('CPD\s[-\s]*([0-9])*\s(hours|days)')
    #unit = match_data[2]  All are in hours - you can use this if they change to using days.
    if match_data
      return match_data[1].to_i * 3600 #86400 if days
    else
      0
    end

  end

  #Found in the description. Parsing should account for different list styles
  #Presented by Richard D. Morey
  #Presented by Geert Verbeke and Geert Molenberghs
  #Presented by Tim Morris, Michael Crowther &amp; Ian White
  #Presented by -&nbsp;Ellen Marshall (University of Sheffield)&nbsp;and Jenny Freeman (University of Leeds)
  def presented_by text

  end

  def parse_data(page)
    events = {}

    rss_feed = open_url(page)
    items = Nokogiri::XML(rss_feed).xpath('//item')
    items.each do |item|
      url = item.children.find{|x| x.name == 'link'}.text
      title_element = item.children.find{|x| x.name == 'title'}
      description = item.children.find{|x| x.name == 'description'}.text
      date, title = parse_title title_element.text
      start_date =  Time.parse(date)
      end_date = (start_date + duration_offset(description))
      events[url] = {
          title: title,
          description: description,
          start_date: start_date.to_s,
          end_date: end_date.to_s
      }
    end

    events
  end
end
