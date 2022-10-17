require './lib/tess_scrapers'

options = { debug: true, verbose: true, offline: false, cache: true }

Object.const_get(ARGV[0]).new(options).run
