require 'nokogiri'

class DataCarpentryScraper < Tess::Scrapers::Scraper
  # For more details of the API and available terms, see:
  # https://building.coursera.org/app-platform/catalog/

  def self.config
    {
        name: 'Data Carpentry Scraper',
        root_url: 'https://www.datacarpentry.org',
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Data Carpentry",
          url: "https://www.datacarpentry.org",
          image_url: "http://www.datacarpentry.org/assets/img/DC_logo_vision.png",
          description: "Data Carpentry's aim is to teach researchers basic concepts, skills, and tools for working with data so that they can get more done in less time, and with less pain.",
          content_provider_type: :organisation
        }))

    doc = Nokogiri::HTML(open_url(config[:root_url] + '/lessons/'))
    exclude = [' Feeling Responsive']
    lessons = {}
    description = ''
    
    #first = doc.css('div.item-list').search('li')
    lesson_urls = doc.css('td > a').collect { |x| x.values }.flatten.select { |x| x.include?('github.io') }

    lesson_urls.each do |lesson_url|
      lesson = Nokogiri::HTML(open_url(lesson_url))
      title = lesson.css('h1').text
      unless exclude.include?(title)
        paragraphs = lesson.css('p')
        if paragraphs.empty?
          puts "No paragraphs found for #{lesson_url}"
          next
        end
        if title.empty?
          title = paragraphs.first.text.gsub('<p>#', '').gsub('</p>', '').gsub('#', '')
          description = paragraphs[2]
        else
          description = paragraphs[0].text
          if description == '======='
            description = paragraphs[1].text
          end
        end
        descriptions = []
        index = 0
        while description && !description.include?('Content Contributors') && index < 5 do
          description = paragraphs[index=index+1]
          descriptions << paragraphs[index]
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
