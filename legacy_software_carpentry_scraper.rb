#!/usr/bin/env ruby

require 'tess_api_client'


$lessons = {}
$debug = ScraperConfig.debug?
$git_dir = "#{ENV['HOME']}/Work/Web/bc/"
$owner_org = 'software-carpentry'
$git_url = "https://github.com/swcarpentry/bc/tree/gh-pages/"
$skill_levels = {'novice' => %w{extras git hg matlab python r ref shell sql teaching},
                 'intermediate' => %w{doit git make python r regex shell sql webdata}}

$git_repo_remote = "https://github.com/swcarpentry/bc.git"
$git_repo = Dir.pwd + '/bc/'
#Not sure if there'll be updates to this repo as its frozen but it can't hurt.
if File.exists?($git_repo)
    %x{cd bc && git pull #{$git_repo} & cd ..}
else
    %x{git clone #{$git_repo_remote} }
end


def parse_data
  $skill_levels.each_pair do |k,v|
    v.each do |value|
      #puts "Got #{k} lesson category entitled #{value}."
      files = Dir["#{$git_repo}#{k}/#{value}/*.md"]
      puts files
      files.each do |file|
        basename = File.basename(file)
        next if basename == "README.md"
        next if basename == "index.md"
        File.foreach(file).with_index do |line,i|
          break if i >= 5
          if line =~ /title:/
            # We have a lesson, and need to save the URL, title, and tags.
            title = line.chomp.gsub(/title: /,'')
            url = "#{$git_url}#{k}/#{value}/#{basename}"
            $lessons[url] = {}
            $lessons[url]['tags'] = [value.capitalize]
            $lessons[url]['audience'] = [k.capitalize]
            $lessons[url]['title'] = title
            break
          end
        end
        File.foreach(file).with_index do |line,i|
          break if i >= 20
          if line =~ /Date:/
            date = line.chomp.gsub(/Date: /,'')
            url = "#{$git_url}#{k}/#{value}/#{basename}"
            $lessons[url]['date'] = date
            break
          end
        end
      end
    end
  end
end


parse_data

cp = ContentProvider.new(
    "Software Carpentry",
    "http://software-carpentry.org/",
    "http://software-carpentry.org/img/software-carpentry-banner.png",
    "The Software Carpentry Foundation is a non-profit organization whose members teach researchers basic software skills.")
cp = Uploader.create_or_update_content_provider(cp)

# Create the new record
$lessons.each_key do |key|
  material = Material.new(title = $lessons[key]['title'],
                          url = key,
                          short_description = "#{$lessons[key]['title']} from #{key}.",
                          doi = nil,
                          remote_updated_date = $lessons[key]['date'],
                          remote_created_date = nil,
                          content_provider_id = cp['id'],
                          scientific_topic = [],
                          keywords = $lessons[key]['tags'],
                          licence = nil, 
                          difficulty_level = nil, 
                          contributors = nil,
                          authors = nil,
                          target_audience = $lessons[key]['audience'],
                          id = id
                          )
  Uploader.create_or_update_material(material)
end

