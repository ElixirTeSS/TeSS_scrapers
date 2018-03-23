class BioconductorScraper  < Tess::Scrapers::Scraper

  # TODO: This is a work in progress, 8/3/18

  def self.config
    {
        name: 'Bioconductor Scraper',
        offline_url_mapping: {},
        root_url: 'https://raw.githubusercontent.com/Bioconductor/bioconductor.org/master/etc/course_descriptions.tsv'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: 'Bioconductor',
          url: 'https://bio.tools/bioconductor',
          image_url: 'https://bio.tools/img/elixir_navbar_home_dark.png',
          description: 'Open development software project, based on the R programming language,
                        providing tools for the analysis of high-throughput genomic data. The project aims to enable
                        interdisciplinary research, collaboration and rapid development of scientific software.',
          content_provider_type: :project
        }))

    get_records(config[:root_url]).each do |record|
      #puts record.inspect
      next if record[0] == 'Date' # First line of the record
      next if %w[Talk Conference Introduction].include?(record[2]) # These are old events; skip them

      title = record[3].gsub(/_/,'')
      if record[4]
        authors = [record[4].split(',')]
      else
        authors = []
      end
      if record[5]
        links = get_urls(record[5])
        puts links.inspect
      end
      next unless links

      material = Tess::API::Material.new(title: title,
                                         url: links[1],
                                         authors: authors
                                        )
    end

  end

  private

  def get_records(url)
    #uri = URI.parse(url)
    #data = open(uri)
    data = IO.read("course_descriptions.tsv")
    CSV.parse(data).collect {|x| x[0].split(/\t/)}
  end

  def get_urls(string)
    # TODO: Fix this regex so it matches multiple times...
    urls = /\[[A-Za-z]*\]\(([^)(]*)\)/.match(string)
    # TODO: Some of these URLs are only paths...
    # TODO: Need to add the correct URL for the material here, but what is it?
    if urls
      return urls
    else
      return nil
    end


  end



end