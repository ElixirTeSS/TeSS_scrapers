require 'nokogiri'

class EbiScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'EBI Scraper',
        offline_url_mapping: {},
        root_url: 'http://www.ebi.ac.uk',
        course_page: '/training/online/course-list'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "European Bioinformatics Institute (EBI)", #name
          url: "http://www.ebi.ac.uk", #url
          image_url: "http://www.ebi.ac.uk/miriam/static/main/img/EBI_logo.png", #logo
          description: "EMBL-EBI provides freely available data from life science experiments, performs basic research in computational biology and offers an extensive user training programme, supporting researchers in academia and industry.", #description
          content_provider_type: Tess::API::ContentProvider::PROVIDER_TYPE[:ORGANISATION],
          node: Tess::API::Node::NODE_NAMES[:'EMBL-EBI']
        }))

    lessons = {}

    1.upto(last_page_number) do |num|
      page = config[:course_page] + '?page=' + num.to_s
      puts "Scraping page: #{num.to_s}"
      doc = Nokogiri::HTML(open_url(config[:root_url] + page))

      #first = doc.css('div.item-list').search('li')
      first = doc.css('div.views-row')
      first.each do |f|
        titles = f.css('div.views-field-title').css('span.field-content').search('a')
        desc = f.css('div.views-field-field-course-desc-value').css('div.field-content').search('p')
        topics = f.css('div.views-field-tid').css('span.field-content').search('a')

        #puts "TITLES: #{titles.css('a')[0]['href']}, #{titles.text}"
        #puts "DESC: #{desc.text}"
        #puts "TOPICS: #{topics.collect{|t| t.text }}"

        href = titles.css('a')[0]['href']
        lessons[href] = {}
        lessons[href]['description'] = desc.text.strip
        lessons[href]['text'] = titles.css('a')[0].text
        topic_text =  topics.collect{|t| t.text }
        if !topic_text.empty?
          #lessons[href]['topics'] = topic_text.map{|t| {'name' => t.gsub(/[^0-9a-z ]/i, ' ')} } # Replaces extract_keywords
          lessons[href]['topics'] = topic_text.collect{|t| t.gsub(/[^0-9a-z ]/i, ' ') } # Replaces extract_keywords
        end                                                                             # Non-alphanumeric purged
      end
    end

    # Create the new record
    lessons.each_key do |path, lesson|
      add_material(Tess::API::Material.new(
          { title: lesson['text'],
            url: config[:root_url] + path,
            short_description: "#{lesson['text']} from #{config[:root_url] + path}.",
            doi: nil,
            remote_updated_date: Time.now,
            remote_created_date: lesson['last_modified'],
            content_provider: cp,
            scientific_topic: lesson['topics'],
            keywords: lesson['topics']}))
    end
  end

  private

  def last_page_number
    doc = Nokogiri::HTML(open_url(config[:root_url] + config[:course_page]))

    doc.css('li.pager-last a').attr('href').value.scan(/page=([0-9]+)/).flatten.first.to_i
  end

end
