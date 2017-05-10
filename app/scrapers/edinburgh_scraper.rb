require 'nokogiri'

class EdinburghScraper < Tess::Scrapers::Scraper
    def self.config 
        {
            root_url: 'https://genomics.ed.ac.uk',
            index_path: '/services/training'
        }
    end

    def scrape
        cp = add_content_provider(Tess::API::ContentProvider.new({
             title: "Edinburgh Genomics", #name
             url: config[:root_url], #url
             image_url: "https://genomics.ed.ac.uk/sites/default/files/unnamed.png",
             description: "The explosion in new sequencing technologies has changed genomics from being the province of a few to being a key part in many research programmes. To enable researchers to analyse their next generation sequencing data themselves, Edinburgh Genomics offers a range of hands-on bioinformatics workshops.",
             content_provider_type: :organisation,
             node_name: :UK
        }))
        doc = Nokogiri::HTML(open_url(config[:root_url] + config[:index_path]))
        urls = doc.xpath('//*[@id="node-34"]/div/div[2]/div/div/table/tbody/tr/td[2]/a').map{|x| config[:root_url] + x.attributes['href'].value}
        urls.each do |url|
            html = open(url).read
            json = /<script type="application\/ld\+json">(.*?)<\/script>/m.match(html)
            if json 
                json = json[1].gsub('<!--//--><![CDATA[// ><!--', '')
                json = json.gsub('//--><!]]>', '')
                event = Tess::Scrapers::RdfEventExtractor.new(json, :jsonld).extract.first
                event.content_provider = cp
                event.event_types = [:workshops_and_courses]
                event.url = url
                add_event(event)
            end
        end
    end
end
