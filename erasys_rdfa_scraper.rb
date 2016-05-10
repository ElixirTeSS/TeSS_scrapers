
require 'rdf/rdfa'
require 'open-uri'
require 'nokogiri'
require 'tess_api'
require 'digest/sha1'

url = 'http://www.sbedu.eu/'
rdfa = RDF::Graph.load(url, format: :rdfa)
m = RdfaExtractor.parse_rdfa(rdfa, 'BlogPosting')

m.each do |material| 
  #puts material['schema:name']
  puts material['schema:author'].collect{|x| trim_characters x} unless material['schema:author'].nil?
  puts material['schema:dateCreated']
  material['schema:keywords'].collect{|x| puts trim_characters x} unless material['schema:keywords'].nil?
  puts trim_characters material['schema:name']
  puts material['schema:url']
end


def trim_characters(string)
  return string.gsub(/\W/, '')
end
