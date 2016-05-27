require 'json'
require 'tess_api_client'
require 'open-uri'


cp = ContentProvider.new(
    "Khan Academy Statistics",
    "https://www.khanacademy.org/math/probability",
    "https://fastly.kastatic.org/images/khan-logo-vertical-transparent.png",
    "Can I pick a red frog out of a bag that only contains marbles? Is it smart to buy a lottery ticket? Even if we are unsure about whether something will happen, can we start to be mathematical about the \"chances\" of an event (essentially realizing that some things are more likely than others). These tutorials will introduce us to the tools that allow us to think about random events."
    )
cp = Uploader.create_or_update_content_provider(cp)


broad_topics = %w( statistics-inferential regression random-variables-topic descriptive-statistics statistical-studies probability-and-combinatorics-topic independent-dependent-probability)

$root_url = 'http://www.khanacademy.org/api/v1/topic/'
broad_topics.each do |topic|
	response = open($root_url + topic)
	topics = JSON.parse(response.read)
	topics['children'].each do |subtopic|
		description = !subtopic['description'].empty? ? subtopic['description'] : "#{subtopic['title']} from #{cp['title']}"
		subtopic['title']
		subtopic['url']
		keyword = topic['title']
		begin
        	upload_material = Material.new(
              title = subtopic['title'],
              url = subtopic['url'],
              short_description = description, 
              doi = nil,
              remote_updated_date = Time.now,
              remote_created_date = nil,
              content_provider_id = cp['id'],
              scientific_topic_names = ['Statistics and probability'],
              keywords = [topics['title']],
              licence = nil,
              difficulty_level = nil,
              contributors = [],
              authors = nil,
              target_audience = nil
            ) 
        	Uploader.create_or_update_material(upload_material)
	    rescue => ex
	      puts ex.message
	    end
	end
end
