for fn in ../../tmp/iso/*.shp.xml; do
	xsltproc lib/gmd2solr.xslt $fn > data/`basename $fn | tr A-Z a-z`
done
