#!/usr/bin/env bash

core_site_template=pio-engine/PredictionIO-dist/conf/core-site.xml.erb
elasticsearch_template=pio-engine/PredictionIO-dist/conf/elasticsearch.yml.erb

if [ -f "$core_site_template" ]
then
  erb $core_site_template > pio-engine/PredictionIO-dist/conf/core-site.xml
fi

if [ -f "$elasticsearch_template" ]
then
  erb $elasticsearch_template > pio-engine/PredictionIO-dist/conf/elasticsearch.yml
fi