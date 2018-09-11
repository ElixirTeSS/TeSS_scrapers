class CourseraScraper < Tess::Scrapers::Scraper
  # For more details of the API and available terms, see:
  # https://building.coursera.org/app-platform/catalog/

  def self.config
    {
        name: 'Coursera Scraper',
        root_url: 'https://api.coursera.org/api/courses.v1',
        friendly_url: 'https://www.coursera.org/learn/',
        search_term: 'bioinformatics',
        search_fields: 'description,domainTypes,primaryLanguages,subtitleLanguages'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Coursera",
          url: "http://www.coursera.org",
          image_url: "http://logonoid.com/images/coursera-logo.png",
          description: "Coursera is an education platform that partners with top universities and organizations worldwide, to offer courses online for anyone to take, for free.",
          content_provider_type: :portal
        }))

    course_ids = parse_data("/?q=search&query=#{config[:search_term]}&limit=10")['elements'].collect {|x| x['id']}
    course_url = "?ids=#{course_ids.join(',')}&fields=#{config[:search_fields]}"
    parse_data(course_url)['elements'].each do |course|
      next unless course['primaryLanguages'].include?('en') # There are some Russian courses turning up...
      topics = [course['domainTypes'].collect {|x| x['domainId'] }, course['domainTypes'].collect {|x| x['subdomainId'] }].flatten.uniq

      add_material(Tess::API::Material.new(
          { title: course['name'],
            url: config[:friendly_url] + course['slug'],
            short_description: course['description'],
            content_provider: cp,
            keywords: topics
          }))
    end
  end

  private

  def parse_data(page)
    JSON.parse(open_url((config[:root_url]+ page)).read)
  end

end
