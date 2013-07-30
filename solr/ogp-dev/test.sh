#!/bin/bash
c=ogp-dev # collection
#h=localhost:8080            # tomcat
h=ogpapp-dev.stanford.edu  # httpd
#h=localhost:8983           # jetty
d=/var/geomdtk/current/workspace

# XXX: include HTTPS authentication

find -L "$d" -name 'ogpSolr.xml' | while read fn; do
  echo "Uploading $fn"
  curl  -X POST \
        -H 'Content-Type: text/xml' \
        --data-binary @- \
        "http://${h}/solr/${c}/update" \
        < "$fn"
done

curl "http://${h}/solr/${c}/update?commit=true"
curl "http://${h}/solr/${c}/update?optimize=true"

