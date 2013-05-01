rm content.xml
for fn in ../../tmp/iso/*.xml; do
	xsltproc lib/gmd2solr.xslt $fn | tail -n +2 >> content.xml
done
