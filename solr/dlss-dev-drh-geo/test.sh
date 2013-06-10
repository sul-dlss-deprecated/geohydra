#!/bin/bash -x
c=dlss-dev-drh-geo-201306_shard1_replica1
curl -X POST -H 'Content-Type: text/xml' \
	--data-binary @example_doc.xml \
	"http://localhost:8080/solr/${c}/update?commit=true"