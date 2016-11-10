require 'nokogiri'

class IfbRdfaScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'IFB RDFa Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.france-bioinformatique.fr',
        events_path: '/en/formations',
        materials_path: '/en/training_material',
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "IFB French Institute of Bioinformatics",
          url: "http://www.france-bioinformatique.fr/en",
          image_url: "https://www.france-bioinformatique.fr/sites/default/files/ifb-logo_1.png",
          description: "The French Institute of Bioinformatics (CNRS IFB) is a national service infrastructure in bioinformatics. IFB’s principal mission is to provide basic services and resources in bioinformatics for scientists and engineers working in the life sciences. IFB is the French node of the European research infrastructure, ELIXIR.",
          content_provider_type: :organisation,
          node_name: :FR,
          keywords: ['bioinformatics', 'infrastructure', 'Big Data', 'NGS']
        }))

    reader = RDF::Reader.for(:rdfa).new(open_url(config[:root_url] + config[:materials_path]))
    rdfa = RDF::Graph.new << reader
    materials = Tess::Scrapers::RdfaExtractor.parse_rdfa(rdfa, 'CreativeWork')

    # TODO: Use RDFMaterialExtractor here
    materials.each do |data|
      keywords = [data['schema:keywords']].flatten
      keywords.delete('en') #Each has en meaning english in. Remove these
      authors = [data['schema:author']].flatten
      authors.delete('en')
      material = Tess::API::Material.new(
          { title: data['schema:name'],
            url: config[:root_url] + data['@id'],
            short_description: data['schema:about'],
            remote_updated_date: Time.now,
            remote_created_date: data['schema:dateCreated'],
            content_provider: cp,
            keywords: keywords, #material['schema:learningResourceType'],
            authors: authors,
            target_audience: [data['schema:audience']].flatten
          })

      material.licence = 'CECILL-2.1' if data['schema:License'] == 'CeCILL'

      add_material(material)
    end
  end
end
