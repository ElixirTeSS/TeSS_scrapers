class Material
  attr_accessor :title, :url, :short_description, :doi, :remote_updated_date, :remote_created_date, :content_provider_id,
                :scientific_topic, :keywords, :id

  def initialize(title=nil, url=nil, short_description=nil, doi=nil, remote_updated_date=nil, remote_created_date=nil,
                 content_provider_id=nil, scientific_topic=[], keywords=[], licence=nil, difficulty_level=nil,
                 contributors=[], authors=[], target_audience=[], id=nil)
    @title = title
    @url = url
    @short_description = short_description 
    @doi = doi 
    @remote_updated_date = remote_updated_date 
    @remote_created_date = remote_created_date 
    @content_provider_id = content_provider_id 
    @scientific_topic = scientific_topic 
    @keywords = keywords 
    @licence = target_audience 
    @difficulty_level = target_audience 
    @contributors = target_audience 
    @authors = target_audience 
    @target_audience = target_audience
    @id = id
  end


  def dump
    hash = {}
    self.instance_variables.each do |var|
      varname = var.to_s.gsub(/@/,'')
      hash[varname] = self.instance_variable_get var
    end
    return hash
  end

  def to_json
    return self.dump.to_json
  end

  def [](var)
    return self.send(var)
  end

end

