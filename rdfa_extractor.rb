require 'json/ld'
require 'nokogiri'
require 'rdf/rdfa'

class RdfaExtractor
  #Given an RDF:RDFa::Reader and a schema.org Type
  # returns a hash containing all the available fields and values of the given schema (e.g. CreativeWork AggregateRating Person)
  #e.g. parse_rdfa(rdfa, 'CreativeWork')

  def self.parse_rdfa(rdfa, type='CreativeWork')

    json_graph = JSON.load(rdfa.dump(:jsonld, standard_prefixes: true))["@graph"]

    #  json_graph looks like this.
    #  {
    #      :@context => {<some stuff>},
    #      :@graph => [
    #      {
    #        "@id" => /audience-tags/beginner-bioinformaticians
    #        "@type" => "skos:Concept"
    #        "rdfs:label" => {
    #          "@value"=>"beginner bioinformaticians",
    #          "@language"=>"en"
    #        }
    #        skos:prefLabel" => {
    #          "@value"=>"beginner bioinformaticians",
    #          "@language"=>"en"
    #        }
    #      },
    #      {
    #        "@id"=>"/users/gabriella-rustici",
    #        "@type"=>["schema:Person", "sioc:UserAccount"],
    #        schema:name"=>"Gabriella Rustici"
    #      }
    #      ]
    #  }

    # The array item(s) in graph with the given type (e.g. "CreativeWork") is the root node.
    # This contains pointers to all of the properties the schema instance has.
    # Find this root node to start:
    if !json_graph.nil?
      objects = json_graph.select do |node|
        if node["@type"]
          node["@type"].include?("schema:#{type}") or node["@type"].include?("https://schema.org/#{type}") or node["@type"].include?("http://schema.org/#{type}")
        end
      end

      #root.keys gets the list of all the properties for this schema. For example a CreativeWork will return =>
      #["@id", "@type", "dc:created", "dc:date", "rss:modules/content/encoded", "schema:audience",
      # "schema:description", "schema:genre", "schema:hasPart", "schema:keywords", "schema:name", "schema:url",
      # "sioc:has_creator", "sioc:num_replies"]

      results_collection = []
      objects.each do |object|
        # Toss aside the @type and @id - we don't need them for now
        attributes = object.keys - ["@type"]
        # Go through the list of properties contained in the schema instance and extract each value to put into our return hash.
        # In most cases these contain an ID which we need to use the original json_graph object to lookup the value of.
        # (see ==Array and has_key?(@id) cases below)
        parsed_object = {}
        attributes.each do |attribute|
          parsed_object[attribute] = extract_attribute_value(object[attribute], json_graph)
        end
        results_collection << parsed_object
      end
      # res now contains a hash with all our property values.
      return results_collection
    else
      return []
    end
  end

  def self.extract_attribute_value(attribute, json_graph)
    if !attribute
      return nil
    elsif attribute.class == String
      return attribute
    elsif attribute.class == Array #e.g. root_node['schema:genre'] => [{"@id"=>"/edam-topic/bioinformatics"}, {"@id"=>"/edam-topic/data-analysis"}]
      properties = []
      attribute.each do |value|
        if value.class == Hash
          if value.has_key?("@id") #e.g. node => [{"@id"=>"/users/gabriella-rustici"}]
            properties << get_label_for_id(json_graph, value["@id"])
          else
            properties << value.values
          end
        else
          properties << value
        end
      end
      return properties.flatten
    elsif attribute.has_key?("@id") #e.g. root_node['sioc:has_creator'] => {"@id"=>"/users/gabriella-rustici"}
      return get_label_for_id(json_graph, attribute["@id"])
    elsif attribute.has_key?('@value') #e.g. root["schema:description"] => {"@value"=>"<p> This is a description </p>"}
      parsed_value = Nokogiri::HTML(attribute['@value'])
      return parsed_value.html? ? parsed_value.text : attribute['@value']
    end
  end


  def self.get_label_for_id(graph, id)
    node = graph.select{|node| node['@id'] == id}.first
    labels = []
    if node
      node.delete("@id") if node.has_key?('@id')
      node.delete("@type") if node.has_key?('@type')
      return node
    else
      return id
    end
    return labels
  end
end
