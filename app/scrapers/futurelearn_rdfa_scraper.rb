require 'tess_api_client'

class FuturelearnRdfaScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Future Learn JSON-LD Scraper',
        root_url: 'https://www.futurelearn.com',
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Future Learn",
          url: "https://www.futurelearn.com/courses/collections/genomics",
          image_url: "http://static.tumblr.com/1f4d7873a6ff8a8c0d571adf0d4e867f/ejyensv/ubIn1b1rl/tumblr_static_fl_logo_white.jpg",
          description: "Discover the growing importance of genomics in healthcare research, diagnosis and treatment, with these free online courses. Learn with researchers and clinicians from leading universities and medical schools.",
          content_provider_type: :portal
        }))

    events = []

    urls = ["#{config[:root_url]}/courses/collections/genomics",
            "#{config[:root_url]}/search?utf8=%E2%9C%93&q=bioinformatics"]

    urls.each do |url|
      events += Tess::Rdf::EventExtractor.new(open_url(url), :rdfa).extract { |p| Tess::API::Event.new(p) }
    end

    events.each do |event|
      event.content_provider = cp
      event.online = true
      event.event_types = [:workshops_and_courses]
      add_event(event)
    end
  end

end
