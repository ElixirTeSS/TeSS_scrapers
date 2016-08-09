require 'rdf'
require 'open-uri'
require 'nokogiri'
require 'tess_api_client'
require 'linkeddata'
require 'geocoder'

$base_url = 'http://www.birmingham.ac.uk'
$index_page = 'http://www.birmingham.ac.uk/facilities/metabolomics-training-centre/index.aspx'

cp = ContentProvider.new({
                             title: "Birmingham metabolomics Training Centre",
                             url: "http://www.birmingham.ac.uk/facilities/metabolomics-training-centre/index.aspx",
                             image_url: "",
                             description: "Providing training to empower the next generation of metabolomics researchers. The Birmingham Metabolomics Training Centre will provide training to the metabolomics community in both analytical and computational methods. The training centre will partner with both the Phenome Centre Birmingham and the NERC Biomolecular Analysis Facility to provide vocational training courses in clinical and environmental metabolomics. A combination of both face-to-face and online courses will be provided.The training centre is directed by Professor Mark Viant, Dr Warwick Dunn, Dr Ralf Weber and Dr Catherine Winder.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:ORGANISATION],
                             node: Node::NODE_NAMES[:UK]
                         })

cp = Uploader.create_or_update_content_provider(cp)

def get_urls index
    page = Nokogiri::HTML(open(index))
    links_div = page.search('//*[@id="form1"]/main/div/div/div/div[1]/ul[1]')
    links = links_div.search('a').collect{|x| $base_url + x['href']}
    return links
end

def location(venue)
  loc = Geocoder.search(venue)
  if !loc.empty?
    lat = loc[0].data['geometry']['location']['lat']
    lon = loc[0].data['geometry']['location']['lng']
  end
  return [lat,lon]
end


urls = get_urls $index_page

urls.each do |url|
    rdfa = RDF::Graph.load(url, format: :rdfa)
    event = RdfaExtractor.parse_rdfa(rdfa, 'Event') if rdfa
    puts "No event found at #{url}"
    if event and !event.nil? and event.is_a? Array and !event.empty?
        begin
            event = event.first
            lat, lon = location event['schema:location']['schema:postalCode']
            upload_event = Event.new({
              content_provider_id: cp['id'],
              title: event['schema:name'],
              url: event['schema:url'],
              description: event['schema:description'],
              category: event['schema:category'],
              start_date: event['schema:startDate'],
              end_date: event['schema:endDate'],
              venue: event['schema:location']['schema:name'],
              city: event['schema:location']['schema:addressLocality'].split(',')[0],
              country: event['schema:location']['schema:addressLocality'].split(',')[1],
              postcode: event['schema:location']['schema:postcode'],
              latitude: lat,
              longitude: lon
            })
           Uploader.create_or_update_event(upload_event)
        rescue => ex
            puts ex.message
        end
    end
end

