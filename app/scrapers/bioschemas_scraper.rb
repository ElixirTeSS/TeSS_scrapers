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
        materials = Tess::Rdf::MaterialExtractor.new(source, format, base_uri: url).extract { |p| Tess::API::Material.new(p) }
        if debug
          puts "Events: #{events.count}"
          puts "Courses: #{courses.count}"
          puts "TrainingMaterials: #{materials.count}"
        end

        (events + courses).each do |event|
          event.content_provider = provider
          add_event(event)
        end

        materials.each do |material|
          material.content_provider = provider
          add_event(material)
        end
      end
    end
  end
end
