# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api_client'
require 'nokogiri'

IANN_MAPPING =  {"Systemsbiology"=>"Systems biology", "Systems Biology"=>"Systems biology", "Genomics"=>"Genomics", "Bioinformatics"=>"Bioinformatics", "Computationalbiology"=>"Computational biology", "Metagenomics"=>"Metagenomics", "Computerscience"=>"Computer science", "Proteomics"=>"Proteomics", "Dataanalysis"=>"Data architecture, analysis and design", "RNA-Seq"=>"RNA-Seq", "Immunology"=>"Immunology", "Medicine"=>"Medicine", "Datavisualisation"=>"Data visualisation", "Medicalimaging"=>"Medical imaging", "Geneexpression"=>"Gene expression", "Geneexpressionandmicroarray"=>"Gene expression", "High-throughputsequencing"=>"Sequencing", "Pharmacology"=>"Pharmacology", "Biology"=>"Biology", "Pathology"=>"Pathology", "Medicalinformatics"=>"Medical informatics", "ChIP-seq"=>"ChIP-seq", "Computationalchemistry"=>"Computational chemistry", "Computerprogramming"=>"Software engineering", "Biomedicalscience"=>"Biomedical science", "Datamanagement"=>"Data management", "Datadeposition"=>"Data submission, annotation and curation", "annotationandcuration"=>"Data submission, annotation and curation", "Moleculardynamics"=>"Molecular dynamics", "Molecularmodelling"=>"Molecular modelling", "Biochemistry"=>"Biochemistry", "DNAmethylation"=>"Epigenetics", "Epigenetics"=>"Epigenetics", "Datasearch"=>"Data management", "queryandretrieval"=>"Data management", "Tooltopic"=>"Data management", "Metabolomics"=>"Metabolomics", "Datamining"=>"Data mining", "Microbiology"=>"Microbiology", "Ecology"=>"Ecology", "Evolutionarybiology"=>"Evolutionary biology", "Theoreticalbiology"=>"Computational biology", "Epigenomics"=>"Epigenomics", "Transcriptomics"=>"Transcriptomics", "Physiology"=>"Physiology", "Anaesthesiology"=>"Anaesthesiology", "Humans"=>"Humans", "Biotherapeutics"=>"Drug formulation and delivery", "Biostatistics"=>"Statistics and probability", "Epidemiology"=>"Public health and epidemiology", "ResearchPathology"=>"Preclinical and clinical studies", "Clinical Studies"=>"Preclinical and clinical studies", "Pharmacodynamics"=>"Pharmacokinetics and pharmacodynamics", "Behavioral"=>"Biology"} 

$debug = ScraperConfig.debug?

cp = ContentProvider.new({
                             title: "iAnn",
                             url: "http://iann.pro",
                             image_url: "http://iann.pro/sites/default/files/itico_logo.png",
                             description: "iAnn is a portal for enabling collaborative announcement dissemination by providing providing relevant scientific announcements data and software tools to help annotation and curation of scientific announcements.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:PORTAL]
                         })

cp = Uploader.create_or_update_content_provider(cp)

iann_dir = 'iann'
Dir.mkdir(iann_dir) unless Dir.exists?(iann_dir) 
iann_file = iann_dir + '/iann_events_' +Time.now.strftime("%Y%m%d.txt")

if File.exists?(iann_file)
  iann_content = File.open(iann_file).read
  puts "Already have a copy of todays iAnn events so loaded from file: '#{iann_file}'."
else
  iann_content = Net::HTTP.get('iann.pro', '/solr/select/?q=*&rows=20000&start=0')
  File.write(iann_file, iann_content)
  puts "Retrieved new iAnn dump for today. Saved in file #{File.absolute_path(iann_file)}."
end


docs = Nokogiri::HTML(iann_content).xpath('//doc')

docs.each do |event_item|
  event = Event.new
  event_item.children.each do |element|
    event.content_provider_id = cp['id']
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
            event.event_types = [Event::EVENT_TYPE[:workshops_and_courses]]
          elsif categories.include?('meeting')
            event.event_types = [Event::EVENT_TYPE[:meetings_and_conferences]]
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
  #puts event.inspect if ScraperConfig.debug?
  Uploader.create_or_update_event(event)
end



