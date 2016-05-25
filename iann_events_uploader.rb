# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api'
require 'nokogiri'

$debug = ScraperConfig.debug?

cp = ContentProvider.new(
    "iAnn",
    "https://iann.pro",
    "http://iann.pro/sites/default/files/itico_logo.png",
    "Enabling Collaborative Announcement Dissemination"
    )
cp = Uploader.create_or_update_content_provider(cp)

iann_dir = 'iann'
Dir.mkdir(iann_dir) unless Dir.exists?(iann_dir) 
iann_file = iann_dir + '/iann_events_' +Time.now.strftime("%Y%m%d.txt")

if File.exists?(iann_file)
  iann_content = File.open(iann_file).read
  puts "Already have a copy of todays iAnn events so loaded from file: '#{iann_file}'."
else
  iann_content = Net::HTTP.get('iann.pro', '/solr/select/?q=*&rows=20000&start=0')
  File.write(iann_file, iann_content)
  puts "Retrieved new iAnn dump for today. Saved in file #{File.absolute_path(iann_file)}."
end


docs = Nokogiri::HTML(iann_content).xpath('//doc')

docs.each do |event_item|
  event = Event.new
  event_item.children.each do |element|
    event.content_provider_id = cp['id']
    if element.text and !element.text.empty?
      case element.values
        when ['id']
          event.external_id = element.text
        when ['link']
          event.url = element.text
        when ['public'],
            ['submission_comment'], ['submission_date'], ['submission_name'],
            ['submission_organization'], ['_version_'], ['submission_email'], ['image']
          #puts "Ignored for element type #{element.values}"
        when ['keyword']
          event.keywords = element.children.collect{|children| children.text}
        when ['category'], ['field']
          event.send("#{element.values.first}=", element.children.collect{|children| children.text})
        else
          event.send("#{element.values.first}=", element.text)
      end
    end
  end

  Uploader.create_or_update_event(event)
end

