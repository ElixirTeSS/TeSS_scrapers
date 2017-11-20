require './lib/tess_scrapers'

options = { debug: true, verbose: true, offline: false, cache: true }

ARGV[0].constantize.new(options).run
