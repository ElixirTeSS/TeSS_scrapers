class Event
  attr_accessor :id, :external_id, :title,:subtitle,:link,:provider,:field,:description,:keyword,:category,:start,:end,:sponsor,:venue,:city,:county,
      :country,:postcode,:latitude,:longitude

  def initialize(id=nil, external_id=nil,title=nil,subtitle=nil,link=nil,provider=nil,field=nil,
                 description=nil,keyword=nil,category=nil,start_date=nil,end_date=nil,sponsor=nil,
                 venue=nil,city=nil,county=nil,country=nil,postcode=nil,latitude=nil,
                 longitude=nil)
    @id = id
    @external_id = external_id
    @title = title
    @subtitle = subtitle
    @link = link
    @provider = provider
    @field = field
    @description = description
    @keyword = keyword
    @category = category
    @start = start_date
    @end = end_date
    @sponsor = sponsor
    @venue = venue
    @city = city
    @county = county
    @country = country
    @postcode = postcode
    @latitude = latitude
    @longitude = longitude
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

