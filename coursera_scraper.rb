#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'tess_api'

# https://building.coursera.org/app-platform/catalog/


$lessons = {}
$debug = false
$root_url = 'https://api.coursera.org/api/courses.v1'
$owner_org = 'coursera'
$categories = {}

def parse_data(page)
  return JSON.parse(open($root_url + page).read)
end


puts "DATA: #{parse_data('/?q=search&query=dna')}"

# Create the organisation.
=begin
org_title = 'Coursera'
org_name = $owner_org
org_desc = 'Coursera is an education platform that partners with top universities and organizations worldwide, to offer courses online for anyone to take, for free.'
org_image_url = 'http://upload.wikimedia.org/wikipedia/commons/e/e5/Coursera_logo.PNG'
homepage = 'https://www.coursera.org/'
node_id = ''
organisation = Organisation.new(org_title,org_name,org_desc,org_image_url,homepage,node_id)
Uploader.check_create_organisation(organisation)
=end