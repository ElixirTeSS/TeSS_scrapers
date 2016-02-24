#gem install 'rdf/rdfa'
#gem install 'json-ld'

require 'rdf/rdfa'
require 'json/ld'
require 'open-uri'
require 'nokogiri'
require 'tess_api'

# This scraper should use the XML API to get the URL of each course, then go to each individual
# course page to parse embedded RDFa data.

$courses = 'http://www.mygoblet.org/training-portal/courses-xml'
$materials = 'http://www.mygoblet.org/training-portal/materials-xml'
$owner_org = 'goblet'
$lessons = {}
$debug = true

# Get all URLs from XML
def get_urls(page,type)
  if $debug
    urls = IO.readlines("html/goblet_#{type}.txt").collect {|x| x.chomp!}
  else
    doc = Nokogiri::XML(open(page))
    urls = []

    doc.search('nodes > node').each do |node|
      url = nil
      node.search('URL').each do |t|
        url = t.inner_text
      end
      if url
        urls << url
      end
    end
  end

  return urls
end


def get_label_for_id(graph, id)
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


xxx = File.open('big_dump.json', 'w') if $debug

get_urls($materials,'materials').each do |url|
	#f = open(url)
	rdfa = RDF::Graph.load(url, format: :rdfa)
	json_graph = JSON.load(rdfa.dump(:jsonld, standard_prefixes: true))["@graph"]

=begin
	json_graph looks like this.
	{
	  	:@context => {<some stuff>}, 
	  	:@graph => [
		{
		    "@id" => /audience-tags/beginner-bioinformaticians
			"@type" => "skos:Concept"
			"rdfs:label" => {
				"@value"=>"beginner bioinformaticians",
				"@language"=>"en"
			} 
			skos:prefLabel" => {
				"@value"=>"beginner bioinformaticians",
				"@language"=>"en"
			} 
		},
		{
			"@id"=>"/users/gabriella-rustici",
			"@type"=>["schema:Person", "sioc:UserAccount"], 
			schema:name"=>"Gabriella Rustici" 
		}
	    ]
	}
=end

	# The array item in graph with the type "CreativeWork" is the root node. This contains pointers to all of the properties the Creative work has.
	# Find the CreativeWork node to start:
	root = json_graph.select{|x| x["@type"].include?("schema:CreativeWork") if x["@type"]}.first

	#root.keys gets the list of all the CreativeWorks attribtues =>
	#["@id", "@type", "dc:created", "dc:date", "rss:modules/content/encoded", "schema:audience",
	# "schema:description", "schema:genre", "schema:hasPart", "schema:keywords", "schema:name", "schema:url", 
	# "sioc:has_creator", "sioc:num_replies"] 

	# Toss aside the @type and @id - we don't need them for now
	properties = root.keys - ["@type", "@id"]

	# Go through the list of properties contained in CreativeWork and extract values to put in our hash.
	# In most cases these contain an ID which we need to use the original json_graph object to lookup the value of. 
	# (see ==Array and has_key?(@id) cases below)
	material = {}
	properties.each do |property|
		values = root[property]
	    if !values or values.class == String
	      puts "Nope for #{property}" if $debug
	    elsif values.class == Array #e.g. root['schema:genre'] => [{"@id"=>"/edam-topic/bioinformatics"}, {"@id"=>"/edam-topic/data-analysis"}] 
	      property_ids = values.collect{|x| x["@id"]}
		  material[property] = property_ids.collect{|id| get_label_for_id(json_graph, id)}.flatten
	      puts "#{property} ------ #{property_ids.join(", ")}" if $debug
	    elsif values.has_key?("@id") #e.g. root['sioc:has_creator'] => {"@id"=>"/users/gabriella-rustici"}
	      material[property] = get_label_for_id(json_graph, values["@id"])
	      puts "#{property} ------ #{material[property]}" if $debug
	    elsif values.has_key?('@value') #e.g. root["schema:description"] => {"@value"=>"<p> This is a description </p>"}
	      material[property] = values['@value']
	      puts "#{property} ------ #{values['@value']}" if $debug
	    end 
	end
	# Material now contains a hash with all our training materials' fields. 

	#write out to JSON for debug mode.
	if $debug
		material.each do |material|
		  xxx.write("#{material.to_json}")
		end
	end

	puts "#{material['schema:name']}"
end
