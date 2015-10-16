class Uploader

  def self.create_material(data)
    conf = Config.get_config
    action = '/materials.json'
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action
    return self.do_upload(data,url,conf)
  end

  def self.do_upload(data,url,conf)
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
    to_post = {:user_email => user_email,
               :user_token => user_token,
               :material => data.dump
    }.to_json


    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if url =~ /https/
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    req = Net::HTTP::Post.new(uri.request_uri, initheader = { 'Content-Type' =>'application/json' })
    req.body = data.to_json

    req.body = to_post
    res = http.request(req)

    unless res.code == '201'
      puts "Upload failed: #{res.code}"
      puts "ERROR: #{res.body}"
      return {}
    end

    # package_create returns the created package as its result.
    created_record = JSON.parse(res.body)
    return created_record
  end

end
