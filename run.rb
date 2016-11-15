require './lib/tess_scrapers'

log = 'log/scrapers.log'
output = 'log/scrapers.out' # Need to logrotate this!

options = { output_file: output, debug: false, verbose: false, offline: false, cache: false } # Live!
# options = { output_file: output, debug: true, verbose: true, offline: false, cache: true } # Testing

if !ARGV[0]
  puts 'Provide name of scraper as argument. e.g. RssScraper'
else 
  scraper_class = ARGV[0]
  begin
    # Open log file
    log_file = File.open(log, 'w')
    log_file.puts "Running #{scraper_class}"
    scraper_class.constantize.new(options).run
    log_file.puts 'Done'
  ensure
    log_file.close
  end
end
