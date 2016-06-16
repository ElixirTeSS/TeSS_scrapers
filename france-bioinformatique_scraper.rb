'http://www.france-bioinformatique.fr/en/formations'


require 'tess_api_client'
require 'linkeddata'

# This scraper should use the XML API to get the URL of each course, then go to each individual
# course page to parse embedded RDFa data.

$materials = 'http://www.france-bioinformatique.fr/en/training_material'
$events = 'http://www.france-bioinformatique.fr/en/formations'
$root_url = 'http://www.france-bioinformatique.fr/en/'
$owner_org = 'ifb'
$lessons = {}
$debug = ScraperConfig.debug?


cp = ContentProvider.new(
    "IFB French Institute of Bioinformatics",
    "http://www.france-bioinformatique.fr/en",
    "http://www.france-bioinformatique.fr/sites/default/files/ifb-logo_1.png",
    "The French Institute of Bioinformatics (referred to as IFB hereafter) is a national service infrastructure in bioinformatics that was created following the call for proposals, \“National Infrastructures in Biology and Health\”, of the \“Investments for the Future\” initiative (ANR-11-INBS-0013)."
    )
cp = Uploader.create_or_update_content_provider(cp)


dump_file = File.open('parsed_ifb.json', 'w') if $debug

#Go through each Training Material, load RDFa, dump to JSON, interogate data, and upload to TeSS. 
rdfa = RDF::Graph.load($materials, format: :rdfa)
materials = RdfaExtractor.parse_rdfa(rdfa, 'CreativeWork')
#article = RdfaExtractor.parse_rdfa(rdfa, 'Article')

=begin
rdfa = RDF::Graph.load($events, format: :rdfa)
events = RdfaExtractor.parse_rdfa(rdfa, 'Event')
=end



  #write out to JSON for debug mode.
  if $debug
    material.each do |material|
      dump_file.write("#{material.to_json}")
    end
  end

  
  # Create the new record
materials.each do |material|
	begin
		keywords = material['schema:keywords'] 
		keywords.delete('en') #Each has en meaning english in. Remove these
		upload_material = Material.new({
	          title: material['schema:name'],
	          url: material['schema:url'],
	          short_description: material['schema:about'],
	          doi: nil,
	          remote_updated_date: Time.now,
	          remote_created_date: material['dc:date'],
	          content_provider_id: cp['id'],
	          scientific_topic_names: keywords,
	          keywords: keywords, #material['schema:learningResourceType'],
	          licence: nil,
	          difficulty_level: nil,
	          contributors: [],
	          authors: material['schema:author'],
	          target_audience: material['schema:audience']
	    })
	    Uploader.create_or_update_material(upload_material)
	rescue => ex
		puts ex.message
	end
end



=begin  
  # Create the new record
events.each do |event|
	begin
		puts event
		keywords = material['schema:keywords']
		keywords.delete('en') #Each has en meaning english in. Remove these
		upload_material = Material.new({
	          title: material['schema:name'],
	          url: material['schema:url'],
	          short_description: material['schema:about'],
	          doi: nil,
	          remote_updated_date: Time.now,
	          remote_created_date: material['dc:date'],
	          content_provider_id: cp['id'],
	          scientific_topic_names: keywords,
	          keywords: keywords.uniq, #material['schema:learningResourceType'],
	          licence: nil,
	          difficulty_level: nil,
	          contributors: [],
	          authors: material['schema:author'],
	          target_audience: material['schema:audience']
	    })
	    Uploader.create_or_update_material(upload_material)

	rescue => ex
		puts ex.message
	end
end
=end

