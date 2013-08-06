<?xml version="1.0"?>
<xsl:stylesheet xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gmd="http://www.isotc211.org/2005/gmd" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <xsl:text>{</xsl:text>
    <xsl:choose>
      <xsl:when test="//gmd:CI_OnlineResource">
        <xsl:apply-templates select="//gmd:CI_OnlineResource"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>"druid" : "</xsl:text>
        <xsl:variable name="druid"/>
        <xsl:value-of select="$druid"/>
        <xsl:text>", </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="//gmd:RS_Identifier"/>
    <xsl:text>"version" : 1 }</xsl:text>
  </xsl:template>
  <xsl:template match="//gmd:CI_OnlineResource">
    <xsl:text>"druid" : "</xsl:text>
    <xsl:value-of select="substring-after(.//gmd:URL/text(), 'http://purl.stanford.edu/')"/>
    <xsl:text>", "filename" : "</xsl:text>
    <xsl:value-of select="substring-before(.//gmd:name/gco:CharacterString/text(), '.shp')"/>
    <xsl:text>",</xsl:text>
  </xsl:template>
  <xsl:template match="//gmd:RS_Identifier">
    <xsl:text>"crs" : "</xsl:text>
    <xsl:copy-of select=".//gmd:codeSpace/gco:CharacterString/text()"/>
    <xsl:text>:</xsl:text>
    <xsl:copy-of select=".//gmd:code/gco:CharacterString/text()"/>
    <xsl:text>",
</xsl:text>
  </xsl:template>
</xsl:stylesheet>
