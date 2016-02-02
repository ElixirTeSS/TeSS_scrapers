class ContentProvider
  attr_accessor :title,:url,:logo_url,:description,:id

  def initialize(title=nil, url=nil, logo_url=nil,description=nil,id=nil)
  	@title = title
  	@url = url
  	@logo_url = logo_url
    @description = description
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

