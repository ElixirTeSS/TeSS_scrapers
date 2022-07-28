require 'nokogiri'
require 'htmlentities'


class LuxembourgRdfaScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Luxembourg Scraper',
        event_content: 'https://elixir-luxembourg.org/events'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "ELIXIR Luxembourg", #name
          url: "https://elixir-luxembourg.org/", #url
          image_url: "https://tess.oerc.ox.ac.uk/system/content_providers/images/000/000/048/original/Elixir_LU_logo_big.png?1569603039",
          description: "ELIXIR-LU, the Luxembourgish node of ELIXIR, the European infrastructure for life science information, focuses on long-term sustainability of tools and data for Translational Medicine.
          Translational Medicine data integrate clinical information with molecular and cellular data for a better understanding of diseases. They bridge the gap between the molecular level, findings from the laboratory, and the clinical observations and applications. 
          ELIXIR-LU aims to facilitate long-term access to those research data and to tools for scientists in both academia and industry. This will allow the reuse of previously generated translational data to address new research questions and dramatically save time and cost. To provide solutions ELIXIR-LU is establishing services that align with three ELIXIR platforms as shown below.", #description
          content_provider_type: :organisation,
          node_name: :LU
        }))
    
    events = Tess::Rdf::EventExtractor.new(open_url(config[:event_content]), :rdfa).extract { |p| Tess::API::Event.new(p) }
    
    events.each do |event|
      event.content_provider = cp
      add_event(event)
    end
  end
end
