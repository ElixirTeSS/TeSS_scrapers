require 'json'

class KhanAcademyApiScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Khan Academy API Scraper',
        root_url: 'https://www.khanacademy.org',
        api_path: '/api/v1/topic/',
        broad_topics: %w() #TODO: Find some topics
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Khan Academy Statistics",
          url: "https://www.khanacademy.org/math/probability",
          image_url: "https://fastly.kastatic.org/images/khan-logo-vertical-transparent.png",
          description: "Can I pick a red frog out of a bag that only contains marbles? Is it smart to buy a lottery ticket? Even if we are unsure about whether something will happen, can we start to be mathematical about the \"chances\" of an event (essentially realizing that some things are more likely than others). These tutorials will introduce us to the tools that allow us to think about random events.",
          content_provider_type: :portal
        }))

    config[:broad_topics].each do |topic|
      response = open_url(config[:root_url] + config[:api_path] + topic)
      topics = JSON.parse(response.read)
      topics['children'].each do |subtopic|
        description = !subtopic['description'].empty? ? subtopic['description'] : "#{subtopic['title']} from #{cp['title']}"
        add_material(Tess::API::Material.new(
            { title: subtopic['title'],
              url: subtopic['url'],
              short_description: description,
              content_provider: cp,
              scientific_topic_names: ['Statistics and probability'],
              keywords: [topics['title']]
            }))
      end
    end
  end
end
