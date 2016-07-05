
require 'rdf/rdfa'
require 'open-uri'
require 'nokogiri'
require 'tess_api_client'
require 'digest/sha1'

def get_materials_for_page(page)
    url = "http://www.sbedu.eu/index.php?start=#{page}"
    rdfa = RDF::Graph.load(url, format: :rdfa)
    materials = RdfaExtractor.parse_rdfa(rdfa, 'BlogPosting')
    materials.each do |material|
        if material['schema:url']
            page = Nokogiri::HTML(open(material['schema:url']))
            material['description'] = page.css('div.item-page p').first.text
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

cp = ContentProvider.new({
                             title: "ERASysAPP", #name
                             url: "http://www.sbedu.eu/", #url
                             image_url: "http://www.sbedu.eu/images/erasysapp.PNG", #logo
                             description: "A platform for the exchange of educational material on systems biology.", #description
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:PROJECT]
                         })

cp = Uploader.create_or_update_content_provider(cp)

page = 0
materials = get_materials_for_page(page)
while materials.count > 0 
    materials.each do |material|
      begin
        upload_material = Material.new({
              title: trim_characters(material['http://schema.org/name']),
              url: material['http://schema.org/url'],
              short_description: "No description available.",
              doi: nil,
              remote_updated_date: Time.now,
              remote_created_date: material['http://schema.org/dateCreated'],
              content_provider_id: cp['id'],
              scientific_topic: nil,
              keywords: trim_characters(material['http://schema.org/keywords']),
              licence: nil,
              difficulty_level: nil,
              contributors: [],
              authors: trim_characters(material['http://schema.org/author']),
              target_audience: nil
         })
        Uploader.create_or_update_material(upload_material)
        rescue => ex
          puts ex.message
       end
    end
    materials = get_materials_for_page(page = page + 5)
end




=begin
m.each do |material| 
  #puts material['schema:name']
  puts material['schema:author'].collect{|x| trim_characters x} unless material['schema:author'].nil?
  puts material['schema:dateCreated']
  material['schema:keywords'].collect{|x| puts trim_characters x} unless material['schema:keywords'].nil?
  puts trim_characters material['schema:name']
  puts material['schema:url']
end
=end


