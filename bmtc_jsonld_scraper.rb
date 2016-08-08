require 'rdf'
require 'open-uri'
require 'nokogiri'
require 'tess_api_client'
require 'linkeddata'
require 'geocoder'

cp = ContentProvider.new({
                             title: "Birmingham metabolomics Training Centre",
                             url: "http://www.birmingham.ac.uk/facilities/metabolomics-training-centre/index.aspx",
                             image_url: "",
                             description: "Providing training to empower the next generation of metabolomics researchers. The Birmingham Metabolomics Training Centre will provide training to the metabolomics community in both analytical and computational methods. The training centre will partner with both the Phenome Centre Birmingham and the NERC Biomolecular Analysis Facility to provide vocational training courses in clinical and environmental metabolomics. A combination of both face-to-face and online courses will be provided.The training centre is directed by Professor Mark Viant, Dr Warwick Dunn, Dr Ralf Weber and Dr Catherine Winder.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION],
                             node: Node::NODE_NAMES[:UK]
                         })
#cp = Uploader.create_or_update_content_provider(cp)



url = 'http://www.birmingham.ac.uk/facilities/metabolomics-training-centre/courses/sample-analysis.aspx'
rdfa = RDF::Graph.load(url, format: :rdfa)
event = RdfaExtractor.parse_rdfa(rdfa, 'Event')

def location(venue)
  loc = Geocoder.search(venue)
  if !loc.empty?
    lat = loc[0].data['geometry']['location']['lat']
    lon = loc[0].data['geometry']['location']['lng']
  end
  return [lat,lon]
end

if event and !event.nil? and event.is_a? Array
    begin
    	lat, lon = location event['schema:location'][2]
		event = event.first
		upload_event = Event.new({
	      content_provider_id: cp['id'],
	      title: event['schema:name'],
	      url: event['schema:url'],
	      description: event['schema:description'],
	      category: event['schema:category'],
	      start_date: event['schema:startDate'],
	      end_date: event['schema:endDate'],
	      venue: event['schema:location'],
	      lat: lat,
	      lon: lon
	    })
	    Uploader.create_or_update_event(upload_event)
    rescue => ex
      puts ex.message
   end
end