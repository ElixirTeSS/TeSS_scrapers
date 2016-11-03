require 'nokogiri'

class DtlsEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'DTLS Events',
        offline_url_mapping: {},
        root_url: 'http://www.dtls.nl',
        feed_path: '/courses/feed/?filter_course=active'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "DTLS - Dutch Techcentre For Life Sciences", #name
          url: "http://www.dtls.nl", #url
          image_url: "http://www.dtls.nl/wp-content/themes/dtls/images/logo.png", #logo
          description: "DTL focuses on the great potential of high-end technologies in pioneering life science research, and on the skills and solutions to professionally use computers to deal with the ever-growing data streams in research.", #description
          content_provider_type: Tess::API::ContentProvider::PROVIDER_TYPE[:ORGANISATION],
          node: Tess::API::Node::NODE_NAMES[:NL]
        }))

    docs = Nokogiri::XML(open_url(config[:root_url] + config[:feed_path])).xpath('//item')

#fields = docs.first.element_children.collect{|x| x.name}
#locations = docs.collect{|x| x.element_children.collect{|x| x.text if x.name == 'location'}.compact}.flatten  

    docs.each do |event_item|
      event = Tess::API::Event.new({ content_provider: cp })
      event_item.element_children.each do |element|
        event.event_types = [Tess::API::Event::EVENT_TYPE[:workshops_and_courses]]
        case element.name
          when 'title'
            event.title = element.text
          when 'link'
            #Use GUID field as probably more stable
            #event.url = element.text
          when 'creator'
            #event.creator = element.text
            # no creator field. Not sure needs one
          when 'guid'
            event.url = element.text
          when 'description'
            event.description = element.text
          when 'location'
            event.venue = element.text
            loc = element.text.split(',')
            event.city = loc.first.strip
            event.country = loc.last.strip
          when 'provider'
            event.organizer = element.text
          when 'courseDate'
            event.start = element.text
          when 'courseEndDate'
            event.end = element.text
          when 'latitude'
            event.latitude = element.text
          when 'longitude'
            event.longitude = element.text
          when 'pubDate'
            # Not really needed
          else
            #chuck away
        end
        if event.end.nil? or event.end.empty?
          event.end = event.start
        end

      end

      add_event(event)
    end
  end

end
