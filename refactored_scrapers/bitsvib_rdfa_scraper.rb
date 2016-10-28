#!/usr/bin/env ruby

require_relative '../tess_scraper.rb'
require 'rdf/rdfa'
require 'nokogiri'

class BitsvibRdfaScraper < TessScraper

  def self.config
    {
        name: 'VIB Bioinformatics Training and Services RDFa Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.bits.vib.be',
        materials_url: 'https://www.bits.vib.be/training-list'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "VIB Bioinformatics Training and Services",
          url: "https://www.bits.vib.be/",
          image_url: "http://www.vib.be/VIBMediaLibrary/Logos/Service_facilities/BITS_website.jpg",
          description: "Provider of Bioinformatics and software training, plus informatics services and resource management support.",
          content_provider_type: Tess::API::ContentProvider::PROVIDER_TYPE[:ORGANISATION],
          node: Tess::API::Node::NODE_NAMES[:BE]
        }))

    get_urls(config[:materials_url]).each do |url|
      materials = RdfMaterialExtractor.new(open_url(url), :rdfa).extract

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
    # <div class="moduletable-collapsible">
    # List of all materials
    urls = []
    first = doc.css('div.moduletable')
    first.each do |f|
      links = f.search('a')
      links.each do |l|
        urls << config[:root_url] + l['href']
      end
    end

    urls
  end
end
