<xsl:stylesheet xmlns="http://lucene.apache.org/solr/4/document" xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gmd="http://www.isotc211.org/2005/gmd" xmlns:gml="http://www.opengis.net/gml/3.2" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0" exclude-result-prefixes="gmd gco gml mods rdf xsl">
  <xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:template match="*">
    <xsl:apply-templates select="//gmd:CI_OnlineResource"/>
  </xsl:template>
  <xsl:template match="//gmd:CI_OnlineResource">
     <xsl:copy-of select="substring-after(.//gmd:URL/text(), 'http://purl.stanford.edu/')"/>
     <xsl:text>,</xsl:text>
     <xsl:copy-of select="substring-before(.//gmd:name/gco:CharacterString/text(), '.shp')"/>
     <xsl:text>
</xsl:text>
  </xsl:template>
</xsl:stylesheet>
