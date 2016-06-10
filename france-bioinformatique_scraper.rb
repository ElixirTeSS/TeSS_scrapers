'http://www.france-bioinformatique.fr/en/formations'


require 'tess_api_client'

# This scraper should use the XML API to get the URL of each course, then go to each individual
# course page to parse embedded RDFa data.

$materials = 'http://www.france-bioinformatique.fr/en/training_material'
$events = 'http://www.france-bioinformatique.fr/en/formations'
$root_url = 'http://www.france-bioinformatique.fr/en/'
$owner_org = 'ifb'
$lessons = {}
$debug = ScraperConfig.debug?

# Get all URLs from XML
def get_urls(index_page)

  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("biocomp.html")
      doc = Nokogiri::HTML(f)
      f.close
    rescue
      puts "Failed to open biocomp.html file."
    end
  else
    puts "Opening: #{index_page}"
    doc = Nokogiri::HTML(open(index_page))
  end

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

cp = ContentProvider.new(
    "IFB French Institute of Bioinformatics",
    "http://www.france-bioinformatique.fr/en",
    "http://www.france-bioinformatique.fr/sites/default/files/ifb-logo_1.png",
    "The French Institute of Bioinformatics (referred to as IFB hereafter) is a national service infrastructure in bioinformatics that was created following the call for proposals, “National Infrastructures in Biology and Health”, of the “Investments for the Future” initiative (ANR-11-INBS-0013)."
    )
cp = Uploader.create_or_update_content_provider(cp)


dump_file = File.open('parsed_ifb.json', 'w') if $debug

#Go through each Training Material, load RDFa, dump to JSON, interogate data, and upload to TeSS. 
  rdfa = RDF::Graph.load($materials, format: :microdata)
  material = RdfaExtractor.parse_rdfa(rdfa, 'CreativeWork')
  #article = RdfaExtractor.parse_rdfa(rdfa, 'Article')

  material.each do |mat| 
    begin
    	if url_xml = Nokogiri::XML(mat['schema:url'][2]).element_children.first
          mat['url'] = url_xml.attributes['href'] || nil 
        end
    end
  end



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
          title: material['schema:name'],
          url: url,
          short_description: material['schema:description'],
          doi: nil,
          remote_updated_date: Time.now,
          remote_created_date: material['dc:date'],
          content_provider_id: cp['id'],
          scientific_topic_names: [], #material['schema:genre'],
          keywords: [], #material['schema:learningResourceType'],
          licence: nil,
          difficulty_level: nil,
          contributors: [],
          authors: material['schema:author'].uniq,
          target_audience: material['schema:audience']
     })
    Uploader.create_or_update_material(upload_material)
    rescue => ex
      puts ex.message
   end
end

