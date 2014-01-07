#!/bin/bash -x
cat druids.log | while read purl; do
# purl=cg716wc7949
#xsltproc \
#	--stringparam geoserver_root http://kurma-podd1/geoserver \
#  	--stringparam purl $purl \
#  	--output out-$purl.xml \
#  	lib/geohydra/mods2ogp.xsl \
#	/var/geomdtk/current/workspace-prod/*/*/*/*/$purl/metadata/descMetadata.xml
xsltproc \
  	--output out/$purl.html \
	pacioos-iso-html.xsl \
	/var/geomdtk/current/workspace-prod/*/*/*/*/$purl/metadata/geoMetadata.xml
done
# open out/$purl.html
