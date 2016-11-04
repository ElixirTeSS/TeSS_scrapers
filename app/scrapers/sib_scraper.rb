class SibScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'SIB Scraper',
        offline_url_mapping: {},
        root_url: 'http://edu.isb-sib.ch',
        materials_path: 'course/index.php?categoryid=2',
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Swiss Institute of Bioinformatics",
          url: "http://edu.isb-sib.ch/",
          image_url: "http://bcf.isb-sib.ch/img/sib.png",
          description: "The SIB Swiss Institute of Bioinformatics is an academic, non-profit foundation recognised of public utility and established in 1998. SIB coordinates research and education in bioinformatics throughout Switzerland and provides high quality bioinformatics services to the national and international research community.",
          content_provider_type: Tess::API::ContentProvider::PROVIDER_TYPE[:ORGANISATION],
          node: Tess::API::Node::NODE_NAMES[:CH]
        }))


    lessons = parse_data(config[:materials_path])

    lessons.each do |url, data|
      material = Tess::API::Material.new(
          { title: data['name'],
            url: url,
            short_description: data['description'],
            remote_updated_date: data['updated'],
            content_provider: cp
          })

      add_material(material)
    end
  end

  private

  def parse_data(page)
    lessons = {}

    doc = Nokogiri::HTML(open_url("#{config[:root_url]}/#{page}"))

    # Now to obtain the exciting course information!
    #links = doc.css('#wiki-content-container').search('li')
    #links.each do |li|
    #  puts "LI: #{li}"
    #end

    links = doc.css("div.coursebox").map do |coursebox|
      course = coursebox.at_css("a")
      if course
        url = course['href']
        name = course.text.strip
        description = coursebox.at_css("p").text.strip
        lessons[url] = {}
        lessons[url]['name'] = name
        lessons[url]['description'] = description
      end
    end

    lessons
  end
end
