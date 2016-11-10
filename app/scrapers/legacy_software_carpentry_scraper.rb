# This "scraper"" behaves a bit differently than the others. It clones a git repo rather than scraping a website.

class LegacySoftwareCarpentryScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Legacy Sofware Carpentry Scraper',
        offline_url_mapping: {},
        root_url: 'https://github.com/swcarpentry',
        gh_pages_path: '/bc/tree/gh-pages/',
        git_repo: '/bc.git',
        skill_levels: { 'novice' => %w{extras git hg matlab python r ref shell sql teaching},
                        'intermediate' => %w{doit git make python r regex shell sql webdata} }
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Software Carpentry",
          url: "http://software-carpentry.org/",
          image_url: "http://software-carpentry.org/img/software-carpentry-banner.png",
          description: "The Software Carpentry Foundation is a non-profit organization whose members teach researchers basic software skills.",
          content_provider_type: :organisation
        }))

    git_setup

    lessons = parse_data

    # Create the new record
    lessons.each do |key, data|
      add_material(Tess::API::Material.new(
          { title: data['title'],
            url: key,
            short_description: "#{data['title']} from #{key}.",
            remote_updated_date: data['date'],
            content_provider: cp,
            keywords: data['tags'],
            target_audience: data['audience']
          }))
    end
  end

  private

  def git_setup
    git_path = cache_file_path('git', true)
    unless File.exists?(git_path)
      puts "Cloning git repo..."
      %x{git clone #{config[:root_url]}#{config[:git_repo]} #{git_path}}
    end
    %x{cd #{git_path} && git pull} unless offline
  end

  def parse_data
    lessons = {}

    config[:skill_levels].each do |skill, topics|
      topics.each do |topic|
        #puts "Got #{skill} lesson category entitled #{topic}."
        files = Dir["#{cache_file_path('git')}/#{skill}/#{topic}/*.md"]
        files.each do |file|
          basename = File.basename(file)
          next if basename == "README.md"
          next if basename == "index.md"
          File.foreach(file).with_index do |line,i|
            break if i >= 5
            if line =~ /title:/
              # We have a lesson, and need to save the URL, title, and tags.
              title = line.chomp.gsub(/title: /,'')
              url = "#{config[:root_url]}#{config[:gh_pages_path]}#{skill}/#{topic}/#{basename}"
              lessons[url] = {}
              lessons[url]['tags'] = [topic.capitalize]
              lessons[url]['audience'] = [skill.capitalize]
              lessons[url]['title'] = title
              break
            end
          end
          File.foreach(file).with_index do |line,i|
            break if i >= 20
            if line =~ /Date:/
              date = line.chomp.gsub(/Date: /,'')
              url = "#{config[:root_url]}#{config[:gh_pages_path]}#{skill}/#{topic}/#{basename}"
              lessons[url]['date'] = date
              break
            end
          end
        end
      end
    end

    lessons
  end
end
