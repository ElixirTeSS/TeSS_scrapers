require 'nokogiri'

class IfbEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'IFB RDFa Scraper',
        root_url: 'https://www.france-bioinformatique.fr',
        events_path: '/en/evenements_upcoming',
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

    #doc = Nokogiri::HTML(open_url(config[:root_url] + config[:events_path]))
    doc = Nokogiri::HTML(open('/Users/milo/Work/Web/TeSS_scrapers/html/ifb_events/index.html'))
    event_block = doc.css('div.event_block')

    event_block.each do |e|
      e.children.each do |c|
        puts c.attributes.inspect
        puts "--"
      end
      puts "--- ---"
    end


  end


end