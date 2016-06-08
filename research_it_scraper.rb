# https://github.com/ElixirUK/TeSS/issues/163

require 'open-uri'
require 'nokogiri'
require 'tess_api_client'


$root_url = 'https://www.ucl.ac.uk/isd/services/research-it/training'
$owner_org = 'research-it'
$lessons = {}
$debug = false #ScraperConfig.debug?


# Do the parsing...
def parse_data(page)
  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("html/research-it.html")
      doc = Nokogiri::HTML(f)
      f.close
    rescue
      puts "Failed to open research-it.html file."
    end
  else
    puts "Opening: #{page}"
    doc = Nokogiri::HTML(open(page))
  end

  doc.xpath('//h3/a').each do |record|
    url = record['href']
    name = record.content
    $lessons[url] = {}
    $lessons[url]['name'] = name
    page = Nokogiri::HTML(open(url))
    desc = page.xpath('//p')[1].content
    if desc == ''
      $lessons[url]['short_description'] = 'No description available at this time.'
    else
      $lessons[url]['short_description'] = desc
    end
  end

end



# Actually run the code here...
parse_data($root_url)


# Update the records...
cp = ContentProvider.new(
    "Research IT Training",
    "http://www.ucl.ac.uk",
    "https://www.ucl.ac.uk/cpc/wp-content/uploads/ucl-logo.jpg",
    "The Research IT Services (RITS) department develops, delivers and operates services to assist UCL researchers in meeting their objectives at each stage of the research lifecycle. These pages are here to help UCL researchers and other users to take full advantage of our services and include comprehensive user guides, contact information for support queries, and details about forthcoming training and events."
)
cp = Uploader.create_or_update_content_provider(cp)




# Create the new record
$lessons.each_key do |key|
  material = Material.new({title: $lessons[key]['name'],
                          url: key,
                          short_description: $lessons[key]['short_description'],
                          doi: nil,
                          remote_updated_date: Time.now,
                          remote_created_date: nil,
                          content_provider_id: cp['id'],
                          scientific_topic: [],
                          keywords:[]})

  Uploader.create_or_update_material(material)
end