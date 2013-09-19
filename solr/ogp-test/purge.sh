#!/bin/bash -x
c=ogp-test
d=/var/geomdtk/current/workspace
h=localhost:28080
s=http

curl "$s://${h}/solr/${c}/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl "$s://${h}/solr/${c}/update?commit=true"

