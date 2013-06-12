#!/bin/bash -x
c=dlss-dev-drh-geo  # collection
h=localhost:8983    # jetty
# h=localhost:8080  # tomcat
for f in example*.xml; do
  curl  -X POST \
        -H 'Content-Type: text/xml' \
	      --data-binary @$f \
	      "http://${h}/solr/${c}/update?commit=true"
done
