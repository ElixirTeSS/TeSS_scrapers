require 'nokogiri'
require 'sitemap-parser'

class BioschemasScraper < Tess::Scrapers::Scraper
  def self.config
    config_path = File.expand_path(File.join(__FILE__, '..', '..', '..', 'bioschemas_scraper_config.yml'))
    raise "No config file found at: #{config_path}" unless File.exist?(config_path)

    {
      name: 'Bioschemas Scraper',
      providers: YAML.load(File.read(config_path))['providers'],
      user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0'
    }
  end

  def scrape
    config[:providers].each do |provider_metadata|
      puts "  #{provider_metadata['title']}"
      source_url = provider_metadata.delete('source')
      sitemap_regex = provider_metadata.delete('sitemap_regex')
      sitemap_regex = /#{sitemap_regex}/ if sitemap_regex
      provider = add_content_provider(Tess::API::ContentProvider.new(provider_metadata))

      if source_url.downcase.end_with?('sitemap.xml')
        sources = SitemapParser.new(source_url, {
          recurse: true,
          url_regex: sitemap_regex,
          headers: { 'User-Agent' => config[:user_agent] },
        }).to_a.uniq
      else
        sources = [source_url]
      end

      provider_events = []
      provider_materials = []
      sources.each do |url|
        source = open_url(url)
        next unless source
        sample = source.read(256)&.strip
        next unless sample
        format = sample.start_with?('[') || sample.start_with?('{') ? :jsonld : :rdfa
        source.rewind
        source = source.read
        events = Tess::Rdf::EventExtractor.new(source, format, base_uri: url).extract { |p| Tess::API::Event.new(p) }
        courses = Tess::Rdf::CourseExtractor.new(source, format, base_uri: url).extract { |p| Tess::API::Event.new(p) }
        learning_resources = Tess::Rdf::LearningResourceExtractor.new(source, format, base_uri: url).extract { |p| Tess::API::Material.new(p) }
        if verbose
          puts "Events: #{events.count}"
          puts "Courses: #{courses.count}"
          puts "LearningResources: #{learning_resources.count}"
        end

        deduplicate(events + courses).each do |event|
          event.content_provider = provider
          provider_events << event
        end

        deduplicate(learning_resources).each do |material|
          material.content_provider = provider
          provider_materials << material
        end
      end

      deduplicate(provider_events).each { |event| add_event(event) }
      deduplicate(provider_materials).each { |material| add_material(material) }
    end
  end

  # If duplicate resources have been extracted, prefer ones with the most metadata.
  def deduplicate(resources)
    return [] unless resources.any?
    puts "De-duplicating #{resources.count} resources" if verbose
    hash = {}
    scores = {}
    resources.each do |resource|
      puts "  Considering: #{resource.url}" if verbose
      if hash[resource.url]
        score = metadata_score(resource)
        # Replace the resource if this resource has a higher metadata score
        puts "    Duplicate! Comparing #{score} vs. #{scores[resource.url]}" if verbose
        if score > scores[resource.url]
          puts "    Replacing resource" if verbose
          hash[resource.url] = resource
          scores[resource.url] = score
        end
      else
        puts "    Not present, adding" if verbose
        hash[resource.url] = resource
        scores[resource.url] = metadata_score(resource)
      end
    end

    puts "#{hash.values.count} resources after de-duplication" if verbose

    hash.values
  end

  # Score based on number of metadata fields available
  def metadata_score(resource)
    score = 0
    resource.dump.each_value do |value|
      score += 1 unless value.nil? || value == {} || value == [] || (value.is_a?(String) && value.strip == '')
    end

    score
  end
end
