#!/bin/bash -x
export PATH=/usr/bin:/bin
c=ogp-dev

if [ "$(hostname)" != 'sul-solr-a.stanford.edu' ]; then
	echo "Wrong host"
	exit -1
fi

cd /home/drh/geohydra/solr/$c/conf || exit -1
java -cp "/usr/share/tomcat6/webapps/solr/WEB-INF/lib/*:/usr/share/tomcat6/lib/*" \
  org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost 127.0.0.1:2181 \
  -confdir . -confname $c \
  -solrhome /home/lyberadmin/solr-home

