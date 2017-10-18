require_relative 'lib/tess_scrapers'

log = 'log/scrapers.log'
output = 'log/scrapers.out' # Need to logrotate this!

scrapers = [
   BiocompRdfaScraper,
   BitsvibEventsJsonldScraper,
   BitsvibRdfaScraper,
   BmtcJsonldScraper,
   CambridgeEventsScraper,
   CourseraScraper,
   CscEventsScraper,
   DataCarpentryScraper,
   DenbiScraper,
   DtlsEventsScraper,
  # EbiScraper, # Broken old materials one
   EbiJsonScraper,
   ElixirEventsScraper,
   ErasysRdfaScraper,
   FlemishJsonldEventsScraper,
   FuturelearnRdfaScraper,
   GalaxyScraper,
   Genome3dScraper,
   GobletRdfaScraper,
   IfbRdfaScraper,
   KhanAcademyApiScraper,
   LegacySoftwareCarpentryScraper,
   NbisEventsScraper,
   NgsRegistryScraper,
   PortugalEventsScraper,
   PraceEventsScraper,
   RssScraper,
   SibScraper,
   SibEventsScraper,
   SoftwareCarpentryEventsScraper,
# IannEventsScraper,
   ScilifelabScraper,
   BiviMaterialScraper,
   BiviEventScraper
]

options = { output_file: output, debug: false, verbose: false, offline: false, cache: false } # Live!
#options = { output_file: output, debug: true, verbose: true, offline: false, cache: true } # Testing

begin
  # Open log file
  log_file = File.open(log, 'w')

  scrapers.each do |scraper_class|
    log_file.puts "Running #{scraper_class}"
    begin
      scraper_class.new(options).run
    rescue => e
      log_file.puts e.message
      log_file.puts e.backtrace.join("\n")
    end
  end

  log_file.puts 'Done'
ensure
  log_file.close
end
