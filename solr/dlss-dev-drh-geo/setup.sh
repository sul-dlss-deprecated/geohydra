find -L tmp -name '*_iso19139.xml' | while read fn; do
	xsltproc lib/gmd2solr.xslt $fn > "data/$(basename $fn _iso19139.xml | tr A-Z a-z).xml"
done
