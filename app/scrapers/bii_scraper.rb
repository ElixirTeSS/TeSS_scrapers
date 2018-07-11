class BiiScraper < Tess::Scrapers::Scraper

  TAXONOMY_TEMPLATE = "/taxonomy/term/%i%_format=json"
  PAGE_TEMPLATE = "/node/%i%?_format=json"

  def self.config
    {
        name: 'BISE Scraper',
        offline_url_mapping: {},
        root_url: 'http://test.biii.eu',
        materials_path: '/training?_format=json'
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "BISE",
          url: "http://bii.eu",
          image_url: "http://eubias.org/NEUBIAS/wp-content/uploads/2018/04/Webbanner_logosNEUBIAS-COST-sm.jpg",
          description: "Many tools for Bio Image Analysis are already available but information about these tools is non-uniform and often focuses on technicalities about the methods implemented rather than the problems the tools can actually solve. Since bio image analysts focus on applied problems, this information is often inadequate. To overcome this issue, the platform BISE developed by the Network of European Bio-image Analyst NEUBIAS  try to match the problem with the relevant tools.",
          content_provider_type: :organisation
        }))

    get_content.each do |material|
        #material = material.first
        material = extract_content(material)
        begin
            puts material[:url] unless add_material(Tess::API::Material.new(material.merge({content_provider: cp})))
        rescue => e
          puts material
        end
    end


  end

  private

  def extract_content material
    extract = {}
    extract[:title] = material['title'].first['value'] if material['title'].any? && material['title'].first.has_key?('value')
    extract[:url] = material['field_url'].first['uri'] if material['field_url'].any? && material['field_url'].first.has_key?('uri')
    extract[:short_description] = material['body'].first['value'] if material['body'].any? && material['body'].first.has_key?('value')
    extract[:authors] = material['field_author_s_'].collect{|y| y['value']} if  material['field_author_s_'].any? && material['field_author_s_'].first.has_key?('value')
    #extract[:scientific_topic_names] =
    #extract[:keywords] =
    extract[:license] = material['field_has_license']
    return extract
  end



  def get_content()
    #{config[:root_url]}#{config[:materials_path]}
    ids = JSON.load(open("#{config[:root_url]}#{config[:materials_path]}"))
    return ids.collect{|x| JSON.load(open( PAGE_TEMPLATE.gsub('%i%', x['nid']) ) ) }
  end
end

=begin
require 'open-uri'
require 'json'

def self.config
    {
        name: 'BISE Scraper',
        offline_url_mapping: {},
        root_url: 'http://test.biii.eu',
        materials_path: '/training?_format=json'
    }
  end
  a = JSON.load(open "#{config[:root_url]}#{config[:materials_path]}").collect{|x| JSON.load(open("#{config[:root_url]}/node/#{x['nid']}?_format=json"))}
  a.select!{|x| x.has_key?('field_url') && x['field_url'].any? && x['field_url'].first.has_key?('uri')}


=end