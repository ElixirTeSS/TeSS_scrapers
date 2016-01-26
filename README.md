Install all depending gems for tessdata gem listed in tessdata/lib/tess_api.rb. For example:


`gem install inifile`


`gem install net/http`


...

Then install the tessdata gem from the root directory:


`sh build.sh`

From the root directory copy the example_uploader_config.txt into uploader_config.txt and configure to suit your environment.

Run scraper with:


`ruby scraper_name.rb`

