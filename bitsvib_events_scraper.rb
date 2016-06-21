#!/usr/bin/env ruby
require 'tess_api_client'

$root_url = 'http://www.vib.be/en/training/research-training/courses/Pages/default.aspx'
$owner_org = 'bioinformatics-training-and-services'
$events = {}
$categories = %w{Bioinformatics, Skills, Science, Coaching}
$debug = ScraperConfig.debug?

cp = ContentProvider.new({
                             title: "VIB Bioinformatics Training and Services",
                             url: "https://www.bits.vib.be/",
                             image_url: "http://www.vib.be/VIBMediaLibrary/Logos/Service_facilities/BITS_website.jpg",
                             description: "Provider of Bioinformatics and software training, plus informatics services and resource management support.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION],
                             node: Node::NODE_NAMES[:BE]
                         })

cp = Uploader.create_or_update_content_provider(cp)


def parse_data()
  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("bitsvib_events.html")
      doc = Nokogiri::HTML(f)
      f.close
      process_html(doc)
    rescue
      puts "Failed to open bitsvib_events.html file."
    end
  else
    $categories.each do |cat|
      url = "#{$root_url}?VIBCourseCategory=#{cat}"
      puts "Opening: #{url}"
      doc = Nokogiri::HTML(open(url))
      process_html(doc)
    end
  end
end

def process_html(doc)
  # TODO: Come up with a means to process this which actually works
  doc.search('table > tr').each do |row|
    puts "ROW: #{row}"
  end

end