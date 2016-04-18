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

	  # The array item in graph with the given type (e.g. "CreativeWork") is the root node.
	  # This contains pointers to all of the properties the schema instance has.
	  # Find this root node to start:
	  if !json_graph.nil?
		  root_nodes = json_graph.select{|node| node["@type"].include?("schema:#{type}") or node["@type"].include?("https://schema.org/#{type}") if node["@type"]}

		  #root.keys gets the list of all the properties for this schema. For example a CreativeWork will return =>
		  #["@id", "@type", "dc:created", "dc:date", "rss:modules/content/encoded", "schema:audience",
		  # "schema:description", "schema:genre", "schema:hasPart", "schema:keywords", "schema:name", "schema:url", 
		  # "sioc:has_creator", "sioc:num_replies"] 

		  results_collection = []
		  root_nodes.each do |root_node| 
			  # Toss aside the @type and @id - we don't need them for now
			  properties = root_node.keys - ["@type", "@id"]
				  # Go through the list of properties contained in the schema instance and extract each value to put into our return hash.
			  # In most cases these contain an ID which we need to use the original json_graph object to lookup the value of. 
			  # (see ==Array and has_key?(@id) cases below)
			  res = {}
			  properties.each do |property_name|
			    data = root_node[property_name]
			    if !data
			        puts "No data for #{property_name}" if $debug
			    elsif data.class == String
			        res[property_name] = data
			    elsif data.class == Array #e.g. root_node['schema:genre'] => [{"@id"=>"/edam-topic/bioinformatics"}, {"@id"=>"/edam-topic/data-analysis"}] 
			        property_ids = data.collect{|item| item["@id"]}
			        res[property_name] = property_ids.collect{|id| get_label_for_id(json_graph, id)}.flatten
			        puts "#{property_name} ------ #{property_ids.join(", ")}" if $debug
			    elsif data.has_key?("@id") #e.g. root_node['sioc:has_creator'] => {"@id"=>"/users/gabriella-rustici"}
			        res[property_name] = get_label_for_id(json_graph, data["@id"])
			        puts "#{property_name} ------ #{res[property_name]}" if $debug
			    elsif data.has_key?('@value') #e.g. root["schema:description"] => {"@value"=>"<p> This is a description </p>"}
			        parsed_value = Nokogiri::HTML(data['@value'])
			        res[property_name] = parsed_value.html? ?  parsed_value.text : data['@value']
			        puts "#{property_name} ------ #{data['@value']}" if $debug
			    end 
			  end
			  results_collection << res
			end
			# res now contains a hash with all our property values.
			return results_collection
		else
			return []
		end
	end


	def self.get_label_for_id(graph, id)
	    node = graph.select{|node| node['@id'] == id}.first
	    labels = []
	    if node
	      node.delete("@id") if node.has_key?('@id')
	      node.delete("@type") if node.has_key?('@type')
	      node.values.each do |value|
	       if value.class == String
	            labels << value
	        elsif value.class == Hash
	          labels << value["@value"]
	        end
	      end
	    end
	    return labels.flatten.uniq
	end


end
