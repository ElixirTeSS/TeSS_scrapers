require 'nokogiri'

class EdinburghScraper < Tess::Scrapers::Scraper

  def scrape
		html = open('http://genomics.ed.ac.uk/services/gatk-best-practices-variant-discovery').read
		json = /<script type="application\/ld\+json">(.*)<\/script>/m.match(html)
		puts json.inspect
		#json = json.gsub('<!--//--><![CDATA[// ><!--', '')
		#json = json.gsub('//--><!]]>', '')
		events = Tess::Scrapers::RdfEventExtractor.new(json, :jsonld).extract
		puts events
	end
end
