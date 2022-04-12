require "active_support"
require "active_support/testing/time_helpers"
module Tess
  module Scrapers
    require 'fileutils'
    require 'open-uri'
    require 'tess_api_client'
    require 'digest'
    require 'sanitize'
    require 'tess_rdf_extractors'
    require_relative 'tess/scrapers/scraper'
    require_relative 'tess/scrapers/rdfa_extractor'
    Dir['app/scrapers/*.rb'].each { |file| require_relative File.join('..', file )}
  end
end

# Tell Ruby RDF to not use RestClient to parse remote files
# https://github.com/ruby-rdf/rdf/issues/331
RDF::Util::File.http_adapter = RDF::Util::File::NetHttpAdapter
