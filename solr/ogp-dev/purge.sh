#!/bin/bash -x
c=ogp-dev
h=localhost:18080
s=http

curl "$s://${h}/solr/${c}/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl "$s://${h}/solr/${c}/update?commit=true"

