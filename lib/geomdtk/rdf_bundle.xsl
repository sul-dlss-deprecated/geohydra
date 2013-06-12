<?xml version="1.0" encoding="UTF-8"?>
<!-- 
     rdf_bundle.xsl - Bundles ISO 19139 XML metadata into RDF geoMetadata
     
     Copyright 2013, Stanford University Libraries.
     
     Created by Darren Hardy.
     -->
<xsl:stylesheet xmlns:gfc="http://www.isotc211.org/2005/gfc" xmlns:gmd="http://www.isotc211.org/2005/gmd" xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" exclude-result-prefixes="xsl gmd gfc gco">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <xsl:variable name="purl" select="/gmd:MD_Metadata/gmd:dataSetURI/gco:CharacterString/text()"/>
    <rdf:RDF>
      <rdf:Description>
        <xsl:attribute name="rdf:about">
          <xsl:value-of select="$purl"/>
        </xsl:attribute>
        <rdf:Description>
          <xsl:attribute name="rdf:about">
            <xsl:value-of select="$purl"/>
            <xsl:text>#geoMetadata/MD_Metadata</xsl:text>
          </xsl:attribute>
          <xsl:apply-templates select="//gmd:MD_Metadata"/>
        </rdf:Description>
        <rdf:Description>
          <xsl:attribute name="rdf:about">
            <xsl:value-of select="$purl"/>
            <xsl:text>#geoMetadata/FC_FeatureCatalogue</xsl:text>
          </xsl:attribute>
          <xsl:apply-templates select="//gfc:FC_FeatureCatalogue"/>
        </rdf:Description>
      </rdf:Description>
    </rdf:RDF>
  </xsl:template>
  <xsl:template match="gmd:MD_Metadata|gfc:FC_FeatureCatalogue">
    <xsl:copy-of select="."/>
  </xsl:template>
</xsl:stylesheet>
