module Tess
  module Scrapers
    require 'fileutils'
    require 'open-uri'
    require 'tess_api_client'
    require 'digest'
    require_relative 'tess/scrapers/scraper'
    require_relative 'tess/scrapers/rdfa_extractor'
    require_relative 'tess/scrapers/rdf_event_extractor'
    require_relative 'tess/scrapers/rdf_material_extractor'
    Dir['app/scrapers/*.rb'].each { |file| require_relative File.join('..', file )}
  end
end
