<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dyn="http://exslt.org/dynamic"
                exclude-result-prefixes="dyn">

  <xsl:param name="doc"/>
  <xsl:param name="data" select="document($doc)"/>

  <xsl:variable name="G" select="$data/graph"/>
  <xsl:variable name="R" select="$G/resource"/>


  <xsl:template match="/*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:for-each select="$G/namespace::*">
        <xsl:copy-of select="."/>
      </xsl:for-each>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@about and not(@about='*')]">
    <!-- TODO -->
  </xsl:template>

  <xsl:template match="*[@typeof and not(@typeof='*')]">
    <xsl:param name="resource"/>
    <xsl:variable name="e" select="."/>
    <xsl:for-each select="$R[a/*[name()=current()/@typeof]]">
      <xsl:call-template name="elem-with-resource">
        <xsl:with-param name="e" select="$e"/>
        <xsl:with-param name="resource" select="."/>
        <xsl:with-param name="about" select="@uri"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- hanging -->
  <xsl:template match="*[@rel]">
    <xsl:param name="resource"/>
    <xsl:variable name="e" select="."/>
    <xsl:for-each select="$R[@uri=$resource/*[name()=current()/@rel]/@ref]">
      <xsl:call-template name="elem-with-resource">
        <xsl:with-param name="e" select="$e"/>
        <xsl:with-param name="resource" select="."/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>


  <xsl:template match="@property" mode="attr">
    <xsl:param name="e"/>
    <xsl:param name="resource"/>
    <xsl:variable name="lang" select="$resource/*[name()=current()]/@xml:lang"/>
    <!-- TODO: really
         if @xml:lang and != it
         else add if not equal to ancestor::@xml:lang -->
    <xsl:if test="not($e/@xml:lang) and $lang">
      <xsl:attribute name="xml:lang">
        <xsl:value-of select="$lang"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:copy><xsl:value-of select="."/></xsl:copy>
  </xsl:template>

  <xsl:template match="@property" mode="content">
    <xsl:param name="resource"/>
    <xsl:value-of select="$resource/*[name()=current()]"/>
  </xsl:template>


  <xsl:template match="@href[.='*']" mode="attr">
    <xsl:param name="resource"/>
    <xsl:attribute name="{name()}">
      <xsl:value-of select="$resource/@uri"/>
    </xsl:attribute>
  </xsl:template>


  <xsl:template match="@typeof[.='*']" mode="attr">
    <xsl:param name="resource"/>
    <xsl:attribute name="{name()}">
      <xsl:for-each select="$resource/a/*">
        <xsl:if test="position() != 1"> </xsl:if>
        <xsl:value-of select="name(.)"/>
      </xsl:for-each>
    </xsl:attribute>
  </xsl:template>


  <xsl:template match="@*" mode="attr">
    <xsl:param name="resource"/>
    <xsl:copy><xsl:value-of select="."/></xsl:copy>
  </xsl:template>

  <xsl:template match="@*" mode="content"/>


  <xsl:template match="*">
    <xsl:param name="e" select="."/>
    <xsl:param name="resource"/>
    <xsl:call-template name="elem-with-resource">
      <xsl:with-param name="e" select="$e"/>
      <xsl:with-param name="resource" select="$resource"/>
    </xsl:call-template>
  </xsl:template>


  <xsl:template name="elem-with-resource">
    <xsl:param name="e"/>
    <xsl:param name="resource"/>
    <xsl:param name="about"/>
    <xsl:for-each select="$e">
      <xsl:copy>
        <xsl:if test="not($e/@about) and $about">
          <xsl:attribute name="about">
            <xsl:value-of select="$about"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="$e/@*" mode="attr">
          <xsl:with-param name="e" select="$e"/>
          <xsl:with-param name="resource" select="$resource"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="$e/@*" mode="content">
          <xsl:with-param name="e" select="$e"/>
          <xsl:with-param name="resource" select="$resource"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="$e/node()">
          <xsl:with-param name="resource" select="$resource"/>
        </xsl:apply-templates>
      </xsl:copy>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
