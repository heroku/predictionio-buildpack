#!/usr/bin/env bash

core_site_template=/app/pio-engine/PredictionIO-dist/conf/core-site.xml.erb
elasticsearch_template=/app/pio-engine/PredictionIO-dist/conf/elasticsearch.yml.erb

if [ -f "$core_site_template" ]
then
  erb $core_site_template > /app/pio-engine/PredictionIO-dist/conf/core-site.xml
  erb $elasticsearch_template > /app/pio-engine/PredictionIO-dist/conf/elasticsearch.yml
fi
