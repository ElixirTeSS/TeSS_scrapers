require 'nokogiri'

class DataCarpentryScraper < Tess::Scrapers::Scraper
  # For more details of the API and available terms, see:
  # https://building.coursera.org/app-platform/catalog/

  def self.config
    {
        name: 'Data Carpentry Scraper',
        offline_url_mapping: {},
        root_url: 'http://www.datacarpentry.org',
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Data Carpentry",
          url: "http://www.datacarpentry.org",
          image_url: "http://www.datacarpentry.org/assets/img/DC_logo_vision.png",
          description: "Data Carpentry's aim is to teach researchers basic concepts, skills, and tools for working with data so that they can get more done in less time, and with less pain.",
          content_provider_type: :organisation
        }))

    doc = Nokogiri::HTML(open_url(config[:root_url] + '/lessons'))
    exclude = [' Feeling Responsive']
    lessons = {}
    description = ''
    
    #first = doc.css('div.item-list').search('li')
    lesson_urls = doc.css('td > a').collect { |x| x.values }.flatten.select { |x| x.include?('github.io') }

    lesson_urls.each do |lesson_url|
      lesson = Nokogiri::HTML(open(lesson_url))
      title = lesson.css('h1').text
      unless exclude.include?(title)
        if title.empty?
          title = lesson.css('p').first.text.gsub('<p>#', '').gsub('</p>', '').gsub('#', '')
          description = lesson.css('p')[2]
        else
          description = lesson.css('p')[0].text
          if description == '======='
            description = lesson.css('p')[1].text
          end
        end
        descriptions = []
        index = 0
        while !description.include?('Content Contributors') and index < 5 do
          description = lesson.css('p')[index=index+1]
          descriptions << lesson.css('p')[index]
        end
        lessons[lesson_url] = {}
        lessons[lesson_url]['short_description'] = descriptions.join(' ')
        lessons[lesson_url]['long_description'] = lesson.css('p h1 a')
        lessons[lesson_url]['title'] = title
      end
    end

    lessons.each do |url, data|
      add_material(Tess::API::Material.new(
          { title: data['title'],
            url: url,
            short_description: data['short_description'],
            content_provider: cp,
            long_description: data['long_description']}))
    end
  end
end
