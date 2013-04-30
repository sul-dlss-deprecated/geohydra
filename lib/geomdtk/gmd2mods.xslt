<?xml version="1.0" encoding="UTF-8"?>
<!-- Written by Darren Hardy <drh@stanford.edu>, DLSS, Stanford University Libraries -->
<xsl:stylesheet 
  xmlns:gco="http://www.isotc211.org/2005/gco" 
  xmlns:gmd="http://www.isotc211.org/2005/gmd" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns="http://www.loc.gov/mods/v3" 
  version="1.0"
  exclude-result-prefixes="gmd gco">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <xsl:template match="gmd:fileIdentifier">
      <identifier type="local" displayLabel="reference_id">geonetwork:<xsl:value-of select="gco:CharacterString"/>
      </identifier>
  </xsl:template>
  
  <xsl:template match="gmd:identificationInfo">
    <xsl:for-each select="gmd:MD_DataIdentification">
      <xsl:for-each select="gmd:citation/gmd:CI_Citation">
        <titleInfo type="main">
          <title>
            <xsl:value-of select="gmd:title/gco:CharacterString"/>
          </title>
        </titleInfo>      
        <originInfo>
          <xsl:for-each select="gmd:citedResponsibleParty/gmd:CI_ResponsibleParty">
            <xsl:if test="gmd:role/gmd:CI_RoleCode[@codeListValue='originator']">
              <publisher>
                <xsl:value-of select="gmd:organisationName/gco:CharacterString"/>
              </publisher>
              <place>
                <placeTerm type="text">
                  <xsl:value-of select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:city/gco:CharacterString"/>, <xsl:value-of select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:administrativeArea/gco:CharacterString"/>, <xsl:value-of select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:country/gmd:Country/@codeListValue"/>
                </placeTerm>
              </place>
            </xsl:if>
          </xsl:for-each>
          <xsl:for-each select="gmd:date/gmd:CI_Date"> 
            <xsl:if test="gmd:dateType/gmd:CI_DateTypeCode[@codeListValue='publication']">
              <dateCreated encoding="w3cdtf">
                <xsl:value-of select="gmd:date/gco:Date"/>
              </dateCreated>
            </xsl:if>
          </xsl:for-each>
        </originInfo>
      </xsl:for-each>
    
      <xsl:for-each select="gmd:abstract|gmd:purpose">
        <note>
          <xsl:attribute name="displayLabel"><xsl:value-of select="local-name()"/>
          </xsl:attribute>
          <xsl:value-of select="gco:CharacterString"/></note>
      </xsl:for-each>
    
      <xsl:for-each select="gmd:descriptiveKeywords/gmd:MD_Keywords">
        <subject>
          <xsl:choose>
            <xsl:when test="gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='theme']">
              <topic>
                <xsl:value-of select="gmd:keyword/gco:CharacterString"/>
              </topic>
            </xsl:when>
            <xsl:when test="gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']">
              <geographic>
                <xsl:value-of select="gmd:keyword/gco:CharacterString"/>
              </geographic>
            </xsl:when>
            <xsl:otherwise>
              <genre>
                <xsl:value-of select="gmd:keyword/gco:CharacterString"/>
              </genre>
            </xsl:otherwise>
          </xsl:choose>
        </subject>
      </xsl:for-each>
      
      <xsl:for-each select="gmd:topicCategory">
        <genre>
          <xsl:value-of select="gmd:MD_TopicCategoryCode"/>
        </genre>
      </xsl:for-each>
    
      <xsl:for-each select="gmd:resourceConstraints/gmd:MD_Constraints">
        <note displayLabel="Use limitation">
          <xsl:value-of select="gmd:useLimitation/gco:CharacterString"/>
        </note>
      </xsl:for-each>

      <xsl:for-each select="gmd:resourceConstraints/gmd:MD_LegalConstraints">
        <note displayLabel="Legal constraints">
          Access: <xsl:value-of select="gmd:accessConstraints/gmd:MD_RestrictionCode"/>.
          Use: <xsl:value-of select="gmd:useConstraints/gmd:MD_RestrictionCode"/>.
        </note>
      </xsl:for-each>
      
      <xsl:for-each select="gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox">
        <subject>
          <cartographic>
            <coordinates>
              <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/> --
              <xsl:value-of select="gmd:eastBoundLongitude/gco:Decimal"/>,
              <xsl:value-of select="gmd:northBoundLatitude/gco:Decimal"/> --
              <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/>
            </coordinates>
          </cartographic>
        </subject>    
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="gmd:dataQualityInfo">
    <note displayLabel="provenance">
      <xsl:for-each select="gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/gmd:source/gmd:LI_Source">
        Source: 
        <xsl:value-of select="gmd:description/gco:CharacterString"/>.
        <xsl:value-of select="gmd:sourceCitation/gmd:CI_Citation/gmd:title/gco:CharacterString"/>.
        <xsl:value-of select="gmd:sourceCitation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date"/>.
        <xsl:value-of select="gmd:sourceCitation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode"/>.
      </xsl:for-each>
    </note>
    <note displayLabel="quality">
      <xsl:value-of select="gmd:DQ_DataQuality/gmd:report/gmd:DQ_QuantitativeAttributeAccuracy/gmd:evaluationMethodDescription/gco:CharacterString" />
    </note>
  </xsl:template>
  
  
  <xsl:template match="gmd:referenceSystemInfo">
    <xsl:for-each select="gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier">
      <identifier type="local" displayLabel="projection_id">
        <xsl:value-of select="gmd:codeSpace/gco:CharacterString"/>_<xsl:value-of select="gmd:code/gco:CharacterString"/>
      </identifier>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="/gmd:MD_Metadata">
    <mods>
      <xsl:apply-templates/>
      <genre>GIS Datasets</genre>
    </mods>
  </xsl:template>

  <xsl:template match="gmd:distributionInfo">
    <identifier type="local" displayLabel="distribution_format">
      <xsl:value-of select="gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name/gco:CharacterString"/>
    </identifier>
  </xsl:template>
  
  <xsl:template match="*"/>

<!-- XXXXXXXXXXXXXXXXXXXXX
  <xsl:template match="/XXX">
    <subject>
      <cartographics>
        <scale>XXX</scale>
      </cartographics>
    </subject>
    <subject>
      <geographicCode authority="marcgac">XXX</geographicCode>
    </subject>
    <subject>
      <geographic authority="marcgac">XXX</geographic>
    </subject>
    <subject>
      <geographic authority="lcsh">XXX</geographic>
    </subject>
    <subject>
      <temporal authority="w3cdtf">2000</temporal>
    </subject>
    <typeOfResource>cartographic</typeOfResource>
    <name type="personal">
      <namePart>XXX</namePart>
      <role>
        <roleTerm type="code" authority="marcrelator">ctg</roleTerm>
        <roleTerm type="text" authority="marcrelator">Cartographer</roleTerm>
      </role>
    </name>
    <note displayLabel="LOCAL_NOTES">XXX</note>
    <genre>map</genre>
    <genre>Digital maps</genre>
  </xsl:template> -->
</xsl:stylesheet>
