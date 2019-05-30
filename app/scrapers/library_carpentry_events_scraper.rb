class LibraryCarpentryEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        events_file: "https://raw.githubusercontent.com/LibraryCarpentry/librarycarpentry.github.io/master/_data/workshops.yml"
    }
  end

  def scrape

    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Library Carpentry",
          url: "https://librarycarpentry.org/",
          image_url: "https://carpentries.org/images//logos/lc.svg",
          description: "Library Carpentry develops lessons and teaches workshops for and with people working in library- and information-related roles. Our goal is to create an on-ramp to empower this community to use software and data in their own work as well as be advocates for and train others in efficient, effective and reproducible data and software practices.",
          content_provider_type: :organisation,
          keywords: ['The Carpentries']
        }))

    events = open_url(config[:events_file])
    workshops_yaml = YAML.load(events)

    workshops_yaml["workshops"].each do |workshop|
      add_event(Tess::API::Event.new(
          content_provider: cp,
          title: "Library Carpentry - #{workshop['venue']}",
          url: workshop['site'],
          start: workshop['start_date'],
          end: workshop['end_date'],
          description: "Software and data skills for people working in library- and information-related roles.\n
          #{workshop['notes'] unless workshop['notes'].blank?}",
          #   organizer: '',
          event_types: [:workshops_and_courses],
          latitude: workshop['latitude'],
          longitude: workshop['longitude'],
          venue: workshop['venue'],
          #    postcode: venue_data['address']['postal_code'],
          #    city: venue_data['address']['city'],
          country: workshop['country']
      ))
    end

  end
end

