require 'linkeddata'

class RdfMaterialExtractor

  SINGLETON_ATTRIBUTES = [:title, :short_description, :remote_created_date]
  ARRAY_ATTRIBUTES = [:scientific_topic_names, :keywords, :authors, :target_audience]

  def initialize(source, format)
    @reader = RDF::Reader.for(format).new(source)
  end

  def extract
    graph = RDF::Graph.new
    graph << @reader

    graph.query(self.class.materials_query).map do |res|
      mat_res = graph.query(self.class.material_query(res.material))
      bindings = mat_res.bindings
      params = {}

      SINGLETON_ATTRIBUTES.each do |attr|
        params[attr] = bindings[attr] ? bindings[attr].map(&:object).uniq.first : nil
      end

      ARRAY_ATTRIBUTES.each do |attr|
        params[attr] = bindings[attr] ? bindings[attr].map(&:object).uniq : []
      end

      Tess::API::Material.new(params)
    end
  end

  private

  def self.materials_query
    RDF::Query.new do
      pattern RDF::Query::Pattern.new(:material, RDF.type, RDF::Vocab::SCHEMA.CreativeWork)
    end
  end

  def self.material_query(material_uri)
    RDF::Query.new do
      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.description, :short_description, optional: true)
      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::DC.date, :remote_created_date, optional: true)

      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.genre, :scientific_topics, optional: true)
      pattern RDF::Query::Pattern.new(:scientific_topics, RDF::RDFS.label, :scientific_topic_names, optional: true)

      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.keywords, :keyword_obs, optional: true)
      pattern RDF::Query::Pattern.new(:keyword_obs, RDF::RDFS.label, :keywords, optional: true)

      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SIOC.has_creator, :author_obs, optional: true)
      pattern RDF::Query::Pattern.new(:author_obs, RDF::Vocab::SCHEMA.name, :authors, optional: true)

      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.audience, :target_audience_obs, optional: true)
      pattern RDF::Query::Pattern.new(:target_audience_obs, RDF::RDFS.label, :target_audience, optional: true)
    end
  end

end
