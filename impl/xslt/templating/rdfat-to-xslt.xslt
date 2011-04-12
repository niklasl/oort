<stylesheet version="1.0"
            xmlns="http://www.w3.org/1999/XSL/Transform"
            xmlns:xslt="http://www.w3.org/1999/XSL/Transform"
            xmlns:xsl="http://www.w3.org/1999/XSL/TransformAlias"
            xmlns:t="http://purl.org/oort/def/2011/rdfat/"
            exclude-result-prefixes="t">

  <namespace-alias stylesheet-prefix="xsl" result-prefix="xslt"/>

  <variable name="RDF">http://www.w3.org/1999/02/22-rdf-syntax-ns#</variable>
  <variable name="XSD">http://www.w3.org/2001/XMLSchema#</variable>

  <!-- TODO: params for lang and base / about -->

  <!-- TODO: also allow @src everyhere @about is used -->

  <template match="/">
    <xsl:stylesheet version="1.0"
                    xmlns:func="http://exslt.org/functions"
                    xmlns:dyn="http://exslt.org/dynamic"
                    exclude-result-prefixes="func dyn">
      <copy-of select="/*/namespace::*"/>

      <xsl:key name="rel" match="/graph/resource" use="@uri"/>
      <xsl:variable name="r" select="/graph/resource"/>

      <xsl:template match="/graph">
        <apply-templates/>
      </xsl:template>

      <xsl:template match="*[@fmt='datatype']">
        <xsl:attribute name="datatype">
          <xsl:text>
            <value-of select="local-name(/*/namespace::*[. = $XSD])"/>
            <text>:</text>
          </xsl:text>
          <xsl:value-of select="local-name(*)"/>
        </xsl:attribute>
        <xsl:value-of select="*"/>
      </xsl:template>

    </xsl:stylesheet>
  </template>

  <!-- TODO: qualifiers (@about|@src) for @property and @typeof -->
  <!-- TODO: qualifiers (@datatype|@xml:lang) for @property -->

  <!-- TODO: add @datatype for datatyped literals -->

  <template match="*[@property and not(@rel)]">
    <xsl:for-each select="{@property}">
      <copy>
        <apply-templates select="@*">
          <with-param name="in-property-scope" select="true()"/>
        </apply-templates>
        <choose>
          <when test="*">
            <for-each select="*">
              <copy>
                <apply-templates select="@*"/>
                <xsl:apply-templates select="."/>
              </copy>
            </for-each>
          </when>
          <otherwise>
            <xsl:apply-templates select="."/>
          </otherwise>
        </choose>
      </copy>
    </xsl:for-each>
  </template>

  <template match="*[@typeof]">
    <param name="in-relrev-scope" select="false()"/>
    <choose>
      <when test="starts-with(@typeof, '?')">
        <call-template name="copy-over"/>
      </when>
      <otherwise>
        <variable name="ctxt">
          <choose>
            <when test="$in-relrev-scope">self::*</when>
            <otherwise>$r</otherwise>
          </choose>
        </variable>
        <xsl:for-each select="{$ctxt}[a/{@typeof}]">
          <call-template name="copy-over"/>
        </xsl:for-each>
      </otherwise>
    </choose>
  </template>

  <template match="*[@rel and (
            not(@resource) or starts-with(@resource, '?') and
            not(@href) or starts-with(@href, '?'))]">
    <call-template name="relrev">
      <with-param name="expr">
        <call-template name="rel-expr"/>
      </with-param>
    </call-template>
  </template>

  <template match="*[@rev and (
            not(@resource) or starts-with(@resource, '?') and
            not(@href) or starts-with(@href, '?'))]">
    <call-template name="relrev">
      <with-param name="expr">
        <call-template name="rev-expr"/>
      </with-param>
    </call-template>
  </template>

  <template name="relrev">
    <param name="expr"/>
    <choose>
      <when test="@resource or @href">
        <xsl:for-each select="{$expr}">
          <choose>
            <when test="self::t:for">
              <apply-templates/>
            </when>
            <otherwise>
              <call-template name="copy-over"/>
            </otherwise>
          </choose>
        </xsl:for-each>
      </when>
      <otherwise>
        <variable name="inner">
          <xsl:for-each select="{$expr}">
            <apply-templates>
              <with-param name="in-relrev-scope" select="true()"/>
            </apply-templates>
          </xsl:for-each>
        </variable>
        <choose>
          <when test="self::t:for">
            <copy-of select="$inner"/>
          </when>
          <otherwise>
            <xsl:if test="{$expr}">
              <copy>
                <apply-templates select="@*"/>
                <copy-of select="$inner"/>
              </copy>
            </xsl:if>
          </otherwise>
        </choose>
      </otherwise>
    </choose>
  </template>

  <template name="rel-expr">
    <!-- TODO: improve loop over just *[@ref] IFF no rel found -->
    <variable name="pred">
      <if test="@in"><value-of select="@in"/><text>/</text></if>
      <apply-templates select="@rel" mode="relrev"/>
    </variable>
    <text>(</text>
    <text>key('rel', </text><value-of select="$pred"/><text>/@ref)</text>
    <text> | </text>
    <value-of select="$pred"/>
    <text>[count(key('rel', @ref)) = 0]</text>
    <text>)</text>
    <text>[true()</text><call-template name="qualifiers"/><text>]</text>
  </template>

  <template name="qualifiers">
    <!-- TODO: scooped up too much, but really just check empty elems? Perhaps
         collect things marked with t:required='true'? -->
    <for-each select="*[@typeof[not(starts-with(., '?'))] and not(@about)
              and not(*)]">
      <text> and a/</text><value-of select="@typeof"/>
    </for-each>
    <for-each select="*[@rel[substring-after(., ':') = 'type']]">
      <if test="ancestor-or-self::*/namespace::*[local-name() =
                    substring-before(current()/@rel, ':') and . = $RDF]">
        <variable name="safe-curie" select="@resource | @href"/>
        <variable name="curie" select="substring-before(
                  substring-after($safe-curie, '['), ']')"/>
        <if test="$curie != ''">
          <text> and a/</text><value-of select="$curie"/>
        </if>
      </if>
    </for-each>
    <!-- TODO: qualify on value for @resource|@href -->
  </template>

  <template name="rev-expr">
    <variable name="rev">
      <apply-templates select="@rev" mode="relrev"/>
    </variable>
    <variable name="select">
      <text>//*[</text>
      <value-of select="$rev"/><text>/@ref = current()/@uri</text>
      <call-template name="qualifiers"/>
      <text>] | self::</text><value-of select="$rev"/><text>/parent::*</text>
      <text>[true()</text>
      <call-template name="qualifiers"/>
      <text>]</text>
    </variable>
    <choose>
      <when test="@in">
        <text>dyn:map(</text><value-of select="@in"/>
        <text>, "</text><value-of select="$select"/><text>")</text>
      </when>
      <otherwise>
        <value-of select="$select"/>
      </otherwise>
    </choose>
  </template>

  <template match="@*[contains(., ' ')]" mode="relrev">
    <value-of select="concat(
              '(', translate(normalize-space(.), ' ', '|'), ')')"/>
  </template>

  <template match="@*" mode="relrev">
    <value-of select="."/>
  </template>

  <template match="@about | @href | @resource">
    <param name="in-property-scope" select="false()"/>
    <attribute name="{name()}">
      <choose>
        <when test="starts-with(., '?')">
          <text>{</text>
          <if test="$in-property-scope">../</if>
          <text>@uri}</text>
        </when>
        <otherwise>
          <apply-templates/>
        </otherwise>
      </choose>
    </attribute>
  </template>

  <template match="@typeof">
    <choose>
      <when test="starts-with(., '?')">
        <xsl:attribute name="typeof">
          <xsl:for-each select="a/*">
            <xsl:if test="position() > 1">
              <xsl:text xml:space="preserve"> </xsl:text>
            </xsl:if>
            <xsl:value-of select="name(.)"/>
          </xsl:for-each>
        </xsl:attribute>
      </when>
      <otherwise>
        <copy-of select="."/>
      </otherwise>
      </choose>
  </template>

  <template match="t:let" priority="1">
    <xsl:variable name="{@var}">
      <attribute name="select">
        <choose>
          <when test="@eval">
            <value-of select="@eval"/>
          </when>
          <when test="@rel">
            <call-template name="rel-expr"/>
          </when>
          <when test="@rev">
            <call-template name="rev-expr"/>
          </when>
        </choose>
      </attribute>
    </xsl:variable>
  </template>

  <template match="t:for">
    <xsl:apply-templates/>
  </template>

  <template match="t:out">
    <xsl:value-of select="{@eval}"/>
  </template>

  <!-- TODO: remove this in favour of either $uri or bound var? -->
  <template match="t:uri">
    <xsl:value-of select="@uri | @ref"/>
  </template>

  <template match="t:if">
    <xsl:if test="{@eval}"><apply-templates/></xsl:if>
  </template>

  <template match="t:order">
    <xsl:sort select="{translate(normalize-space(@desc | @asc), ' ', '|')}">
      <attribute name="order">
        <choose>
          <when test="@desc">descending</when>
          <otherwise>ascending</otherwise>
        </choose>
      </attribute>
    </xsl:sort>
  </template>

  <template match="*|@*" name="copy-over">
    <param name="in-relrev-scope" select="false()"/>
    <copy>
      <apply-templates select="@*"/>
      <apply-templates>
        <with-param name="in-relrev-scope" select="$in-relrev-scope"/>
      </apply-templates>
    </copy>
  </template>

</stylesheet>
