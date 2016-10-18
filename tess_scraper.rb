require 'open-uri'
require 'tess_api_client'

class TessScraper

  attr_accessor :output_file, :debug, :verbose, :offline
  attr_reader :scraped

  def initialize(output_file: nil, debug: false, verbose: false, offline: false)
    @output_file = output_file
    @debug = debug || Tess::API::ScraperConfig.debug?
    @verbose = verbose
    @offline = offline
    @scraped = { content_providers: [], events: [], materials: [] }
  end

  def self.config
    {
        name: 'Unnamed Scraper',
        offline_url_mapping: {}
    }
  end

  # Run the scraper
  def run
    puts "[Running #{self.class.config[:name]}]"
    puts 'Scraping...'
    scrape
    log(@output_file ? File.open(@output_file) : STDOUT)

    unless @debug
      puts 'Persisting...'
      persist
    end

    puts 'Done'
  end

  def scrape
    raise "No 'scrape' method implemented!"
  end

  def persist
    @scraped[:content_providers].each do |content_provider|
      content_provider.create_or_update
    end

    [:events, :materials].each do |type|
      @scraped[type].each do |resource|
        resource.create_or_update
      end
    end
  end

  # If in online mode, returns the content of the URL
  # If in offline mode, either skips the URL or opens the corresponding file for that URL, as defined in
  #   `config[:offline_url_mapping]`
  def open_url(url)
    if @offline
      if self.class.config[:offline_url_mapping].key?(url)
        puts "Reading from local file: #{self.class.config[:offline_url_mapping][url]}"
        File.open(self.class.config[:offline_url_mapping][url])
      else
        puts "Skipping URL, no offline file found for: #{url}"
      end
    else
      puts "Reading from remote URL: #{url}"
      open(url)
    end
  end

  def add_content_provider(params)
    Tess::API::ContentProvider.new(params).tap do |cp|
      @scraped[:content_providers] << cp
    end
  end

  def add_event(params)
    Tess::API::Event.new(params).tap do |e|
      @scraped[:events] << e
    end
  end

  def add_material(params)
    Tess::API::Material.new(params).tap do |m|
      @scraped[:materials] << m
    end
  end

  def log(output)
    output.puts 'Resources scraped:'
    summary = StringIO.new
    @scraped.each do |type, resources|
      if resources.any?
        output.puts '-' * 40
        output.puts type.to_s
        if @verbose
          resources.each do |resource|
            output.puts '  {'
            resource.dump.each do |attr, value|
              output.puts "    '#{attr}' => #{value.inspect}" unless value.nil? || (value == [])
            end
            output.puts '  }'
            output.puts
          end
        end
      end
      summary.puts "#{resources.length} #{type} scraped"
      created = resources.select { |r| r.last_action == :create }
      updated = resources.select { |r| r.last_action == :update }
      summary.puts "  #{created.length} created"
      summary.puts "  #{updated.length} updated"
      summary.puts
    end
    output.puts '=' * 40
    output.puts
    output.puts 'Summary:'
    output.puts
    summary.rewind
    output.puts summary.read
  end

end
