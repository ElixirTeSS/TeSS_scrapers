# This doesn't actually scrape anything, but does perform an upload.

require 'tess_api_client'

$events_url = "https://www.statslife.org.uk/index.php?option=com_jevents&task=modlatest.rss&format=feed&type=rss&modid=284"
$events = {}
# The majority of events are here and their RSS does not contain location so use this set location data for each event.
$location = {
      :provider => 'Royal Statistical Society',
      :venue => 'The Royal Statistical Society',
      :city => 'London',
      :country => 'United Kingdom',
      :postcode => 'EC1Y 8LX',
      :latitude => 51.5225237,
      :longitude => -0.0909223
}

#separate date and title
#presented in format: "23 Jun 2016 10:00 : Presenting Data"
def parse_title string
  return string.split(' : ')
end

#Parse the HTML of the description to extract the duration. Return this as number of seconds
# to offset from start date
def duration_offset text
  match_data = text.match('CPD\s[-\s]*([0-9])*\s(hours|days)')
  #unit = match_data[2]  All are in hours - you can use this if they change to using days.
  return match_data[1].to_i * 3600 #86400 if days
end

#Found in the description. Parsing should account for different list styles
 #Presented by Richard D. Morey
 #Presented by Geert Verbeke and Geert Molenberghs
 #Presented by Tim Morris, Michael Crowther &amp; Ian White
 #Presented by -&nbsp;Ellen Marshall (University of Sheffield)&nbsp;and Jenny Freeman (University of Leeds)
def presented_by text
  
end


def parse_data(page)
  rss_feed = open page
  items = Nokogiri::XML(rss_feed).xpath('//item')
  items.each do |item|
    url = item.children.find{|x| x.name == 'link'}.text
    title_element = item.children.find{|x| x.name == 'title'}
    description = item.children.find{|x| x.name == 'description'}.text
    date, title = parse_title title_element.text
    start_date =  Time.parse(date)
    end_date = (start_date + duration_offset(description))
    $events[url] = {
      :title => title,
      :description => description,
      :start_date => start_date.to_s,
      :end_date => end_date.to_s
    }
  end
end


cp = ContentProvider.new(
    "Royal Statistical Society",
    "https://www.statslife.org.uk/",
    "https://www2.warwick.ac.uk/fac/sci/statistics/courses/rss/rss-strapline-logo-360x180.jpg",
    "We are a world-leading organisation promoting the importance of statistics and data - and a professional body for all statisticians and data analysts."
    )
cp = Uploader.create_or_update_content_provider(cp)

parse_data($events_url)

$events.each_key do |key| 
  event = Event.new({
      content_provider_id: cp['id'],
      title: $events[key][:title],
      url: key,
      category: 'course',
      start_date: $events[key][:start_date],
      end_date: $events[key][:end_date],
      description: $events[key][:description]
    }.merge($location)
    )  
  puts event.inspect if ScraperConfig.debug?
  Uploader.create_or_update_event(event)
end