require 'linkeddata'

module Tess
  module Scrapers
    class RdfEventExtractor

      include Tess::Scrapers::RdfExtraction

      def extract
        super do |params|
          # Need to check if this is a good solution...
          locality = params.delete(:locality)
          if locality
            params[:city], locality_country = locality.split(',')
            params[:country] ||= locality_country
            params[:city].strip! if params[:city]
            params[:country].strip! if params[:country]
          end

          duration = params.delete(:duration)
          if !params[:end] && params[:start] && duration
            params[:end] = modify_date(params[:start], duration)
          end

          Tess::API::Event.new(params)
        end
      end

      private

      def self.singleton_attributes
        [:title, :description, :start, :end, :venue, :postcode, :locality, 
          :organizer, :duration, :url, :country, :latitude, :longitude]
      end

      def self.array_attributes
        []
      end

      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.Event)
        end
      end

      def self.individual_queries(event_uri)
        [
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.description, :description, optional: true)
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.startDate, :start, optional: true)
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.endDate, :end, optional: true)
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.organizer, :organizer, optional: true)
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.duration, :duration, optional: true)
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.url, :url, optional: true)
            end,
            # Other location info
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.location, :location)
              pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.name, :venue, optional: true)
              pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.postalCode, :postcode, optional: true)
              pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.addressLocality, :locality, optional: true)
            end,
            #Location Geoocordinates
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.location, :location)
              pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.geo, :geo)
              pattern RDF::Query::Pattern.new(:geo, RDF::Vocab::SCHEMA.longitude, :longitude, optional: true)
              pattern RDF::Query::Pattern.new(:geo, RDF::Vocab::SCHEMA.latitude, :latitude, optional: true)
            end,
            #Location address
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.location, :location)
              pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.address, :address)
              pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.location, :location, optional: true)
              pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.postalCode, :postcode, optional: true)
              pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressCountry, :country, optional: true)
              pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressLocality, :locality, optional: true)
            end
        ]
      end
    end
  end
end
