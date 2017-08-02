require 'icalendar'

class AbacbsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'ABACBS Scraper',
        calendar: 'https://calendar.google.com/calendar/ical/oe7bqnaf44l0eg20lj5c7n1te4%40group.calendar.google.com/public/basic.ics',
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "ABACBS",
          url: "https://www.abacbs.org/",
          image_url: "https://static1.squarespace.com/static/5423875be4b03f0c482a58c4/t/5428c055e4b04de32a8b0fd4/1500958230164/?format=1500w",
          description: "The Australian Bioinformatics and Computational Biology Society Inc or ABACBS (pronounced abacus) is the national scientific and professional society for bioinformatics and computational biology in Australia.  OUR AIMS
Bioinformatics and computational biology deal with the management, analysis and interpretation of biological information, especially at the molecular level.
The Australian Bioinformatics And Computational Biology Society (ABACBS, pron.ˈabəkəs) is focused on the science and profession of bioinformatics and computational biology in Australia.
ABACBS aims to strengthen the science and profession encourage and support students provide representation and advocacy promote interaction and awareness of bioinformatics and computational biology.",
          content_provider_type: :organisation
        }))

        
        file = open_url(config[:calendar])
        events = Icalendar::Event.parse(file.set_encoding('utf-8'))


    events.each_slice(40) do |batch|
      batch.each do |event|
        begin
            uri = URI.extract(event.description.value, ['http', 'https'])
            puts uri
            add_event(Tess::API::Event.new(
                { content_provider: cp,
                  title: event.summary,
                  url: uri.first,
                  start: event.dtstart,
                  end: event.dtend,
                  description: event.description.value,
                  event_types: [:workshops_and_courses]
                }))
end
end
end


  end
end
