<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:coin="http://purl.org/court/def/2009/coin#"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:exslt="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                xmlns:gr="http://purl.org/oort/impl/xslt/grit/lib/common#"
                exclude-result-prefixes="coin rdf exslt str gr">

  <xsl:import href="../grit/lib/common.xslt"/>

  <xsl:template match="/graph">
    <coin>
      <xsl:for-each select="*[a/coin:CoinScheme]">
        <scheme uri="{@uri}">
          <xsl:apply-templates select="coin:template">
            <xsl:with-param name="scheme" select="."/>
          </xsl:apply-templates>
        </scheme>
      </xsl:for-each>
    </coin>
  </xsl:template>

  <xsl:template match="coin:template[coin:uriTemplate]">
    <xsl:param name="scheme"/>
    <xsl:variable name="tplt" select="."/>
    <xsl:for-each select="$r">
      <xsl:variable name="resource" select="."/>
      <xsl:if test="not(coin:forType)
              or count($resource/a/*[gr:name-to-uri(.) = $tplt/coin:forType/@ref]) > 0">
        <xsl:variable name="completed-components-rt">
          <xsl:apply-templates select="$tplt/coin:component[1]">
            <xsl:with-param name="resource" select="$resource"/>
            <xsl:with-param name="scheme" select="$scheme"/>
          </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="completed-components"
                      select="exslt:node-set($completed-components-rt)"/>
        <xsl:if test="count($completed-components/*) > 0">
          <!-- TODO: support for relToBase, relFromBase and fragmentPrefix -->
          <xsl:variable name="template-parts-rt">
            <xsl:call-template name="fill-template">
              <xsl:with-param name="uriTemplate" select="$tplt/coin:uriTemplate"/>
              <xsl:with-param name="completed-components" select="$completed-components"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="base">
            <xsl:choose>
              <xsl:when test="false()">
              </xsl:when>
              <xsl:otherwise>
                <base>
                  <xsl:value-of select="$scheme/coin:base"/>
                </base>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <uri value="{$base}{$template-parts-rt}" resource="{$resource/@uri}">
            <uriTemplate>
              <xsl:value-of select="$tplt/coin:uriTemplate"/>
            </uriTemplate>
            <xsl:copy-of select="$base"/>
            <xsl:copy-of select="$completed-components"/>
          </uri>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="coin:component">
    <xsl:param name="scheme"/>
    <xsl:param name="resource"/>
    <xsl:variable name="p" select="coin:property/@ref"/>
    <xsl:variable name="slugFrom" select="coin:slugFrom/@ref"/>
    <xsl:variable name="match">
      <xsl:for-each select="$resource/*[gr:name-to-uri(.) = $p]">
        <xsl:choose>
          <xsl:when test="$slugFrom">
            <slugFrom ref="{./@ref}" p="{$slugFrom}">
              <xsl:value-of select="gr:get(.)/*[gr:name-to-uri(.) = $slugFrom]"/>
            </slugFrom>
          </xsl:when>
          <xsl:otherwise>
            <match value="{.}">
              <xsl:call-template name="translate">
                <xsl:with-param name="slugTranslation"
                                select="$scheme/coin:slugTranslation"/>
              </xsl:call-template>
            </match>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="var">
      <xsl:choose>
        <xsl:when test="coin:variable">
          <xsl:value-of select="coin:variable"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="gr:term($p)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="(string($match)) != ''">
      <completed p="{$p}" var="{$var}">
        <xsl:copy-of select="$match"/>
      </completed>
      <xsl:apply-templates select="following-sibling::coin:component">
        <xsl:with-param name="resource" select="$resource"/>
        <xsl:with-param name="scheme" select="$scheme"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <xsl:template name="fill-template">
    <xsl:param name="uriTemplate"/>
    <xsl:param name="completed-components"/>
    <xsl:for-each select="str:tokenize($uriTemplate, '{}')">
      <xsl:choose>
        <!-- FIXME: vars aren't always at even pos! -->
        <xsl:when test="position() mod 2 = 0">
          <var name="{.}">
            <xsl:value-of select="string($completed-components/*[@var=current()])"/>
          </var>
        </xsl:when>
        <xsl:otherwise>
          <string><xsl:value-of select="."/></string>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="translate">
    <xsl:param name="slugTranslation"/>
    <!-- TODO: use lowercase, basechar-table and regexp rules -->
    <xsl:value-of select="translate(., ' ', $slugTranslation/coin:spaceReplacement)"/>
  </xsl:template>

</xsl:stylesheet>
