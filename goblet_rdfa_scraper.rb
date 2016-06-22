require 'rdf/rdfa'
require 'open-uri'
require 'nokogiri'
require 'tess_api_client'
require 'digest/sha1'

# This scraper should use the XML API to get the URL of each course, then go to each individual
# course page to parse embedded RDFa data.

$courses = 'http://www.mygoblet.org/training-portal/courses-xml'
$materials = 'http://www.mygoblet.org/training-portal/materials-xml'
$owner_org = 'goblet'
$lessons = {}
$debug = false
# Get all URLs from XML
def get_urls(page,type)
  if $debug
    urls = IO.readlines("html/goblet_#{type}.txt").collect {|x| x.chomp!}
  else
    doc = Nokogiri::XML(open(page))
    urls = []

    doc.search('nodes > node').each do |node|
      url = nil
      node.search('URL').each do |t|
        url = t.inner_text
      end
      if url
        urls << url
      end
    end
  end

  return urls
end

cp = ContentProvider.new({
                             title: "GOBLET",
                             url: "http://www.mygoblet.org",
                             image_url: "http://www.mygoblet.org/sites/default/files/logo_goblet_trans.png",
                             description: "GOBLET, the Global Organisation for Bioinformatics Learning, Education and Training, is a legally registered foundation providing a global, sustainable support and networking structure for bioinformatics educators/trainers and students/trainees.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:PORTAL]
                         })

cp = Uploader.create_or_update_content_provider(cp)

dump_file = File.open('parsed_goblet.json', 'w') if $debug

#Go through each Training Material, load RDFa, dump to JSON, interogate data, and upload to TeSS. 
get_urls($materials,'materials').each do |url|
  #f = open(url)
  if true #Load from file for now
    if File.exists?("html/goblet_pages/#{Digest::SHA1.hexdigest(url)}")
      rdfa = RDF::Graph.load("html/goblet_pages/#{Digest::SHA1.hexdigest(url)}", format: :rdfa)
      puts 'Opened from Filesystem'
    else
      File.open("html/goblet_pages/#{Digest::SHA1.hexdigest(url)}", 'w') do |file|
        file.write(open(url).read)
      end
      rdfa = RDF::Graph.load("html/goblet_pages/#{Digest::SHA1.hexdigest(url)}", format: :rdfa)
        puts 'Opened from Web'
    end
  else
    rdfa = RDF::Graph.load(url, format: :rdfa)
  end

  material = RdfaExtractor.parse_rdfa(rdfa, 'CreativeWork')
  material.each{|mat| mat['url'] = url}
  #write out to JSON for debug mode.
  if $debug
    material.each do |material|
      dump_file.write("#{material.to_json}")
    end
  end
  puts material
  material = material.first
  # Create the new record

  upload_material = Material.new({
      title: material['http://schema.org/name'],
        url: url,
        short_description: material['http://schema.org/description'],
        doi: nil,
        remote_updated_date: Time.now,
        remote_created_date: material['http://purl.org/dc/terms/date'],
        content_provider_id: cp['id'],
        scientific_topics: material['http://schema.org/genre'],
        keywords: material['http://schema.org/keywords'],
        licence: nil,
        difficulty_level: nil,
        contributors: [],
        authors: material['http://rdfs.org/sioc/ns#has_creator'],
        target_audience: material['http://schema.org/audience']
   })
   Uploader.create_or_update_material(upload_material)
end
