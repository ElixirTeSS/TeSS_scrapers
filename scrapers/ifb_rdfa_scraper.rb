require 'tess_api_client'
require 'linkeddata'

# This scraper should use the XML API to get the URL of each course, then go to each individual
# course page to parse embedded RDFa data.

require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
$materials = 'http://www.france-bioinformatique.fr/en/training_material'
$events = 'http://www.france-bioinformatique.fr/en/formations'
$root_url = 'http://www.france-bioinformatique.fr/en/'
$owner_org = 'ifb'
$lessons = {}
$debug = ScraperConfig.debug?

cp = ContentProvider.new({
                             title: "IFB French Institute of Bioinformatics",
                             url: "http://www.france-bioinformatique.fr/en",
                             image_url: "http://www.france-bioinformatique.fr/sites/default/files/ifb-logo_1.png",
                             description: "The French Institute of Bioinformatics (CNRS IFB) is a national service infrastructure in bioinformatics. IFB’s principal mission is to provide basic services and resources in bioinformatics for scientists and engineers working in the life sciences. IFB is the French node of the European research infrastructure, ELIXIR.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION],
                             node: Node::NODE_NAMES[:FR],
                             keywords: ['bioinformatics', 'infrastructure', 'Big Data', 'NGS']
                         })

cp = Uploader.create_or_update_content_provider(cp)

dump_file = File.open('parsed_ifb.json', 'w') if $debug

#Go through each Training Material, load RDFa, dump to JSON, interogate data, and upload to TeSS. 
rdfa = RDF::Graph.load($materials, format: :rdfa)
materials = RdfaExtractor.parse_rdfa(rdfa, 'CreativeWork')
#article = RdfaExtractor.parse_rdfa(rdfa, 'Article')


#write out to JSON for debug mode.
if $debug
    materials.each do |material|
        dump_file.write("#{material.to_json}")
    end
end

  
  # Create the new record
materials.each do |material|
    begin
        keywords = [material['schema:keywords']].flatten
        keywords.delete('en') #Each has en meaning english in. Remove these
        authors = [material['schema:author']].flatten
        licence = material['schema:License'] == 'CeCILL' ? 'CECILL-2.1' : nil
        authors.delete('en')
        upload_material = Material.new({
              title: material['schema:name'],
              url: material['@id'],
              short_description: material['schema:about'],
              remote_updated_date: Time.now,
              remote_created_date: material['schema:dateCreated'],
              content_provider_id: cp['id'],
              keywords: keywords, #material['schema:learningResourceType'],
              licence: licence,
              authors: authors,
              target_audience: [material['schema:audience']].flatten
        })
        print "MATERIAL: #{upload_material.inspect}" if $debug
        Uploader.create_or_update_material(upload_material)
    rescue => ex
        puts ex.message
    end
end



=begin  
rdfa = RDF::Graph.load($events, format: :rdfa)
events = RdfaExtractor.parse_rdfa(rdfa, 'Event')
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

