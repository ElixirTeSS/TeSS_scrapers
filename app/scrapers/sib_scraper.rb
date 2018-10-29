class SibScraper < Tess::Scrapers::Scraper

  def self.config
  {
    name: 'SIB Scraper',
    root_url: 'https://edu.isb-sib.ch',
    materials_path: 'course/index.php?categoryid=2',
  }
  end
  # https://edu.isb-sib.ch/course/index.php?categoryid=2

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
                                title: 'Swiss Institute of Bioinformatics',
                                url: 'http://edu.isb-sib.ch/',
                                image_url: 'http://bcf.isb-sib.ch/img/sib.png',
                                description: 'The SIB Swiss Institute of Bioinformatics is an academic, non-profit
foundation recognised of public utility and established in 1998. SIB coordinates research and education in
bioinformatics throughout Switzerland and provides high quality bioinformatics services to the national and
international research community.',
                                content_provider_type: :organisation,
                                node_name: :CH
    ))


    lessons = parse_data(config[:materials_path])

    lessons.each do |url, data|
      material = Tess::API::Material.new(
        title: data['name'],
        url: url,
        short_description: data['description'],
        remote_updated_date: data['updated'],
        content_provider: cp
      )

      add_material(material)
    end



  end



  private

  def parse_data(page)
    lessons = {}

    doc = Nokogiri::HTML(open_url("#{config[:root_url]}/#{page}"))


    doc.css("div.coursebox").map do |coursebox|
      course = coursebox.at_css("a")
      next unless course
      url = course['href']
      name = course.text.strip
      desc = coursebox.at_css('p')
      if desc
        description = desc.text.strip
      else
        description = 'No description provided.'
      end
      lessons[url] = {}
      lessons[url]['name'] = name
      lessons[url]['description'] = description
    end

    lessons
  end



end
