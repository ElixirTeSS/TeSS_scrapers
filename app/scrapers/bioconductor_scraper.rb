class BioconductorScraper  < Tess::Scrapers::Scraper

  # TODO: This is a work in progress, 8/3/18

  def self.config
    {
        name: 'Bioconductor Scraper',
        root_url: 'https://raw.githubusercontent.com/Bioconductor/bioconductor.org/master/etc/course_descriptions.tsv',
        material_url: 'https://bioconductor.org/help/course-materials/'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: 'Bioconductor',
          url: 'https://www.bioconductor.org/help/course-materials/',
          image_url: 'https://www.bioconductor.org/images/logo_bioconductor.gif',
          description: 'Open development software project, based on the R programming language,
                        providing tools for the analysis of high-throughput genomic data. The project aims to enable
                        interdisciplinary research, collaboration and rapid development of scientific software.',
          content_provider_type: :project
        }))

    get_records(config[:root_url]).each do |record|
      #puts record.inspect
      next if record[0] == 'Date' # First line of the record
      # All records to now be included as per comments on #51
      #next if %w[Talk Conference Introduction].include?(record[2]) # These are old events; skip them

      title = record[3].gsub(/_/,'')
      description = "Bioconductor provides tools for the analysis and comprehension of high-throughput genomic data.
                    Bioconductor uses the R statistical programming language, and is open source and open development. 
                    It has two releases each year, 1560 software packages, and an active user community. 
                    Bioconductor is also available as an AMI (Amazon Machine Image) and a series of Docker images."

      if record[4]
        authors = [record[4].split(',')]
      else
        authors = []
      end
      if record[5]
        links = get_urls(record[5])
        #puts links.inspect
      end
      keywords = record[2] if record[2].present?

      next unless links

      material = Tess::API::Material.new(
        {
          title: title,
          url: "#{config[:material_url]}#{links[1]}",
          authors: authors,
          content_provider: cp,
          short_description: description,
          external_resources_attributes: {url: 'https://bio.tools/bioconductor', title: 'Bioconductor'}
        }.merge(sortKeywords(keywords))
      )
      add_material(material)
      #puts material.inspect
    end

  end

  private


  def sortKeywords(keyword)
    operation_names = []
    scientific_topic_names = []
    resource_type = []
    difficulty_level = ''
    case keyword
      when 'RNASeq'
        scientific_topic_names << 'RNA-Seq'
      when 'DNASeq'
        scientific_topic_names << 'Sequencing'            
      when 'Microarray'
        scientific_topic_names << 'Microarray experiment'       
      when 'ChIPSeq'
        scientific_topic_names << 'ChIP-seq'      
      when 'Proteomics'
        scientific_topic_names << 'Proteomics'         
      when 'Genomic Ranges'
        scientific_topic_names << 'Genomics'               
      when 'Statistics'
        scientific_topic_names << 'Statistics and probability'      
      when 'Variants'
        operation_names << 'Variant calling'
      when 'Visualization'
        operation_names << 'Visualisation'
      when 'Machine Learning'
        scientific_topic_names << 'Machine learning'
      when 'Reporting'
        operation_names << 'Report'
      when 'Annotation'
        operation_names << 'Annotation'
      when 'Gene set enrichment'
        operation_names << 'Gene-set enrichment analysis'
      when 'Methylation'
        operation_names << 'Methylation analysis'
      when 'Introduction'
        difficulty_level = 'Beginner'
      when 'Talk'
        resource_type << 'Talk'
      else
        keywords, operation_names, scientific_topic_names = keyword #see if anything shows up and set as keywords
    end
    return {
        :keywords => keywords,
        :operation_names => operation_names,
        :scientific_topic_names => scientific_topic_names,
        :resource_type => resource_type,
        :difficulty_level => difficulty_level
    }.delete_if{|k,v| v.nil? or v.empty?}
  end

  def get_records(url)
    uri = URI.parse(url)
    data = open(uri)
    #data = IO.read("course_descriptions.tsv")
    CSV.parse(data).collect {|x| x[0].split(/\t/)}
  end

  def get_urls(string)
    # TODO: Fix this regex so it matches multiple times...
    urls = /\[[A-Za-z]*\]\(([^)(]*)\)/.match(string)
    if urls
      return urls
    else
      return nil
    end

  end

end