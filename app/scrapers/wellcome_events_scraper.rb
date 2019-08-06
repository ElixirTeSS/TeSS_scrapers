require 'nokogiri'

class WellcomeEventsScraper < Tess::Scrapers::Scraper
  def self.config
    {
        name: 'Wellcome Genome Campus scraper',
        root_url: 'https://coursesandconferences.wellcomegenomecampus.org',
        index_path: '/events.json'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new({
         title: "Wellcome Genome Campus", #name
         url: config[:root_url], #url
         image_url: "https://i.imgur.com/37JhL8c.png",
         description: "Wellcome Genome Campus Advanced Courses and Scientific Conferences fund, develop and deliver training and conferences that span basic research, cutting-edge biomedicine and the application of genomics in healthcare.",
         content_provider_type: :organisation,
         keywords: ["HDRUK"]
     }))


    json = JSON.parse(open_url(config[:root_url] + config[:index_path]).read)

    json.each do |event|
      event.delete("image_url")
      new_event = Tess::API::Event.new(event)
      new_event.content_provider = cp
      new_event.event_types = [:workshops_and_courses]
      new_event.keywords = ["HDRUK"]
      add_event(new_event )
    end
  end
end
