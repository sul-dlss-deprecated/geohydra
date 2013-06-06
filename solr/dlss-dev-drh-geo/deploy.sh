#!/bin/bash
c=dlss-dev-drh-geo-jun6
d=/home/drh/dlss-dev-drh-geo
cd $d/conf || exit -1

java -cp "/usr/share/tomcat6/webapps/solr/WEB-INF/lib/*" \
  org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost 127.0.0.1:2181 \
  -confdir . -confname $c \
  -solrhome /home/lyberadmin/solr-home

set -x
curl "http://sul-solr-a.stanford.edu/solr/admin/collections?action=DELETE&name=${c}"
sleep 5
curl "http://sul-solr-a.stanford.edu/solr/admin/collections?action=CREATE&name=${c}&numShards=1&replicationFactor=3"
