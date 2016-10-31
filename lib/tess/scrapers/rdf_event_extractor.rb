require 'linkeddata'

module Tess
  module Scrapers
    class RdfEventExtractor

      SINGLETON_ATTRIBUTES = [:title, :description, :start, :end, :venue, :postcode, :locality]
      ARRAY_ATTRIBUTES = []

      def initialize(source, format)
        @reader = RDF::Reader.for(format).new(source)
      end

      def extract
        graph = RDF::Graph.new
        graph << @reader

        graph.query(self.class.events_query).map do |res|
          evt_res = graph.query(self.class.event_query(res.event))
          bindings = evt_res.bindings
          params = {}

          SINGLETON_ATTRIBUTES.each do |attr|

            params[attr] = bindings[attr] ? bindings[attr].map { |v| v.object.strip }.uniq.first : nil
          end

          ARRAY_ATTRIBUTES.each do |attr|
            params[attr] = bindings[attr] ? bindings[attr].map { |v| v.object.strip }.uniq : []
          end

          # Need to check if this is a good solution...
          params[:city], params[:country] = params.delete(:locality).split(',')

          params[:city].strip!
          params[:country].strip!

          Tess::API::Event.new(params)
        end
      end

      private

      def self.events_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:event, RDF.type, RDF::Vocab::SCHEMA.Event)
        end
      end

      def self.event_query(event_uri)
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.description, :description, optional: true)
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.startDate, :start, optional: true)
          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.endDate, :end, optional: true)

          pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.location, :location, optional: true)
          pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.name, :venue, optional: true)
          pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.postalCode, :postcode, optional: true)
          pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.addressLocality, :locality, optional: true)
        end
      end

    end
  end
end
