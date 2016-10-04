# To be run from console
require 'csv'

csv = CSV.parse(open('old_tess_users.txt'))
users = []
csv.each do |user|
  users << user.first.split('|').collect{|x| x.strip}
end

users.each do |user|
  name = user.last.split(' ')
  firstname = name.shift
  surname = name.join(' ')

  email = user.second
  username = user.first

  u = User.find_by_username(username)
  if u.nil?
    u = User.new(:username => username, :email => email)
    u.set_default_profile
    u.set_default_role
    u.confirmed_at = Time.now
    #u.password = SecureRandom.hex
    u.authentication_token = Devise.friendly_token
    u.password = Devise.friendly_token
    u.profile.firstname = firstname
    u.profile.surname = surname
    u.save!
  end

end
