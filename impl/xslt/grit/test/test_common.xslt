<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:gr="http://purl.org/oort/impl/xslt/grit/lib/common#">

  <xsl:import href="../lib/common.xslt"/>

  <xsl:template match="/tests">
    <results>
      <xsl:apply-templates/>
    </results>
  </xsl:template>

  <xsl:template match="test_term">
    <xsl:copy>
      <xsl:for-each select="item">
        <xsl:variable name="term" select="gr:term(uri)"/>
        <result success="{$term = term}">
          <in>
            <xsl:value-of select="uri"/>
          </in>
          <out>
            <xsl:value-of select="term"/>
          </out>
        </result>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
