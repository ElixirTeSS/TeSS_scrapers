require 'linkeddata'

module Tess
  module Scrapers
    module RdfExtraction

      def initialize(source, format)
        @reader = RDF::Reader.for(format).new(source)
      end

      def extract(&block)
        graph = RDF::Graph.new
        graph << @reader

        graph.query(self.class.type_query).map do |res|
          individual = graph.query(self.class.individual_query(res.individual))
          bindings = individual.bindings
          params = {}

          self.class.singleton_attributes.each do |attr|
            params[attr] = parse_values(bindings[attr]).first
          end

          self.class.array_attributes.each do |attr|
            params[attr] = parse_values(bindings[attr])
          end

          yield params
        end
      end

      def parse_values(values)
        if values
          values.map do |v|
            case v
              when RDF::Literal::HTML
                v.object.text.strip
              when RDF::Literal::DateTime
                v.object
              when RDF::Literal
                v.object.strip
              else
                v.object
            end
          end.uniq
        else
          []
        end
      end

      def modify_date(date, duration)
        matches = duration.match(/P([^T]+)T?(.*)/)
        date_period = matches[1]

        date_period.scan(/(\d+)([YMWD])/).each do |match|
          value = match[0].to_i
          case match[1]
            when 'Y'
              date = date >> (12 * value)
            when 'M'
              date = date >> value
            when 'W'
              date = date + (7 * value)
            when 'D'
              date = date + value
          end
        end
        # time_period = matches[2]
        #
        # time_period.scan(/(\d+)([HMS])/).each do |match|
        #   case match[1]
        #     when 'H'
        #     when 'M'
        #     when 'S'
        #   end
        # end
        date
      end

    end
  end
end
