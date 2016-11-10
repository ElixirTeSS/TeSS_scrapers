require 'nokogiri'

class BitsvibEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'VIB Bioinformatics Training and Services Events Scraper',
        root_url: 'http://www.vib.be/en/training/research-training/courses/Pages/default.aspx',
        categories: %w{Bioinformatics, Skills, Science, Coaching}
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "VIB Bioinformatics Training and Services",
          url: "https://www.bits.vib.be/",
          image_url: "http://www.vib.be/VIBMediaLibrary/Logos/Service_facilities/BITS_website.jpg",
          description: "Provider of Bioinformatics and software training, plus informatics services and resource management support.",
          content_provider_type: :organisation,
          node_name: :BE
        }))

    config[:categories].each do |cat|
      url = "#{config[:root_url]}?VIBCourseCategory=#{cat}"
      puts "Opening: #{url}"
      doc = Nokogiri::HTML(open(url))
      process_html(doc)
    end
  end

  private

  def process_html(doc)
    # TODO: Come up with a means to process this which actually works
    doc.search('table > tr').each do |row|
      puts "ROW: #{row}"
    end
  end

end
