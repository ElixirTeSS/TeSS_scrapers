class DataCarpentryEventsScraper < Tess::Scrapers::Scraper

  def self.config
    {
        events_file: "https://raw.githubusercontent.com/datacarpentry/datacarpentry.github.io/master/_data/dc_upcoming_workshops.json"
    }
  end

  def scrape

    cp = add_content_provider(Tess::API::ContentProvider.new(
        { title: "Data Carpentry",
          url: "https://datacarpentry.org/",
          image_url: "https://carpentries.org/images//logos/dc.svg",
          description: "Data Carpentry develops and teaches workshops on the fundamental data skills needed to conduct research. Our mission is to provide researchers high-quality, domain-specific training covering the full lifecycle of data-driven research.",
          content_provider_type: :organisation,
          keywords: ['The Carpentries']
        }))

    workshops_file = open_url(config[:events_file])
    workshops_json = JSON.parse(workshops_file.read)

    workshops_json.each do |workshop|
      add_event(Tess::API::Event.new(
          content_provider: cp,
          title: "Data Carpentry - #{workshop['venue']}",
          url: workshop['url'],
          start: workshop['start_date'],
          end: workshop['end_date'],
          description: "Data Carpentry trains researchers in the core data skills for efficient, shareable, and reproducible research practices. We run accessible, inclusive training workshops; teach openly available, high-quality, domain-tailored lessons; and foster an active, inclusive, diverse instructor community that promotes and models reproducible research as a community norm.\n",
          #   organizer: '',
          event_types: [:workshops_and_courses],
          latitude: workshop['latitude'],
          longitude: workshop['longitude'],
          venue: workshop['venue'],
          #    postcode: venue_data['address']['postal_code'],
          #    city: venue_data['address']['city'],
          country: workshop['country'],
          host_institutions: [workshop['host_name']]
      ))
    end
  end
end
