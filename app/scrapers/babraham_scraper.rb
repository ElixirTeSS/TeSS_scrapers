class BabrahamScraper < Tess::Scrapers::Scraper

  def self.config
  {
    name: 'Babraham Scraper',
    root_url: 'https://www.bioinformatics.babraham.ac.uk',
    materials_path: 'cgi-bin/public/course_dates.cgi',
  }
  end

  def scrape
    cp = add_content_provider(Tess::API::ContentProvider.new(
                                title: 'Babraham Institute Bioinformatics Group',
                                url: 'https://www.bioinformatics.babraham.ac.uk',
                                image_url: 'https://www.bioinformatics.babraham.ac.uk/images/babraham_bioinformatics.gif',
                                description: 'The Babraham Institute Bioinformatics Groupwprovides bioinformatics services
                                              to the 30 research groups which form the institute as well as providing an
                                              external commercial consultancy service. The group has experience in a wide
                                              variety of areas of bioinformatics including genomics, proteomics, statistics
                                              and microarrays as well as having extensive experience of custom software
                                              development. ',
                                content_provider_type: :organisation
    ))

    materials_route = "#{config[:root_url]}/#{config[:materials_path]}"
    doc = Nokogiri::HTML(open_url(materials_route).read)

    contact = doc/'a[href ^="mailto:"]'
    doc.search('table > tr').each do |row|
      begin
        title = row.css('td')[0].text.strip
        start_date = row.css('td')[1].text.strip
        start_time = row.css('td')[2].text.strip
        end_date = row.css('td')[3].text.strip
        end_time = row.css('td')[4].text.strip
        free_spaces = row.css('td')[5].text.strip
        venue = row.css('td')[6].text.strip
      rescue
        # This will be the table header.
      end

      next unless title

      postcode = nil
      if venue == 'Babraham Campus'
        postcode = 'CB22 3AT'
      end


      desc = "For more details please see https://www.bioinformatics.babraham.ac.uk/cgi-bin/public/course_dates.cgi. Course status: #{free_spaces}."

      event = Tess::API::Event.new(
          content_provider: cp,
          title: title,
          url: contact[0]['href'],
          description: desc,
          start: "#{start_date}, #{start_time}",
          end: "#{end_date}, #{end_time}",
          venue: venue,
          postcode: postcode
      )
      #puts event.inspect
      puts("Adding: #{title}")
      add_event(event)

=begin
      add_event(Tess::API::Event.new(
          content_provider: cp,
          title: title,
          url: 'https://www.bioinformatics.babraham.ac.uk/cgi-bin/public/course_dates.cgi#' + title.gsub(' ', '_'),
          contact: contact[0]['href'],
          description: desc,
          start: "#{start_date}, #{start_time}",
          end: "#{end_date}, #{end_time}",
          venue: venue,
          postcode: postcode
      ))
=end

    end


  end

end