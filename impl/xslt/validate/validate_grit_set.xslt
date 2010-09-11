<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:vl="http://purl.org/oort/def/2010/validation/core#">

  <xsl:template match="/graph">
    <graph>
      <xsl:for-each select="resource">
        <xsl:variable name="uri" select="@uri"/>
        <xsl:for-each select="*">
          <xsl:variable name="results">
            <xsl:apply-templates select="."/>
          </xsl:variable>
          <xsl:if test="$results">
            <resource>
              <vl:examinedResource ref="{$uri}"/>
              <xsl:copy-of select="$results"/>
            </resource>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    </graph>
  </xsl:template>

  <xsl:template match="*">
    <!--

    <vl:error>
      <a><vl:UnknownProperty/></a>
    </vl:error>

    <vl:error>
      <a><vl:UnknownType/></a>
    </vl:error>

    <vl:error>
      <a><vl:UnknownType/></a>
    </vl:error>

    <vl:warning>
      <a><vl:UndefinedRange/></a>
    </vl:warning>

    -->
  </xsl:template>

</xsl:stylesheet>
