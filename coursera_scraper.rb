#!/usr/bin/env ruby
require 'tess_api_client'

# For more details of the API and available terms, see:
# https://building.coursera.org/app-platform/catalog/


$lessons = {}
$debug = false
$root_url = 'https://api.coursera.org/api/courses.v1'
$friendly_url = 'https://www.coursera.org/learn/'
$owner_org = 'coursera'
$categories = {}
$search_term = 'bioinformatics'
$search_fields = 'description,domainTypes,primaryLanguages,subtitleLanguages'

def parse_data(page)
  return JSON.parse(open($root_url + page).read)
end

cp = ContentProvider.new({
                             title: "Coursera",
                             url: "http://www.coursera.org",
                             image_url: "http://upload.wikimedia.org/wikipedia/commons/e/e5/Coursera_logo.PNG",
                             description: "Coursera is an education platform that partners with top universities and organizations worldwide, to offer courses online for anyone to take, for free.",
                             content_provider_type: ContentProvider::PROVIDER_TYPE[:PORTAL]
                         })
cp = Uploader.create_or_update_content_provider(cp)

course_ids = parse_data("/?q=search&query=#{$search_term}&limit=10")['elements'].collect {|x| x['id']}
course_url = "?ids=#{course_ids.join(',')}&fields=#{$search_fields}"
parse_data(course_url)['elements'].each do |course|
  next unless course['primaryLanguages'].include?('en') # There are some Russian courses turning up...
  topics = [course['domainTypes'].collect {|x| x['domainId'] }, course['domainTypes'].collect {|x| x['subdomainId'] }].flatten.uniq
  begin
    material = Material.new({title: course['name'],
                            url: $friendly_url + course['slug'],
                            short_description: course['description'],
                            doi: nil,
                            remote_updated_date: Time.now,
                            remote_created_date: nil,
                            content_provider_id: cp['id'],
                            scientific_topic_names: [],
                            keywords: topics,
                            licence: nil,
                            difficulty_level: nil,
                            contributors: [],
                            authors: nil,
                            target_audience: nil
                           })
    puts material.inspect
    Uploader.create_or_update_material(material)
  rescue => ex
    puts ex.message
  end



end





__END__
{"id"=>"M5IS7Pw3EeW3kAo3Iffzfw",
"description"=>"In this class, we will compare DNA from an individual against a reference human genome to find potentially disease-causing mutations. We will also learn how to identify the function of a protein even if it has been bombarded by so many mutations compared to similar proteins with known functions that it has become barely recognizable.",
"domainTypes"=>[{"domainId"=>"life-sciences", "subdomainId"=>"bioinformatics"}, {"subdomainId"=>"algorithms", "domainId"=>"computer-science"}],
"slug"=>"dna-mutations", "courseType"=>"v2.ondemand", "subtitleLanguages"=>[], "name"=>"Finding Mutations in DNA and Proteins (Bioinformatics VI)", "primaryLanguages"=>["en"]}