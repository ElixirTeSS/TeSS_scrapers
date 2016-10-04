#!/bin/bash

# TRAINING MATERIALS
ruby scrapers/goblet_api_scraper.rb
#ruby scrapers/goblet_scraper.rb # Old one
ruby scrapers/genome3d_scraper.rb
ruby scrapers/ebi_scraper.rb
ruby scrapers/sib_scraper.rb
ruby scrapers/bitsvib_scraper.rb
ruby scrapers/legacy_software_carpentry_scraper.rb


# EVENTS
ruby scrapers/csc_events_scraper.rb
ruby scrapers/dtls_events.rb
ruby scrapers/elixir_events_scraper.rb
ruby scrapers/iann_events_uploader.rb

#NOT READY
#ruby scrapers/bitsvib_event_scraper.rb

