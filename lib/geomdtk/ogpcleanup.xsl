<?xml version="1.0" encoding="UTF-8"?>
<!-- 
     ogpcleanup.xsl - Fix FgdcText so that XML is properly escaped
     
     Copyright 2013, Stanford University Libraries.
     
     Created by Darren Hardy.
     -->
<xsl:stylesheet xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://lucene.apache.org/solr/4/document" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:solr="http://lucene.apache.org/solr/4/document" version="1.0" exclude-result-prefixes="xi xsl rdf solr">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <add>
      <doc>
        <xsl:for-each select="/solr:add/solr:doc/solr:field[not(@name='FgdcText')]">
          <xsl:copy-of select="."/>
        </xsl:for-each>
        <xsl:for-each select="/solr:add/solr:doc/solr:field[(@name='FgdcText')]">
          <field name="FgdcText">
            <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
            <xsl:copy-of select="*"/>
            <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
          </field>
        </xsl:for-each>
      </doc>
    </add>
  </xsl:template>
</xsl:stylesheet>
