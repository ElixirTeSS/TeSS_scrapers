#!/usr/bin/env ruby

require_relative '../tess_scraper.rb'
require_relative '../rdfa_extractor.rb'
require 'nokogiri'
require 'geocoder'

class BiocompRdfaScraper < TessScraper

  def self.config
    {
        name: 'Biocomp RDFa Scraper',
        offline_url_mapping: {},
        root_url: 'http://biocomp.vbcf.ac.at/training/',
        materials_url: 'http://biocomp.vbcf.ac.at/training/index.html'
    }
  end

  def get_urls(index_page)
    doc = Nokogiri::HTML(open_url(index_page))
    # <div class="moduletable-collapsible">
    # List of all materials
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

  def scrape
    #$courses = 'http://www.mygoblet.org/training-portal/courses-xml'

    cp = add_content_provider(
        { title: "VBCF BioComp",
          url: "http://biocomp.vbcf.ac.at/training/index.html",
          image_url: "http://biocomp.vbcf.ac.at/training/biocomp.jpg",
          description: "BioComp is one of the core facilities at the Vienna BioCenter Core Facilities (VBCF). We offer data analysis services for next-generation sequencing data and develop software solutions for biological experiments, with an emphasis on image and video processing and hardware control. We also provide custom-made data management solutions to research groups. BioComp offers trainings and consultations in the areas of bioinformatics, statistics and computational skills.",
          content_provider_type: Tess::API::ContentProvider::PROVIDER_TYPE[:ORGANISATION]
        })

    dump_file = File.open(cache_file_path('parsed_biocomp.json', true), 'w') if @debug

    #Go through each Training Material, load RDFa, dump to JSON, interogate data, and upload to TeSS.
    get_urls(config[:materials_url]).each do |url|
      rdfa = RDF::Reader.for(:rdfa).new(open_url(url))

      material = RdfaExtractor.parse_rdfa(rdfa, 'CreativeWork')
      #article = RdfaExtractor.parse_rdfa(rdfa, 'Article')
      material.each{|mat| mat['url'] = url}

      #write out to JSON for debug mode.
      if @debug
        material.each do |material|
          dump_file.write("#{material.to_json}")
        end
      end

      material = material.first

      # Create the new record
      begin
        add_material(
            { title: material['http://schema.org/name'].strip,
              url: url,
              short_description: material['http://schema.org/description'].strip,
              remote_updated_date: Time.now,
              remote_created_date: material['dc:date'],
              content_provider: cp,
              authors: material[''],
              target_audience: material['http://schema.org/audience']
            })
      rescue => ex
        puts ex.message
      end
    end
  end

end
