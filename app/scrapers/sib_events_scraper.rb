class SibEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
      name: 'SIB Events Scraper',
      root_url: 'https://www.sib.swiss/training/upcoming-training-events'
    }
  end

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

    events = get_events(config[:root_url])
    events.each do |event|
      external_id = event['@id']
      email = event['schema:contact']['schema:email']
      description = event['schema:description'].gsub('\\n', ' ')
      start = event['schema:startDate']
      finish = event['schema:endDate']
      host = event['schema:hostInstitution']['schema:name']
      address = event['schema:location']['schema:address'] # Seems to be a duplicate of City
      city = event['schema:location']['schema:name']
      title = trim_characters(event['schema:name'])
      url = event['schema:url']
      new = Tess::API::Event.new(
        content_provider: cp,
        external_id: external_id,
        contact: email,
        title: title,
        description: description,
        url: url,
        city: city,
        start: start,
        end: finish,
        venue: host,
        event_types: get_event_type(event['schema:eventType'])
      )
      add_event(new)
    end
  end

  private

  def get_events(url)
    reader = RDF::Reader.for(:rdfa).new(open_url(url))
    rdfa = RDF::Graph.new << reader
    Tess::Scrapers::RdfaExtractor.parse_rdfa(rdfa, 'Event')
  end

  # TODO: Find out if any more topics are likely to be used and add them here.
  def get_event_type(type)
    if type.casecmp('Workshops and courses')
      return [:workshops_and_courses]
    end
    []
  end


  def trim_characters(attribute)
    if attribute.class == String
      attribute.gsub('\\n', '').gsub('\\t', '').strip
    elsif attribute.class == Array
      attribute.collect{ |x| x.gsub('\\n', '').gsub('\\t', '').strip }
    end
  end

end

