require 'redcarpet'

class NgsRegistryScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'Legacy Sofware Carpentry Scraper',
        root_url: 'https://microasp.upsc.se/ngs_trainers/Materials/tree/master',
        json_file: 'https://bioinformatics.upsc.se/trainers/details.json',
        tedious_string: '[Top](#sub-module-title) | [Keywords](#keywords) | [Authors](#authors) | [Type](#type) | [Description](#description) | [Aims](#aims) | [Prerequisites](#prerequisites) | [Target audience](#target-audience) | [Learning objectives](#learning-objectives) | [Materials](#materials) | [Data](#data) | [Timing](#timing) | [Content stability](#content-stability) | [Technical requirements](#technical-requirements) | [Literature references](#literature-references)',
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
        exclude_list_urls: %w(
          https://microasp.upsc.se/ngs_trainers/Materials/tree/master/Content/RNA-Seq/Nicolas_Delhomme/EMBO-Oct-2014/01_EMBO-October-2014-Introduction.md
          https://microasp.upsc.se/ngs_trainers/Materials/tree/master/Content/README.md
          https://microasp.upsc.se/ngs_trainers/Materials/tree/master/Content/Prerequisite/201505-RNA-Seq-ChIP-Seq-Data-Analysis.md
          https://microasp.upsc.se/ngs_trainers/Materials/tree/master/Content/RNA-Seq/Benilton_Carvalho/SimpleRNASeqExample.md
        )
    }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "NGS Registry",
          url: "https://microasp.upsc.se/ngs_trainers/Materials/wikis/home",
          image_url: "",
          description: "GitLab repository and its Wiki companion containing a collection of training materials for teaching next generation sequencing data analysis.",
          content_provider_type: :project,
          node_name: :GB
        }))

    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    lessons = JSON.parse(open_url(config[:json_file]).read)

    lessons.each do |lesson|
      relative_path = lesson[0]
      page_url = "#{config[:root_url]}/#{relative_path}"
      unless config[:exclude_list_urls].include?(page_url)
        ngs_material = lesson[1]

        material = Tess::API::Material.new
        material.title = ngs_material['title']
        material.url = page_url
        material.content_provider = cp
        full_md_description = ngs_material['full']

        sections = ["## Keywords\n", "## Target audience (at least beginner/advanced)\n", "## Description\n"]

        if full_md_description.nil?
          material.description = ngs_material['title']
        else
          keywords_index = ngs_material['full'].find_index(sections[0])
          if !keywords_index.nil?
            a = ngs_material['full'][keywords_index+1].split(',').map(&:strip).uniq
            material.keywords = a
          end

          audience_index = ngs_material['full'].find_index(sections[1])
          if !audience_index.nil?
            material.target_audience = ngs_material['full'][audience_index+2]
          end

          #Not sure about this. Maybe should just use the FULL description rather than succinct.
          description_index = ngs_material['full'].find_index(sections[2])
          if !description_index.nil?
            material.description = ngs_material['full'][description_index+1]
          else
            material.description = 'No description available'
          end
          material.authors = ngs_material['authors']

          material.scientific_topic_names = [ngs_material['ontologies'] + material.keywords].flatten.map(&:strip).uniq
        end

        add_material(material)
      end
    end
  end
end
