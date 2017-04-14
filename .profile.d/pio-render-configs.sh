#!/usr/bin/env bash

core_site_template=pio-engine/PredictionIO-dist/conf/core-site.xml.erb

if [ -f "$core_site_template" ]
then
  erb $core_site_template > pio-engine/PredictionIO-dist/conf/core-site.xml
fi
