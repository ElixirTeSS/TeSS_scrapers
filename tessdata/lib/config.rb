class Config

  def self.get_config
    host, port, protocol, user_email, user_token = nil
    myini = IniFile.load('uploader_config.txt')

    unless myini
      raise "Can't open config file!"
    end

    myini.each_section do |section|
      if section == 'Main'
        host = myini[section]['host']
        port = myini[section]['port']
        protocol = myini[section]['protocol']
        user_email = myini[section]['user_email']
        user_token = myini[section]['user_token']
      end
    end

    return {
        'host' => host,
        'port' => port,
        'protocol' => protocol,
        'user_email' => user_email,
        'user_token' => user_token
    }

  end

  def self.debug?
    return myini = IniFile.load('uploader_config.txt')['Main']['debug'] || false
  end
end