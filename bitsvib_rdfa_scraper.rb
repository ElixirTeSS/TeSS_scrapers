require 'rdf/rdfa'
require 'open-uri'
require 'nokogiri'
require 'tess_api_client'
require 'digest/sha1'

# This scraper should use the XML API to get the URL of each course, then go to each individual
# course page to parse embedded RDFa data.

#$courses = 'http://www.mygoblet.org/training-portal/courses-xml'
$materials = 'https://www.bits.vib.be/training'
$root_url = 'https://www.bits.vib.be'
$owner_org = 'bitsvib'
$lessons = {}
$debug = false

# Get all URLs from XML
def get_urls(index_page)

  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("bitsvib.html")
      doc = Nokogiri::HTML(f)
      f.close
    rescue
      puts "Failed to open bitsvib.html file."
    end
  else
    puts "Opening: #{index_page}"
    doc = Nokogiri::HTML(open(index_page))
  end

  # <div class="moduletable-collapsible">
  # List of all materials
  urls = []
  first = doc.css('div.moduletable-collapsible')
  first.each do |f|
    links = f.search('a')
    links.each do |l|
      urls << $root_url + l['href']
    end
  end
  return urls
end

cp = ContentProvider.new(
    "VIB Bioinformatics Training and Services",
    "https://www.bits.vib.be/index.php/training",
    "http://www.vib.be/VIBMediaLibrary/Logos/Service_facilities/BITS_website.jpg",
    "Belgian provider of Bioinformatics and Software Training, plus informatics services and resource management support."
    )
cp = Uploader.create_or_update_content_provider(cp)


dump_file = File.open('parsed_bitsvib.json', 'w') if $debug

#Go through each Training Material, load RDFa, dump to JSON, interogate data, and upload to TeSS. 
get_urls($materials).each do |url|
  #f = open(url)
  if true #Load from file for now
    if File.exists?("html/bitsvib_pages/#{Digest::SHA1.hexdigest(url)}")
      rdfa = RDF::Graph.load("html/bitsvib_pages/#{Digest::SHA1.hexdigest(url)}", format: :rdfa)
      puts 'Opened from Filesystem'
    else
      File.open("html/bitsvib_pages/#{Digest::SHA1.hexdigest(url)}", 'w') do |file|
        file.write(open(url).read)
      end
      rdfa = RDF::Graph.load("html/bitsvib_pages/#{Digest::SHA1.hexdigest(url)}", format: :rdfa)
        puts 'Opened from Web'
    end
  else
    rdfa = RDF::Graph.load(url, format: :rdfa)
  end


  material = RdfaExtractor.parse_rdfa(rdfa, 'CreativeWork')
  #article = RdfaExtractor.parse_rdfa(rdfa, 'Article')
  material.each{|mat| mat['url'] = url}


  #write out to JSON for debug mode.
  if $debug
    material.each do |material|
      dump_file.write("#{material.to_json}")
    end
  end

  material = material.first
  # Create the new record
  begin
    upload_material = Material.new(
        title = material['schema:name'],
          url = url,
          short_description = material['schema:description'],
          doi = nil,
          remote_updated_date = Time.now,
          remote_created_date = material['dc:date'],
          content_provider_id = cp['id'],
          scientific_topic = material['schema:genre'],
          keywords = material['schema:keywords'],
          licence = nil,
          difficulty_level = nil,
          contributors = [],
          authors = material['sioc:has_creator'],
          target_audience = material['schema:audience']
      ) 
    Uploader.create_or_update_material(upload_material)
    rescue => ex
      puts ex.message
   end
end
