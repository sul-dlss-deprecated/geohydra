#!/bin/bash -x
c=ogp
d=/var/geomdtk/current/workspace
h=localhost:8080
s=http

find -L "$d" -name 'ogpSolr.xml' | while read fn; do
  echo "Uploading $fn"
  curl  -X POST \
        -H 'Content-Type: text/xml' \
        --data-binary "@$fn" \
        "$s://${h}/solr/${c}/update"
  curl "$s://${h}/solr/${c}/update?commit=true"
done
curl "$s://${h}/solr/${c}/update?optimize=true"

