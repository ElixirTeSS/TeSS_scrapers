require 'nokogiri'

class IfbRdfaScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'IFB RDFa Scraper',
        offline_url_mapping: {},
        root_url: 'https://www.france-bioinformatique.fr',
        events_path: '/en/evenements_upcoming',
        past_events_path: '/en/evenements_previous',
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

    materials = Tess::Rdf::MaterialExtractor.new(
        open_url(config[:root_url] + config[:materials_path]), :rdfa).extract { |p| Tess::API::Material.new(p) }

    materials.each do |material|
      material.content_provider = cp
      material.licence = 'CECILL-2.1' if material.licence == 'http://www.cecill.info/index.en.html' || material.licence == 'http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html'
      material.licence = material.licence.gsub('http://', 'https://') if material.licence && material.licence.start_with?('http://creativecommons.org/')

      add_material(material)
    end

    [config[:events_path], config[:past_events_path]].each do |path|
      events = Tess::Rdf::EventExtractor.new(
          open_url(config[:root_url] + path).read, :rdfa).extract { |p| Tess::API::Event.new(p) }

      events.each do |event|
        event.content_provider = cp

        add_event(event)
      end
    end
  end
end
