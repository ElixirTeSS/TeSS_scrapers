class Uploader

  def self.create_material(data)
    conf = Config.get_config
    action = '/materials.json'
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action
    auth = true
    return self.do_upload(data,url,conf,auth)
  end

    def self.check_material(data)
    conf = Config.get_config
    action = '/materials/check_title.json'
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action
    auth = false
    return self.do_upload(data,url,conf,auth)

  end

  def self.do_upload(data,url,conf,auth)
    # process data to json for uploading
    puts "Trying URL: #{url}"

    user_email = conf['user_email']
    user_token = conf['user_token']
    if user_email.nil? or user_token.nil?
      puts 'API connection information missing!'
      return
    end

    # The data to post must be converted to JSON and
    # the proper auth details added.
    if auth
      payload = {:user_email => user_email,
                :user_token => user_token,
                :material => data.dump
      }.to_json
    else
      payload = data.to_json
    end

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if url =~ /https/
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    req = Net::HTTP::Post.new(uri.request_uri, initheader = { 'Content-Type' =>'application/json' })

    req.body = payload
    res = http.request(req)

    unless res.code == '201' or res.code == '200'
      puts "Upload failed: #{res.code}"
      puts "ERROR: #{res.body}"
      return {}
    end

    # package_create returns the created package as its result.
    created_record = JSON.parse(res.body) rescue {}
    return created_record
  end



end
