c=dlss-dev-drh-geo
d=/home/drh/dlss-dev-drh-geo
urlbase=http://sul-solr-a.stanford.edu/solr

cd $d || exit -1
java -cp "/usr/share/tomcat6/webapps/solr/WEB-INF/lib/*" \
  org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost 127.0.0.1:2181 \
  -confdir conf -confname $c \
  -solrhome /home/lyberadmin/solr-home


echo curl "$urlbase/admin/collections?action=CREATE&name=${c}&numShards=1&replicationFactor=3"

curl "$urlbase/admin/collections?action=RELOAD&name=${c}"

for fn in data/*.xml; do
  curl -X POST -H "Content-Type: text/xml" $urlbase/${c}/update" @$fn
done
