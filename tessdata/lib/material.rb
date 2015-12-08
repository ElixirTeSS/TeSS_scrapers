class Material
  attr_accessor :title, :url, :short_description, :doi, :remote_updated_date, :remote_created_date, :content_provider_id

  def initialize(title, url, short_description, doi, remote_updated_date, remote_created_date, content_provider_id)
    @title = title || nil
    @url = url || nil
    @short_description = short_description || nil
    @doi = doi || nil
    @remote_updated_date = remote_updated_date || nil
    @remote_created_date = remote_created_date || nil
    @content_provider_id = content_provider_id || nil
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

