require 'rdf/rdfa'
require 'nokogiri'
require 'digest/sha1'

class ErasysRdfaScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'ERASysAPP RDFa Scraper',
        offline_url_mapping: {},
        root_url: 'http://www.sbedu.eu',
        per_page: 5
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "ERASysAPP", #name
          url: "http://www.sbedu.eu/", #url
          image_url: "http://www.sbedu.eu/images/erasysapp.PNG", #logo
          description: "A platform for the exchange of educational material on systems biology.", #description
          content_provider_type: :project
        }))

    page = 0
    materials = get_materials_for_page(page)
    while materials.count > 0
      materials.each do |material|
        # TODO: Figure out how to do this using rdf_material_extractor
        add_material(Tess::API::Material.new(
            { title: trim_characters(material['https://schema.org/name']),
              url: material['https://schema.org/url'],
              short_description: material['description'],
              remote_updated_date: Time.now,
              remote_created_date: material['https://schema.org/dateCreated'],
              content_provider: cp,
              scientific_topic_names: trim_characters(material['https://schema.org/keywords']),
              keywords: trim_characters(material['https://schema.org/keywords']),
              authors: (trim_characters(material['https://schema.org/author'].values) unless material['https://schema.org/author'].blank?)
            }))
      end
      materials = get_materials_for_page(page = page + 5)
    end
  end

  private

  def get_materials_for_page(page)
    url = "#{config[:root_url]}/index.php?start=#{page}"
    reader = RDF::Reader.for(:rdfa).new(open_url(url))
    rdfa = RDF::Graph.new << reader
    materials = Tess::Scrapers::RdfaExtractor.parse_rdfa(rdfa, 'BlogPosting')
    materials.each do |material|
      if material['https://schema.org/url']
        page = Nokogiri::HTML(open(material['https://schema.org/url']))
        desc_div = material['description'] = page.css('div.item-page p')
        unless desc_div.first.nil?
          material['description'] = desc_div.first.text 
        end
        #puts page.css('div.item-page p').first.text
      end
    end unless materials.empty?
    return materials
  end


  def trim_characters(attribute)
    if attribute.class == String
      return attribute.gsub("\\n", '').gsub("\\t", '').strip
    elsif attribute.class == Array
      return attribute.collect{|x| x.gsub("\\n", '').gsub("\\t", '').strip}
    end
  end
end
