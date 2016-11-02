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
            params[:city], params[:country] = locality.split(',')
            params[:city].strip!
            params[:country].strip!
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
        [:title, :description, :start, :end, :venue, :postcode, :locality, :organizer, :duration, :url]
      end

      def self.array_attributes
        []
      end

      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.Event)
        end
      end

      def self.individual_query(event_uri)
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.description, :description, optional: true)
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.startDate, :start, optional: true)
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.endDate, :end, optional: true)
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.organizer, :end, optional: true)
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.duration, :duration, optional: true)
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.url, :url, optional: true)

          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.location, :location, optional: true)
          pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.name, :venue, optional: true)
          pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.postalCode, :postcode, optional: true)
          pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.addressLocality, :locality, optional: true)
        end
      end

    end
  end
end
