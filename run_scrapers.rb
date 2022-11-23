require_relative 'lib/tess_scrapers'
require 'net/smtp'
require 'pathname'
require 'fileutils'

log = 'log/scrapers.log' # The log file for this script, just mentions which scrapers are run.
output = 'log/scrapers.out' # The log file for scraper output. Says how many events etc. were scraped. Need to logrotate this, will be big!
email = ARGV[0] != 'no_email' rescue true

scrapers = [
   BabrahamScraper,
   #BiocompRdfaScraper,
   BioconductorScraper,
   BioconductorJsonldScraper,
   BioschemasScraper,
   #BitsvibEventsJsonldScraper,
   #BitsvibRdfaScraper,
   BiviMaterialScraper,
   BiviEventScraper,
   BmtcJsonldScraper,
   CambridgeEventsScraper,
   CourseraScraper,
   #CscEventsScraper,
   CscEventsScraperNew,
   CvlEventbriteScraper,
   DataCarpentryScraper,
   #DataCarpentryEventsScraper,
   DenbiScraper,
   DtlsEventsScraper,
   #EbiScraper, # Broken old materials one
   EbiJsonScraper,
   EdinburghScraper,
   ElixirEventsScraper,
   EnanomapperScraper,
   #ErasysRdfaScraper, # Domain changed to erasysapp.eu, breaking old links
   #FlemishJsonldEventsScraper,
   FuturelearnRdfaScraper,
   GalaxyEventsScraper,
   #GalaxyScraper,
   Genome3dScraper,
   GobletRdfaScraper,
   #GobletApiScraper, # See ticket #20
   #IfbRdfaScraper,
   #IntermineScraper,
   KhanAcademyApiScraper,
   LegacySoftwareCarpentryScraper,
   #LibraryCarpentryEventsScraper,
   LuxembourgRdfaScraper,
   #NbisEventsScraper,
   #NgsRegistryScraper,
   #OpenTargetJsonScraper,
   PortugalEventsScraper,
   #PraceEventsScraper,
   #RssScraper,
   SheffieldScraper,
   SibScraper,
   #SibEventsScraper,
   #SoftwareCarpentryEventsScraper,
   #IannEventsScraper,
   ScilifelabScraper,
   #WellcomeEventsScraper
]


options = { output_file: output, debug: false, verbose: false, offline: false, cache: false } # Live!
# options = { output_file: output, debug: true, verbose: true, offline: false, cache: true } # Testing

failed_scrapers = []

begin
  # Open log file
  log_file = File.open(log, 'w')
  begin
    dir = Pathname(File.dirname(__FILE__)).expand_path
    unless dir.join('email_config.yml').exist?
      FileUtils.cp(dir.join('email_config.example.yml'), dir.join('email_config.yml'))
    end
    email_config = YAML.load(open(dir.join('email_config.yml')))['email']
  rescue => e
    puts "Couldn't load email_config.yml:"
    raise e
  end

  scrapers.each do |scraper_class|
    log_file.puts "Running #{scraper_class}"
    exceptions = []
    begin
      scraper = scraper_class.new(options)
      scraper.run
      exceptions = scraper.exceptions
    rescue => e
      exceptions << e
    end
    failed_scrapers << [scraper_class, exceptions] if exceptions.any?
    exceptions.each do |exception|
      log_file.puts exception.message
      log_file.puts exception.backtrace.join("\n")
      log_file.puts
    end
  end

  if email && failed_scrapers.length > 0
    message = ''
    message << "From: #{email_config['from']}\n"
    message << "To: #{email_config['to']}\n"
    message << "Sender: #{email_config['sender']}\n" if email_config.key?('sender')
    message << "Subject: Scraper Failure (#{failed_scrapers.map { |e| e[0] }.join(', ')})\n"
    message << "\n"
    message << "It would seem that the following scrapers have failed to run:\n\n"
    failed_scrapers.each do |scraper_class, exceptions|
      message << "#{scraper_class}:\n"
      exceptions.each do |e|
        message << "  #{e.message}\n"
        e.backtrace.each do |t|
          message << "    #{t}\n"
        end
      end
    end
    message << "\n"

    begin
      Net::SMTP.start(email_config['server']) do |smtp|
        smtp.send_message message, email_config['from'], email_config['to']
      end
    rescue => e
      puts "Could not email: #{message} | #{e}"
    end
  end

  log_file.puts 'Done'
ensure
  log_file.close
end
