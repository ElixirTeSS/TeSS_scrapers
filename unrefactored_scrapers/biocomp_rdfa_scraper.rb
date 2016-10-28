require 'tess_api_client'
require_relative '../rdfa_extractor.rb'

# This scraper should use the XML API to get the URL of each course, then go to each individual
# course page to parse embedded RDFa data.

#$courses = 'http://www.mygoblet.org/training-portal/courses-xml'
$materials = 'http://biocomp.vbcf.ac.at/training/index.html'
$root_url = 'http://biocomp.vbcf.ac.at/training/'
$owner_org = 'biocomp'
$lessons = {}
$debug = ScraperConfig.debug?

# Get all URLs from XML
def get_urls(index_page)
  puts "Opening: #{index_page}"
  doc = Nokogiri::HTML(open(index_page))
  # <div class="moduletable-collapsible">
  # List of all materials
  urls = []
  materials = doc.css('ul > li > ul > li')
  materials.each do |material|
    links = material.search('a')
    links.each do |l|
      urls << $root_url + l['href']
    end
  end
  return urls
end
get_urls($materials)

cp = ContentProvider.new({
                             title: "VBCF BioComp",
                             url: "http://biocomp.vbcf.ac.at/training/index.html",
                             image_url: "http://biocomp.vbcf.ac.at/training/biocomp.jpg",
                             description: "BioComp is one of the core facilities at the Vienna BioCenter Core Facilities (VBCF). We offer data analysis services for next-generation sequencing data and develop software solutions for biological experiments, with an emphasis on image and video processing and hardware control. We also provide custom-made data management solutions to research groups. BioComp offers trainings and consultations in the areas of bioinformatics, statistics and computational skills.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION]
                         })
cp = Uploader.create_or_update_content_provider(cp)


dump_file = File.open('parsed_biocomp.json', 'w') if $debug

#Go through each Training Material, load RDFa, dump to JSON, interogate data, and upload to TeSS. 
get_urls($materials).each do |url|
  #f = open(url)
  if $debug #Load from file for now
    if File.exists?("html/biocomp_pages/#{Digest::SHA1.hexdigest(url)}")
      rdfa = RDF::Graph.load("html/biocomp_pages/#{Digest::SHA1.hexdigest(url)}", format: :rdfa)
      puts 'Opened from Filesystem'
    else
      File.open("html/biocomp_pages/#{Digest::SHA1.hexdigest(url)}", 'w') do |file|
        file.write(open(url).read)
      end
      rdfa = RDF::Graph.load("html/biocomp_pages/#{Digest::SHA1.hexdigest(url)}", format: :rdfa)
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
    upload_material = Material.new({
                                       title: material['http://schema.org/name'],
                                       url: url,
                                       short_description: material['http://schema.org/description'],
                                       remote_updated_date: Time.now,
                                       remote_created_date: material['dc:date'],
                                       content_provider_id: cp['id'],
                                       authors: material[''],
                                       target_audience: material['http://schema.org/audience']
                                   })
    Uploader.create_or_update_material(upload_material)
  rescue => ex
    puts ex.message
  end
end
