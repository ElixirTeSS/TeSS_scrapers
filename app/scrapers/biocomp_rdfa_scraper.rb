require 'nokogiri'
require 'geocoder'

class BiocompRdfaScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Biocomp RDFa Scraper',
        offline_url_mapping: {},
        root_url: 'http://biocomp.vbcf.ac.at/training/',
        materials_url: 'http://biocomp.vbcf.ac.at/training/index.html'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "VBCF BioComp",
          url: "http://biocomp.vbcf.ac.at/training/index.html",
          image_url: "http://biocomp.vbcf.ac.at/training/biocomp.jpg",
          description: "BioComp is one of the core facilities at the Vienna BioCenter Core Facilities (VBCF). We offer data analysis services for next-generation sequencing data and develop software solutions for biological experiments, with an emphasis on image and video processing and hardware control. We also provide custom-made data management solutions to research groups. BioComp offers trainings and consultations in the areas of bioinformatics, statistics and computational skills.",
          content_provider_type: Tess::API::ContentProvider::PROVIDER_TYPE[:ORGANISATION]
        }))

    get_urls(config[:materials_url]).each do |url|
      materials = Tess::Scrapers::RdfMaterialExtractor.new(open_url(url), :rdfa).extract

      materials.each do |material|
        material.url = url
        material.remote_updated_date = Time.now
        material.content_provider = cp

        add_material(material)
      end
    end
  end

  private

  def get_urls(index_page)
    doc = Nokogiri::HTML(open_url(index_page))
    urls = []
    materials = doc.css('ul > li > ul > li')
    materials.each do |material|
      links = material.search('a')
      links.each do |l|
        urls << config[:root_url] + l['href']
      end
    end

    urls
  end

end
