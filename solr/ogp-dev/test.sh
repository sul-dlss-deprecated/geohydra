#!/bin/bash
c=ogp-dev # collection
h=ogpapp-dev.stanford.edu    # ogpdev
#h=localhost:8983    # jetty
# h=localhost:8080  # tomcat
find -L /var/geomdtk/current/workspace -name 'ogp*.xml' | while read f; do
  echo "Uploading $f /solr/${c}/update"
  curl  -X POST \
        -H 'Content-Type: text/xml' \
	      --data-binary @$f \
	      "http://${h}/solr/${c}/update?commit=true"
done

curl "http://${h}/solr/${c}/update?commit=true"
curl "http://${h}/solr/${c}/update?optimize=true"

