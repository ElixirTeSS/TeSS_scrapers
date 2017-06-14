module Tess
  module Scrapers
    require 'fileutils'
    require 'open-uri'
    require 'tess_api_client'
    require 'digest'
    require 'sanitize'
    require_relative 'tess/scrapers/scraper'
    require_relative 'tess/scrapers/rdfa_extractor'
    require_relative 'tess/scrapers/rdf_extraction'
    require_relative 'tess/scrapers/rdf_event_extractor'
    require_relative 'tess/scrapers/rdf_material_extractor'
    Dir['app/scrapers/*.rb'].each { |file| require_relative File.join('..', file )}
  end
end

# Tell Ruby RDF to not use RestClient to parse remote files
# https://github.com/ruby-rdf/rdf/issues/331
RDF::Util::File.http_adapter = RDF::Util::File::NetHttpAdapter
