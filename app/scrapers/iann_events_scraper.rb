require 'nokogiri'

class IannEventsScraper < Tess::Scrapers::Scraper

  IANN_MAPPING =  {"Systemsbiology"=>"Systems biology", "Systems Biology"=>"Systems biology", "Genomics"=>"Genomics", "Bioinformatics"=>"Bioinformatics", "Computationalbiology"=>"Computational biology", "Metagenomics"=>"Metagenomics", "Computerscience"=>"Computer science", "Proteomics"=>"Proteomics", "Dataanalysis"=>"Data architecture, analysis and design", "RNA-Seq"=>"RNA-Seq", "Immunology"=>"Immunology", "Medicine"=>"Medicine", "Datavisualisation"=>"Data visualisation", "Medicalimaging"=>"Medical imaging", "Geneexpression"=>"Gene expression", "Geneexpressionandmicroarray"=>"Gene expression", "High-throughputsequencing"=>"Sequencing", "Pharmacology"=>"Pharmacology", "Biology"=>"Biology", "Pathology"=>"Pathology", "Medicalinformatics"=>"Medical informatics", "ChIP-seq"=>"ChIP-seq", "Computationalchemistry"=>"Computational chemistry", "Computerprogramming"=>"Software engineering", "Biomedicalscience"=>"Biomedical science", "Datamanagement"=>"Data management", "Datadeposition"=>"Data submission, annotation and curation", "annotationandcuration"=>"Data submission, annotation and curation", "Moleculardynamics"=>"Molecular dynamics", "Molecularmodelling"=>"Molecular modelling", "Biochemistry"=>"Biochemistry", "DNAmethylation"=>"Epigenetics", "Epigenetics"=>"Epigenetics", "Datasearch"=>"Data management", "queryandretrieval"=>"Data management", "Tooltopic"=>"Data management", "Metabolomics"=>"Metabolomics", "Datamining"=>"Data mining", "Microbiology"=>"Microbiology", "Ecology"=>"Ecology", "Evolutionarybiology"=>"Evolutionary biology", "Theoreticalbiology"=>"Computational biology", "Epigenomics"=>"Epigenomics", "Transcriptomics"=>"Transcriptomics", "Physiology"=>"Physiology", "Anaesthesiology"=>"Anaesthesiology", "Humans"=>"Humans", "Biotherapeutics"=>"Drug formulation and delivery", "Biostatistics"=>"Statistics and probability", "Epidemiology"=>"Public health and epidemiology", "ResearchPathology"=>"Preclinical and clinical studies", "Clinical Studies"=>"Preclinical and clinical studies", "Pharmacodynamics"=>"Pharmacokinetics and pharmacodynamics", "Behavioral"=>"Biology"}

  def self.config
    {
        name: 'iAnn Scraper',
        offline_url_mapping: {},
        root_url: 'http://iann.pro',
        path: '/solr/select/?q=*&rows=20000&start=0'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "iAnn",
          url: "http://iann.pro",
          image_url: "http://iann.pro/sites/default/files/itico_logo.png",
          description: "iAnn is a portal for enabling collaborative announcement dissemination by providing providing relevant scientific announcements data and software tools to help annotation and curation of scientific announcements.",
          content_provider_type: :portal
        }))

    docs = Nokogiri::HTML(open_url(config[:root_url] + config[:path])).xpath('//doc')

    events = []

    docs.each do |event_item|
      event = Tess::API::Event.new
      event_item.children.each do |element|
        event.content_provider = cp
        if element.text and !element.text.empty?
          #  puts element.values
          case element.values
            when ['id']
              event.external_id = element.text
            when ['link']
              event.url = element.text
            when ['public'],
                ['submission_comment'], ['submission_date'], ['submission_name'],
                ['submission_organization'], ['_version_'], ['submission_email'], ['image']
              #puts "Ignored for element type #{element.values}"
            when ['keyword']
              event.keywords = element.children.collect{|children| children.text}
            when ['category']
              categories = element.children.collect{|children| children.text}
              if categories.include?('course')
                event.event_types = [:workshops_and_courses]
              elsif categories.include?('meeting')
                event.event_types = [:meetings_and_conferences]
              end
            when ['field']
              event.scientific_topic_names = IANN_MAPPING[element.children.collect{|children| children.text}]
            when ['provider']
              event.organizer = element.text
            else
              event.send("#{element.values.first}=", element.text)
          end
        end
      end

      events << event
    end

    deduplicate_urls(events)

    events.each { |event| add_event(event) }
  end

  private

  # Adds "__<number>" to the end of duplicate URLs
  def deduplicate_urls(events)
    events.group_by(&:url).each do |url, url_events|
      if url_events.count > 1
        url_events.each_with_index do |event, i|
          unless i == 0 # The first event can keep its original URL
            event.url = url + "#__#{i}"
          end
        end
      end
    end
  end

end
