#!/bin/bash --login

if [ "$#" -eq 0 ];then
    echo "Usage: run_scrapers.sh <scraper_directory>"
	exit 0
else
    DIR=$1
fi

cd $DIR && bundle exec ruby run_scrapers.rb
