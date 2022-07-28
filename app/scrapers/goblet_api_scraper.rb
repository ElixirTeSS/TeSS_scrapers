require 'nokogiri'

class GobletApiScraper < Tess::Scrapers::Scraper

  def self.config
  {
    name: 'Goblet API Scraper',
    root_url: 'http://www.mygoblet.org',
    courses_path: '/training-portal/courses-xml', # Unused?
    materials_path: '/training-portal/materials-xml'
  }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
                                title: 'GOBLET',
                                url: 'http://www.mygoblet.org',
                                image_url: 'http://www.mygoblet.org/sites/default/files/logo_goblet_trans.png',
                                description: 'GOBLET, the Global Organisation for Bioinformatics Learning, Education
and Training, is a legally registered foundation providing a global, sustainable support and networking structure for
bioinformatics educators/trainers and students/trainees.',
                                content_provider_type: :portal
    ))

    [config[:materials_path], config[:courses_path]].each do |url|
      lessons = parse_data(url)
      lessons.each_key do |key|
        material = Tess::API::Material.new(title: lessons[key][:title],
                                           url: key,
                                           description: "#{lessons[key][:title]} from #{key}.",
                                           doi: nil,
                                           remote_updated_date: lessons[key][:updated],
                                           remote_created_date: nil,
                                           scientific_topic_names: lessons[key][:topics],
                                           keywords: lessons[key][:topics],
                                           content_provider: cp
        )
        add_material(material)

      end
    end



  end

  private

  def parse_data(url)
    lessons = {}
    page = "#{config[:root_url]}/#{url}"
    doc = Nokogiri::XML(open_url(page))

    doc.search('nodes > node').each do |node|

      url = nil
      title = nil
      updated = nil
      rating = nil
      topics = nil

      node.search('Title').each do |t|
        title = t.inner_text
      end
      node.search('Updated-data').each do |t|
        updated = t.inner_text
      end
      node.search('Rating').each do |t|
        rating = t.inner_text
      end
      node.search('Topic').each do |t|
        if t.inner_text
          topics = t.inner_text.split(',')
        end
      end
      node.search('URL').each do |t|
        url = t.inner_text
      end

      if url
        lessons[url] = {title: title,
                        updated: updated,
                        rating: rating,
                        topics: topics}
      else
        puts "No URL found for #{title}"
      end
    end
    lessons

  end

end