class Event
  attr_accessor :external_id, :title,:subtitle,:link,:provider,:field,:description,:category,:start,:end,:sponsor,:venue,:city,:county,
      :country,:postcode,:latitude,:longitude

  def initialize(external_id,title,subtitle,link,provider,field,description,category,start_date,end_date,sponsor,venue,city,county,
      country,postcode,latitude,longitude)
    @external_id = id || nil
    @title = title || nil
    @subtitle = subtitle || nil
    @link = link || nil
    @provider = provider || nil
    @field = field || nil
    @description = description || nil
    @category = category || nil
    @start = start_date || nil
    @end = end_date || nil
    @sponsor = sponsor || nil
    @venue = venue || nil
    @city = city || nil
    @county = county || nil
    @country = country || nil
    @postcode = postcode || nil
    @latitude = latitude || nil
    @longitude = longitude || nil
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

