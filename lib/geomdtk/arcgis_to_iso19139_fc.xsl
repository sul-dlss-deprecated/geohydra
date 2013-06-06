<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gfc="http://www.isotc211.org/2005/gfc" xmlns:gmd="http://www.isotc211.org/2005/gmd" version="1.0">
  <xsl:output method="xml" encoding="utf-8" indent="yes"/>
  <xsl:template match="metadata">
    <gfc:FC_FeatureCatalogue xmlns="http://www.isotc211.org/2005/gfc" xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gfc="http://www.isotc211.org/2005/gfc" xmlns:gmd="http://www.isotc211.org/2005/gmd" xmlns:gml="http://www.opengis.net/gml/3.2" xmlns:gmx="http://www.isotc211.org/2005/gmx" xmlns:gsr="http://www.isotc211.org/2005/gsr" xmlns:gss="http://www.isotc211.org/2005/gss" xmlns:gts="http://www.isotc211.org/2005/gts" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.isotc211.org/2005/gfc http://www.isotc211.org/2005/gfc/gfc.xsd">
      <gmx:name>
        <gco:CharacterString>
          <xsl:text>Feature Catalog for </xsl:text>
          <xsl:value-of select="idinfo//title"/>
        </gco:CharacterString>
      </gmx:name>
      <xsl:for-each select="idinfo/keywords/theme/themekey">
        <gmx:scope>
          <gco:CharacterString>
            <xsl:value-of select="."/>
          </gco:CharacterString>
        </gmx:scope>
      </xsl:for-each>
      <!--
			<xsl:for-each select="dataIdInfo/searchKeys/keyword">
				<gmx:scope>
					<gco:CharacterString>
						<xsl:value-of select="."/>
					</gco:CharacterString>
				</gmx:scope>
			</xsl:for-each> -->
      <gmx:versionNumber>
        <xsl:attribute name="gco:nilReason">unknown</xsl:attribute>
      </gmx:versionNumber>
      <gmx:versionDate>
        <xsl:choose>
          <xsl:when test="idinfo/citation/citeinfo/pubdate">
            <xsl:value-of select="idinfo/citation/citeinfo/pubdate"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="gco:nilReason">unknown</xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
      </gmx:versionDate>
      <gmx:language>
        <gco:CharacterString>
          <xsl:value-of select="'eng; US'"/>
        </gco:CharacterString>
      </gmx:language>
      <gmx:characterSet>
        <gmd:MD_CharacterSetCode>
          <xsl:attribute name="codeList">
            <xsl:value-of select="'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_CharacterSetCode'"/>
          </xsl:attribute>
          <xsl:attribute name="codeListValue">
            <xsl:value-of select="'utf-8'"/>
          </xsl:attribute>
          <xsl:attribute name="codeSpace">
            <xsl:value-of select="'ISOTC211/19115'"/>
          </xsl:attribute>
        </gmd:MD_CharacterSetCode>
      </gmx:characterSet>
      <gfc:producer>
        <gmd:CI_ResponsibleParty>
          <xsl:for-each select="metainfo/metc/cntinfo/cntorgp">
            <xsl:choose>
              <xsl:when test="cntorg">
                <gmd:organisationName>
                  <gco:CharacterString>
                    <xsl:for-each select="cntorg">
                      <xsl:value-of select="."/>
                    </xsl:for-each>
                  </gco:CharacterString>
                </gmd:organisationName>
              </xsl:when>
              <xsl:otherwise>
                <gmd:individualName>
                  <gco:CharacterString>
                    <xsl:for-each select="cntper">
                      <xsl:value-of select="."/>
                    </xsl:for-each>
                  </gco:CharacterString>
                </gmd:individualName>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
          <xsl:for-each select="metainfo/metc/cntinfo/cntpos">
            <gmd:positionName>
              <gco:CharacterString>
                <xsl:value-of select="."/>
              </gco:CharacterString>
            </gmd:positionName>
          </xsl:for-each>
          <gmd:contactInfo>
            <gmd:CI_Contact>
              <gmd:phone>
                <gmd:CI_Telephone>
                  <xsl:for-each select="metainfo/metc/cntinfo/cntvoice">
                    <gmd:voice>
                      <gco:CharacterString>
                        <xsl:value-of select="."/>
                      </gco:CharacterString>
                    </gmd:voice>
                  </xsl:for-each>
                  <xsl:for-each select="metainfo/metc/cntinfo/cntfax">
                    <gmd:facsimile>
                      <gco:CharacterString>
                        <xsl:value-of select="."/>
                      </gco:CharacterString>
                    </gmd:facsimile>
                  </xsl:for-each>
                </gmd:CI_Telephone>
              </gmd:phone>
              <gmd:address>
                <gmd:CI_Address>
                  <xsl:for-each select="metainfo/metc/cntinfo/cntaddr/address">
                    <gmd:deliveryPoint>
                      <gco:CharacterString>
                        <xsl:value-of select="."/>
                      </gco:CharacterString>
                    </gmd:deliveryPoint>
                  </xsl:for-each>
                  <xsl:for-each select="metainfo/metc/cntinfo/cntaddr/city">
                    <gmd:city>
                      <gco:CharacterString>
                        <xsl:value-of select="."/>
                      </gco:CharacterString>
                    </gmd:city>
                  </xsl:for-each>
                  <xsl:for-each select="metainfo/metc/cntinfo/cntaddr/state">
                    <gmd:administrativeArea>
                      <gco:CharacterString>
                        <xsl:value-of select="."/>
                      </gco:CharacterString>
                    </gmd:administrativeArea>
                  </xsl:for-each>
                  <xsl:for-each select="metainfo/metc/cntinfo/cntaddr/postal">
                    <gmd:postalCode>
                      <gco:CharacterString>
                        <xsl:value-of select="."/>
                      </gco:CharacterString>
                    </gmd:postalCode>
                  </xsl:for-each>
                  <xsl:for-each select="metainfo/metc/cntinfo/cntaddr/country">
                    <gmd:country>
                      <gco:CharacterString>
                        <xsl:value-of select="."/>
                      </gco:CharacterString>
                    </gmd:country>
                  </xsl:for-each>
                  <xsl:for-each select="metainfo/metc/cntinfo/cntemail">
                    <gmd:electronicMailAddress>
                      <gco:CharacterString>
                        <xsl:value-of select="."/>
                      </gco:CharacterString>
                    </gmd:electronicMailAddress>
                  </xsl:for-each>
                </gmd:CI_Address>
              </gmd:address>
              <xsl:for-each select="metainfo/metc/cntinfo/hours">
                <gmd:hoursOfService>
                  <gco:CharacterString>
                    <xsl:value-of select="."/>
                  </gco:CharacterString>
                </gmd:hoursOfService>
              </xsl:for-each>
              <xsl:for-each select="metainfo/metc/cntinfo/cntinst">
                <gmd:contactInstructions>
                  <gco:CharacterString>
                    <xsl:value-of select="."/>
                  </gco:CharacterString>
                </gmd:contactInstructions>
              </xsl:for-each>
            </gmd:CI_Contact>
          </gmd:contactInfo>
          <gmd:role>
            <gmd:CI_RoleCode>
              <xsl:attribute name="codeList">
                <xsl:value-of select="'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#CI_RoleCode'"/>
              </xsl:attribute>
              <xsl:attribute name="codeListValue">
                <xsl:value-of select="'resourceProvider'"/>
              </xsl:attribute>
              <xsl:attribute name="codeSpace">
                <xsl:value-of select="'001'"/>
              </xsl:attribute>
            </gmd:CI_RoleCode>
          </gmd:role>
        </gmd:CI_ResponsibleParty>
      </gfc:producer>
      <xsl:for-each select="eainfo/detailed">
        <gfc:featureType>
          <gfc:FC_FeatureType>
            <xsl:for-each select="enttyp">
              <gfc:typeName>
                <xsl:for-each select="enttypl">
                  <gco:LocalName>
                    <xsl:value-of select="."/>
                  </gco:LocalName>
                </xsl:for-each>
              </gfc:typeName>
              <gfc:definition>
                <xsl:for-each select="enttypd">
                  <gco:CharacterString>
                    <xsl:value-of select="."/>
                  </gco:CharacterString>
                </xsl:for-each>
              </gfc:definition>
            </xsl:for-each>
            <isAbstract>
              <gco:Boolean>false</gco:Boolean>
            </isAbstract>
            <gfc:featureCatalogue>
              <xsl:attribute name="uuidref">
                <xsl:value-of select="'contentInfo'"/>
              </xsl:attribute>
            </gfc:featureCatalogue>
            <xsl:for-each select="attr">
              <gfc:carrierOfCharacteristics>
                <gfc:FC_FeatureAttribute>
                  <xsl:for-each select="attrlabl">
                    <gfc:memberName>
                      <gco:LocalName>
                        <xsl:value-of select="."/>
                      </gco:LocalName>
                    </gfc:memberName>
                  </xsl:for-each>
                  <xsl:for-each select="attrdef">
                    <gfc:definition>
                      <gco:CharacterString>
                        <xsl:value-of select="."/>
                      </gco:CharacterString>
                    </gfc:definition>
                  </xsl:for-each>
                  <gfc:cardinality>
                    <xsl:attribute name="gco:nilReason">
                      <xsl:value-of select="'unknown'"/>
                    </xsl:attribute>
                  </gfc:cardinality>
                  <xsl:for-each select="attrdefs">
                    <gfc:definitionReference>
                      <gfc:FC_DefinitionReference>
                        <gfc:definitionSource>
                          <gfc:FC_DefinitionSource>
                            <gfc:source>
                              <gmd:CI_Citation>
                                <gmd:title>
                                  <xsl:attribute name="gco:nilReason">
                                    <xsl:value-of select="'inapplicable'"/>
                                  </xsl:attribute>
                                </gmd:title>
                                <gmd:date>
                                  <xsl:attribute name="gco:nilReason">
                                    <xsl:value-of select="'unknown'"/>
                                  </xsl:attribute>
                                </gmd:date>
                                <gmd:citedResponsibleParty>
                                  <gmd:CI_ResponsibleParty>
                                    <gmd:organisationName>
                                      <gco:CharacterString>
                                        <xsl:value-of select="."/>
                                      </gco:CharacterString>
                                    </gmd:organisationName>
                                    <gmd:role>
                                      <gmd:CI_RoleCode>
                                        <xsl:attribute name="codeList">
                                          <xsl:value-of select="'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#CI_RoleCode'"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="codeListValue">
                                          <xsl:value-of select="'resourceProvider'"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="codeSpace">
                                          <xsl:value-of select="'001'"/>
                                        </xsl:attribute>
                                      </gmd:CI_RoleCode>
                                    </gmd:role>
                                  </gmd:CI_ResponsibleParty>
                                </gmd:citedResponsibleParty>
                              </gmd:CI_Citation>
                            </gfc:source>
                          </gfc:FC_DefinitionSource>
                        </gfc:definitionSource>
                      </gfc:FC_DefinitionReference>
                    </gfc:definitionReference>
                  </xsl:for-each>
                  <xsl:for-each select="attrtype">
                    <valueType>
                      <gco:TypeName>
                        <gco:aName>
                          <gco:CharacterString>
                            <xsl:value-of select="."/>
                          </gco:CharacterString>
                        </gco:aName>
                      </gco:TypeName>
                    </valueType>
                  </xsl:for-each>
                  <xsl:for-each select="attudomv/udom/attrunit">
                    <gfc:valueMeasurementUnit>
                      <gml:BaseUnit>
                        <xsl:attribute name="gml:id">
                          <xsl:value-of select="."/>
                        </xsl:attribute>
                        <gml:identifier>
                          <xsl:attribute name="codeSpace">
                            <xsl:value-of select="."/>
                          </xsl:attribute>
                        </gml:identifier>
                        <gml:unitsSystem>
                          <xsl:attribute name="nilReason">
                            <xsl:value-of select="."/>
                          </xsl:attribute>
                        </gml:unitsSystem>
                      </gml:BaseUnit>
                    </gfc:valueMeasurementUnit>
                  </xsl:for-each>
                  <xsl:for-each select="attrdomv/edom">
                    <gfc:listedValue>
                      <gfc:FC_ListedValue>
                        <xsl:for-each select="edomv">
                          <gfc:label>
                            <gco:CharacterString>
                              <xsl:value-of select="."/>
                            </gco:CharacterString>
                          </gfc:label>
                        </xsl:for-each>
                        <xsl:for-each select="edomvd">
                          <gfc:definition>
                            <gco:CharacterString>
                              <xsl:value-of select="."/>
                            </gco:CharacterString>
                          </gfc:definition>
                        </xsl:for-each>
                        <xsl:for-each select="edomvds">
                          <gfc:definitionReference>
                            <gfc:FC_DefinitionReference>
                              <gfc:definitionSource>
                                <gfc:FC_DefinitionSource>
                                  <gfc:source>
                                    <gmd:CI_Citation>
                                      <gmd:title>
                                        <xsl:attribute name="gco:nilReason">
                                          <xsl:value-of select="."/>
                                        </xsl:attribute>
                                      </gmd:title>
                                      <gmd:date>
                                        <xsl:attribute name="gco:nilReason">
                                          <xsl:value-of select="."/>
                                        </xsl:attribute>
                                      </gmd:date>
                                      <gmd:citedResponsibleParty>
                                        <gmd:CI_ResponsibleParty>
                                          <gmd:organisationName>
                                            <gco:CharacterString>
                                              <xsl:value-of select="."/>
                                            </gco:CharacterString>
                                          </gmd:organisationName>
                                          <gmd:role>
                                            <gmd:CI_RoleCode>
                                              <xsl:attribute name="codeList">
                                                <xsl:value-of select="'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#CI_RoleCode'"/>
                                              </xsl:attribute>
                                              <xsl:attribute name="codeListValue">
                                                <xsl:value-of select="'resourceProvider'"/>
                                              </xsl:attribute>
                                              <xsl:attribute name="codeSpace">
                                                <xsl:value-of select="'001'"/>
                                              </xsl:attribute>
                                            </gmd:CI_RoleCode>
                                          </gmd:role>
                                        </gmd:CI_ResponsibleParty>
                                      </gmd:citedResponsibleParty>
                                    </gmd:CI_Citation>
                                  </gfc:source>
                                </gfc:FC_DefinitionSource>
                              </gfc:definitionSource>
                            </gfc:FC_DefinitionReference>
                          </gfc:definitionReference>
                        </xsl:for-each>
                      </gfc:FC_ListedValue>
                    </gfc:listedValue>
                  </xsl:for-each>
                  <xsl:for-each select="attudomv/codesetd">
                    <gfc:listedValue>
                      <gfc:FC_ListedValue>
                        <xsl:for-each select="codesetn">
                          <gfc:label>
                            <gco:CharacterString>
                              <xsl:value-of select="."/>
                            </gco:CharacterString>
                          </gfc:label>
                        </xsl:for-each>
                        <gfc:definitionReference>
                          <gfc:FC_DefinitionReference>
                            <xsl:for-each select="codesets">
                              <gfc:definitionSource>
                                <gfc:FC_DefinitionSource>
                                  <gfc:source>
                                    <gmd:CI_Citation>
                                      <gmd:title>
                                        <xsl:attribute name="gco:nilReason">
                                          <xsl:value-of select="."/>
                                        </xsl:attribute>
                                      </gmd:title>
                                      <gmd:date>
                                        <xsl:attribute name="gco:nilReason">
                                          <xsl:value-of select="."/>
                                        </xsl:attribute>
                                      </gmd:date>
                                      <gmd:citedResponsibleParty>
                                        <gmd:CI_ResponsibleParty>
                                          <gmd:organisationName>
                                            <gco:CharacterString>
                                              <xsl:value-of select="."/>
                                            </gco:CharacterString>
                                          </gmd:organisationName>
                                          <gmd:role>
                                            <gmd:CI_RoleCode>
                                              <xsl:attribute name="codeList">
                                                <xsl:value-of select="'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#CI_RoleCode'"/>
                                              </xsl:attribute>
                                              <xsl:attribute name="codeListValue">
                                                <xsl:value-of select="'resourceProvider'"/>
                                              </xsl:attribute>
                                              <xsl:attribute name="codeSpace">
                                                <xsl:value-of select="'001'"/>
                                              </xsl:attribute>
                                            </gmd:CI_RoleCode>
                                          </gmd:role>
                                        </gmd:CI_ResponsibleParty>
                                      </gmd:citedResponsibleParty>
                                    </gmd:CI_Citation>
                                  </gfc:source>
                                </gfc:FC_DefinitionSource>
                              </gfc:definitionSource>
                            </xsl:for-each>
                          </gfc:FC_DefinitionReference>
                        </gfc:definitionReference>
                      </gfc:FC_ListedValue>
                    </gfc:listedValue>
                  </xsl:for-each>
                </gfc:FC_FeatureAttribute>
              </gfc:carrierOfCharacteristics>
            </xsl:for-each>
          </gfc:FC_FeatureType>
        </gfc:featureType>
      </xsl:for-each>
    </gfc:FC_FeatureCatalogue>
  </xsl:template>
</xsl:stylesheet>
