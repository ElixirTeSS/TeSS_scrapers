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
          email = params.delete(:contact_email)
          name = params.delete(:contact_name)
          if email and name
            params[:contact] = "#{name} - #{email}"
          elsif email
            params[:contact] = email
          elsif name
            params[:contact] = name
          end

          Tess::API::Event.new(params)
        end
      end

      private

      def self.singleton_attributes
        [:title, :description, :start, :end, :venue, :postcode, :locality, 
          :organizer, :duration, :url, :country, :latitude, :longitude, 
          :contact_name, :contact_email, :contact
          ]
      end

      def self.array_attributes
        [:keywords, :scientific_topic_names, :host_institutions]
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
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocabulary::Term.new('http://schema.org/topic', attributes: {}), :scientific_topic_names, optional: true)
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocabulary::Term.new('http://schema.org/topic', attributes: {}), :keywords, optional: true)
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
            end,
            #Host institution
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocabulary::Term.new('http://schema.org/hostInstitution', attributes: {}), :host_institution)
              pattern RDF::Query::Pattern.new(:host_institution, RDF::Vocab::SCHEMA.name, :host_institutions, optional: true)
            end,
            #Contact 
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(event_uri, RDF::Vocabulary::Term.new('http://schema.org/contact', attributes: {}), :contact_details)
              pattern RDF::Query::Pattern.new(:contact_details, RDF::Vocab::SCHEMA.email, :contact_email, optional: true)
              pattern RDF::Query::Pattern.new(:contact_details, RDF::Vocab::SCHEMA.name, :contact_name, optional: true)
            end

        ]
      end
    end
  end
end
