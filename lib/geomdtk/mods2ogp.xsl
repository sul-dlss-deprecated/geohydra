<?xml version="1.0" encoding="UTF-8"?>
<!-- 
     mods2ogp.xsl - Transforms MODS with GML extensions into an OGP Solr document
     
     Copyright 2013, Stanford University Libraries.
     
     Created by Darren Hardy.

     For OGP Solr schema, see:

       https://github.com/OpenGeoportal/ogpSolrConfig/blob/master/ogpSolrConfig/SolrConfig/schema.xml
       
       
     Requires parameters:
       
       - geoserver_root - URL prefix to the geoserver
       - stacks_root - URL prefix to the stacks
       - purl - complete URL with aa111bb1111 (len = 11)
       
     -->
<xsl:stylesheet xmlns="http://lucene.apache.org/solr/4/document" xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gmd="http://www.isotc211.org/2005/gmd" xmlns:gml="http://www.opengis.net/gml/3.2" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0" exclude-result-prefixes="gmd gco gml mods rdf xsl">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/mods:mods">
    <xsl:variable name="druid" 
      select="substring($purl, string-length($purl)-10)" />
    <xsl:variable name="filename" select="mods:extension[@rdf:type='geo']/rdf:RDF/rdf:Description[@rdf:type='geo#filename']/text()"/>
    <xsl:variable name="downloadURL">
      <xsl:value-of select="$stacks_root"/>
      <xsl:value-of select="concat('/',$druid)"/>
      <xsl:text>/content/</xsl:text>
      <xsl:value-of select="substring-before($filename, '.shp')"/>
      <xsl:text>.zip</xsl:text>
    </xsl:variable>
    <!-- XXX: Use Xpointer on geoMetadata to extract -->
    <xsl:variable name="metadataURL">
      <xsl:value-of select="$stacks_root"/>
      <xsl:value-of select="concat('/',$druid)"/>
      <xsl:text>/metadata/geoMetadata.xml</xsl:text>
    </xsl:variable>
    <xsl:variable name="localMetadataURL">
      <xsl:text>file:///var/geomdtk/current/export</xsl:text>
      <xsl:value-of select="concat('/',$druid)"/>
      <xsl:text>/metadata/geoMetadata.xml</xsl:text>
    </xsl:variable>
    <add>
      <doc>
        <field name="LayerId">
          <xsl:value-of select="$druid"/>
        </field>
        <field name="Name">
          <xsl:value-of select="$druid"/>
        </field>
        <field name="ExternalLayerId">
          <xsl:value-of select="$purl"/>
        </field>
        <xsl:comment>
          XXX: Access is really Stanford-only but UI is not defaulted to search for restricted
        </xsl:comment>
        <field name="Access">
          <xsl:text>Restricted</xsl:text>
        </field>
        <field name="Institution">
          <xsl:text>Stanford</xsl:text>
        </field>
        <field name="WorkspaceName">
          <xsl:text>druid</xsl:text>
        </field>
        <field name="GeoReferenced">
          <xsl:text>true</xsl:text>
        </field>
        <field name="Availability">
          <xsl:text>Online</xsl:text>
        </field>
        <field name="ContentDate">
          <!-- year only -->
          <xsl:value-of select="substring(mods:originInfo/mods:dateIssued/text(), 0, 5)"/>
          <xsl:text>-01-01T00:00:00Z</xsl:text>
        </field>
        <field name="LayerDisplayName">
          <xsl:value-of select="mods:titleInfo/mods:title[@type='main']/text()"/>
        </field>
        <xsl:if test="mods:physicalDescription/mods:form[text() = 'Shapefile']">
          <field name="DataType">
            <xsl:value-of select="substring-after(mods:extension[@rdf:type='geo']/rdf:RDF/rdf:Description[@rdf:type='geo#geometryType']/text(), 'gml:')"/>
          </field>
        </xsl:if>
        <xsl:for-each select="mods:name[mods:role/mods:roleTerm/text()='Publisher']">
          <field name="Publisher">
            <xsl:value-of select="mods:namePart/text()"/>
          </field>
        </xsl:for-each>
        <field name="Abstract">
          <xsl:for-each select="mods:abstract[@displayLabel='abstract' or @displayLabel='purpose']/text()">
            <xsl:value-of select="."/>
            <xsl:text>; </xsl:text>
          </xsl:for-each>
        </field>
        <field name="ThemeKeywords">
          <xsl:for-each select="mods:subject/mods:topic">
            <xsl:value-of select="text()"/>
            <xsl:text>; </xsl:text>
          </xsl:for-each>
        </field>
        <field name="PlaceKeywords">
          <xsl:for-each select="mods:subject/mods:geographic">
            <xsl:value-of select="text()"/>
            <xsl:text>; </xsl:text>
          </xsl:for-each>
        </field>
        <xsl:for-each select="mods:extension[@rdf:type='geo']/rdf:RDF/rdf:Description[@rdf:type='geo#boundingBox']/gml:Envelope">
          <xsl:variable name="x2" select="number(substring-before(gml:upperCorner/text(), ' '))"/>
          <xsl:variable name="x1" select="number(substring-before(gml:lowerCorner/text(), ' '))"/>
          <xsl:variable name="y2" select="number(substring-after(gml:upperCorner/text(), ' '))"/>
          <xsl:variable name="y1" select="number(substring-after(gml:lowerCorner/text(), ' '))"/>
          <field name="MinX">
            <xsl:value-of select="$x1"/>
          </field>
          <field name="MinY">
            <xsl:value-of select="$y1"/>
          </field>
          <field name="MaxX">
            <xsl:value-of select="$x2"/>
          </field>
          <field name="MaxY">
            <xsl:value-of select="$y2"/>
          </field>
          <field name="CenterX">
            <!-- XXX: doesn't work across meridian -->
            <xsl:value-of select="($x2 - $x1) div 2 + $x1"/>
          </field>
          <field name="CenterY">
            <xsl:value-of select="($y2 - $y1) div 2 + $y1"/>
          </field>
          <xsl:comment> XXX: in degrees ??? </xsl:comment>
          <field name="HalfWidth">
            <xsl:value-of select="($x2 - $x1) div 2"/>
          </field>
          <xsl:comment> XXX: in degrees ??? </xsl:comment>
          <field name="HalfHeight">
            <xsl:value-of select="($y2 - $y1) div 2"/>
          </field>
          <xsl:comment> XXX: in degrees**2 ??? </xsl:comment>
          <field name="Area">
            <xsl:value-of select="round(($y2 - $y1) * ($x2 - $x1))"/>
          </field>
          <field name="SrsProjectionCode">
            <xsl:value-of select="@srsName"/>
          </field>
        </xsl:for-each>
        <field name="Location">
          <xsl:text>
              { 
              "wms":       ["</xsl:text>
          <xsl:value-of select="$geoserver_root"/>
          <xsl:text>/wms"],
              "tilecache": ["</xsl:text>
          <xsl:value-of select="$geoserver_root"/>
          <xsl:text>/wms"],
              "wfs":       ["</xsl:text>
          <xsl:value-of select="$geoserver_root"/>
          <xsl:text>/wfs"],
              "metadata":  ["</xsl:text>
          <xsl:value-of select="$metadataURL"/>
          <xsl:text>"],
              "download":  ["</xsl:text>
          <xsl:value-of select="$downloadURL"/>
          <xsl:text>"],
              "view":      ["</xsl:text>
          <xsl:value-of select="$purl"/>
          <xsl:text>"]              
              }
          </xsl:text>
        </field>
        <field name="FgdcText">
          <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" parse="xml" xpointer="xmlns(gmd=http://www.isotc211.org/2005/gmd)xpointer(//gmd:MD_Metadata)">
            <xsl:attribute name="href">
              <xsl:value-of select="$localMetadataURL"/>
            </xsl:attribute>
          </xi:include>
        </field>
      </doc>
    </add>
  </xsl:template>
  <xsl:template match="*"/>
</xsl:stylesheet>
