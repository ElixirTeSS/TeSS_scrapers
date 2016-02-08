#!/bin/bash

# TRAINING MATERIALS
ruby goblet_api_scraper.rb
#ruby goblet_scraper.rb # Old one
ruby genome3d_scraper.rb
ruby ebi_scraper.rb
ruby sib_scraper.rb
ruby bitsvib_scraper.rb
ruby legacy_software_carpentry_scraper.rb


# EVENTS
ruby csc_events_scraper.rb
ruby dtls_events.rb
ruby elixir_events_scraper.rb
ruby iann_events_uploader.rb

#NOT READY
#ruby bitsvib_event_scraper.rb

