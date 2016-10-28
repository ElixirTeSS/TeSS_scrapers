module Tess
  module Scrapers
    class Scraper

      CACHE_ROOT_DIR = 'tmp'

      attr_accessor :output_file, :debug, :verbose, :offline, :cache
      attr_reader :scraped

      def initialize(output_file: nil, debug: false, verbose: false, offline: false, cache: false)
        @output_file = output_file
        @debug = debug || Tess::API.debug?
        @verbose = verbose
        @offline = offline
        @cache = cache
        @scraped = { content_providers: [], events: [], materials: [] }
      end

      def self.config
        {
            name: 'Unnamed Scraper',
            offline_url_mapping: {} # TODO: Decide if this is really needed
        }
      end

      def config
        self.class.config
      end

      # Run the scraper
      def run
        puts "[Running #{config[:name]}]"
        puts 'Scraping...'
        scrape

        unless debug
          puts 'Persisting...'
          persist
        end

        log(output_file ? File.open(output_file) : STDOUT)

        puts 'Done'
      end

      def scrape
        raise "No 'scrape' method implemented!"
      end

      def persist
        scraped[:content_providers].each do |content_provider|
          content_provider.create_or_update
        end

        scraped.each do |type, resources|
          unless type == :content_providers
            resources.each do |resource|
              resource.create_or_update
            end
          end
        end
      end

      # If in online mode, returns the content of the URL
      # If in offline mode, either skips the URL or opens the corresponding file for that URL, as defined in
      #   `config[:offline_url_mapping]`
      def open_url(url)
        puts "Opening URL: #{url}" if verbose

        if offline
          if config[:offline_url_mapping].key?(url)
            puts "... using local file: #{config[:offline_url_mapping][url]}" if verbose
            File.open(config[:offline_url_mapping][url])
          elsif (cache_path = cache_file_path(Digest::SHA1.hexdigest(url))) && File.exists?(cache_path)
            puts "... using cache: #{cache_path}" if verbose
            File.open(cache_path)
          else
            puts "... skipping! No offline file or cache entry found" if verbose
          end
        else
          puts "... from remote location" if verbose
          open(url).tap do |f|
            cache_file(url, f) if cache
            f.rewind
          end
        end
      end

      def add_content_provider(cp)
        scraped[:content_providers] << cp

        cp
      end

      def add_event(event)
        scraped[:events] << event

        event
      end

      def add_material(material)
        scraped[:materials] << material

        material
      end

      def log(output)
        if verbose
          output.puts 'Resources scraped:'
          scraped.each do |type, resources|
            if resources.any?
              output.puts '-' * 40
              output.puts type.to_s
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
          output.puts
          output.puts '=' * 40
        end
        output.puts
        output.puts 'Summary:'
        output.puts
        scraped.each do |type, resources|
          output.puts "#{resources.length} #{type} scraped"
          created = resources.select { |r| r.last_action == :create }
          updated = resources.select { |r| r.last_action == :update }
          output.puts "  #{created.length} created"
          output.puts "  #{updated.length} updated"
        end
        output.puts
      end

      def cache_file(url, file)
        path = Digest::SHA1.hexdigest(url)

        cached_file_path = cache_file_path(path, true)

        puts "Caching in: #{cached_file_path}"
        File.open(cached_file_path, 'w') do |cf|
          cf.write(file.read)
        end
      end

      def cache_file_path(filepath, create_dirs = false)
        path = File.join(CACHE_ROOT_DIR, self.class.name, filepath)

        if create_dirs
          # Create the directories needed
          dirname = File.dirname(path)
          FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
        end

        path
      end

    end
  end
end
