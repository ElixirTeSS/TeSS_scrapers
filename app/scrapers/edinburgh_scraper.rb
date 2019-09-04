require 'nokogiri'

class EdinburghScraper < Tess::Scrapers::Scraper
    def self.config 
        {
            name: 'Edinburgh genomics scraper',
            root_url: 'https://genomics.ed.ac.uk',
            index_path: '/services/training',
            root_regex: /https?:\/\/genomics\.ed\.ac\.uk/
        }
    end

    def scrape
        cp = add_content_provider(Tess::API::ContentProvider.new({
             title: "Edinburgh Genomics", #name
             url: config[:root_url], #url
             image_url: "https://genomics.ed.ac.uk/sites/default/files/unnamed.png",
             description: "The explosion in new sequencing technologies has changed genomics from being the province of a few to being a key part in many research programmes. To enable researchers to analyse their next generation sequencing data themselves, Edinburgh Genomics offers a range of hands-on bioinformatics workshops.",
             content_provider_type: :organisation,
             node_name: :UK,
             keywords: ["HDRUK"]
        }))
        doc = Nokogiri::HTML(open(config[:root_url] + config[:index_path]).read)
        urls = doc.xpath('//*[@id="node-34"]/div/div[2]/div/div/table/tbody/tr/td[2]/a').map do |x|
            config[:root_url] + x.attributes['href'].value.gsub(config[:root_regex], '')
        end
        urls.each do |url|
            page = open_url(url)
            next unless page
            html = page.read
            json = /<script type="application\/ld\+json">(.*?)<\/script>/m.match(html)
            if json 
                #Clean up - remove CDATA and <br /> that trip up parser
                json = json[1].gsub('<!--//--><![CDATA[// ><!--', '')
                json = json.gsub('//--><!]]>', '')
                json = json.gsub('<br />', '')
                event = Tess::Rdf::EventExtractor.new(json, :jsonld).extract { |p| Tess::API::Event.new(p) }.first
                event.content_provider = cp
                event.event_types = [:workshops_and_courses]
                event.url = url
                event.keywords = ["HDRUK"]
                add_event(event)
            end
        end
    end
end
