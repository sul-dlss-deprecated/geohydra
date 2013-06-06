<?xml version="1.0" encoding="UTF-8"?>
<!-- Written by Darren Hardy <drh@stanford.edu>, DLSS, Stanford University Libraries -->
<xsl:stylesheet 
  xmlns:gco="http://www.isotc211.org/2005/gco" 
  xmlns:gmd="http://www.isotc211.org/2005/gmd" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  version="1.0"
  exclude-result-prefixes="gmd gco">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <xsl:template match="gmd:fileIdentifier">
    <field name="id">geonetwork:<xsl:value-of select="gco:CharacterString"/></field>
    <field name="uuid_ssi">geonetwork:<xsl:value-of select="gco:CharacterString"/></field>
  </xsl:template>
  
  <xsl:template match="gmd:identificationInfo">
    <xsl:for-each select="gmd:MD_DataIdentification">
      <xsl:for-each select="gmd:citation/gmd:CI_Citation">
        <field name="title_ssi">
            <xsl:value-of select="gmd:title/gco:CharacterString"/>
        </field>      
        <xsl:for-each select="gmd:citedResponsibleParty/gmd:CI_ResponsibleParty">
          <xsl:if test="gmd:role/gmd:CI_RoleCode[@codeListValue='originator']">
            <field name="publisher_ssi">
              <xsl:value-of select="gmd:organisationName/gco:CharacterString"/>
            </field>
            <field name="place_ssim">
                <xsl:value-of select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:city/gco:CharacterString"/>, <xsl:value-of select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:administrativeArea/gco:CharacterString"/>, <xsl:value-of select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:country/gmd:Country/@codeListValue"/>
            </field>
          </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="gmd:date/gmd:CI_Date"> 
          <xsl:if test="gmd:dateType/gmd:CI_DateTypeCode[@codeListValue='publication']">
            <field name="publication_dsi">
              <xsl:value-of select="gmd:date/gco:Date"/>
            </field>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    
      <xsl:for-each select="gmd:abstract|gmd:purpose">
        <field>
          <xsl:attribute name="name"><xsl:value-of select="local-name()"/>_tsi</xsl:attribute>
          <xsl:value-of select="gco:CharacterString"/>
        </field>
      </xsl:for-each>
    
      <xsl:for-each select="gmd:descriptiveKeywords/gmd:MD_Keywords">
          <xsl:choose>
            <xsl:when test="gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='theme']">
              <field name="subject_ssim">
                <xsl:value-of select="gmd:keyword/gco:CharacterString"/>
              </field>
            </xsl:when>
            <xsl:when test="gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']">
              <field name="place_ssim">
                <xsl:value-of select="gmd:keyword/gco:CharacterString"/>
              </field>
            </xsl:when>
            <xsl:otherwise>
              <field name="genre_ssim">
                <xsl:value-of select="gmd:keyword/gco:CharacterString"/>
              </field>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:for-each>
      
      <xsl:for-each select="gmd:topicCategory">
        <field name="genre_ssim">
          <xsl:value-of select="gmd:MD_TopicCategoryCode"/>
        </field>
      </xsl:for-each>
    
      <xsl:for-each select="gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox">
        <!-- A lat-lon rectangle can be indexed with 4 numbers in minX minY maxX maxY order:

             <field name="geo">-74.093 41.042 -69.347 44.558</field> 

          -->
        <field name="geo_bbox">
          <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/><xsl:text> </xsl:text>
          <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/><xsl:text> </xsl:text>
          <xsl:value-of select="gmd:eastBoundLongitude/gco:Decimal"/><xsl:text> </xsl:text>
          <xsl:value-of select="gmd:northBoundLatitude/gco:Decimal"/>
        </field>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="gmd:dataQualityInfo">
    <field name="provenance_tsi">
      <xsl:for-each select="gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/gmd:source/gmd:LI_Source">
        Source: 
        <xsl:value-of select="gmd:description/gco:CharacterString"/>.
        <xsl:value-of select="gmd:sourceCitation/gmd:CI_Citation/gmd:title/gco:CharacterString"/>.
        <xsl:value-of select="gmd:sourceCitation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date"/>.
        <xsl:value-of select="gmd:sourceCitation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode"/>.
      </xsl:for-each>
    </field>
    <field name="quality_tsi">
      <xsl:value-of select="gmd:DQ_DataQuality/gmd:report/gmd:DQ_QuantitativeAttributeAccuracy/gmd:evaluationMethodDescription/gco:CharacterString" />
    </field>
  </xsl:template>
  
  
  <xsl:template match="gmd:referenceSystemInfo">
    <xsl:for-each select="gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier">
      <field name="projection_ssi">
        <xsl:value-of select="gmd:codeSpace/gco:CharacterString"/>_<xsl:value-of select="gmd:code/gco:CharacterString"/>
      </field>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="/gmd:MD_Metadata">
    <add><doc>
      <field name="_version_">1</field>
      <xsl:apply-templates/>
    </doc></add>
  </xsl:template>

  <xsl:template match="gmd:distributionInfo">
    <field name="distribution_format_ssim">
      <xsl:value-of select="gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name/gco:CharacterString"/>
    </field>
  </xsl:template>
  
  <xsl:template match="*"/>

</xsl:stylesheet>
