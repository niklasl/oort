<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:owl="http://www.w3.org/2002/07/owl#"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
                xmlns:dcelem="http://purl.org/dc/elements/1.1/"
                xmlns:dct="http://purl.org/dc/terms/"
                xmlns:gr="http://purl.org/oort/impl/xslt/grit/lib/common#">

  <xsl:import href="../grit/lib/common.xslt"/>

  <xsl:param name="lang">
    <xsl:choose>
      <xsl:when test="//*/@xml:lang">
        <xsl:value-of select="//*/@xml:lang[1]"/>
      </xsl:when>
      <xsl:otherwise>en</xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <xsl:param name="mediabase">.</xsl:param>

  <xsl:variable name="vocab" select="$r[a/owl:Ontology][1]"/>

  <xsl:output method="html" encoding="utf-8"
              omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="/">
    <html xml:lang="{$lang}">
      <xsl:variable name="title">
        <xsl:apply-templates mode="label" select="$vocab"/>
        <xsl:text>| Vocabulary Specification</xsl:text>
      </xsl:variable>
      <head>
        <title><xsl:value-of select="$title"/></title>
        <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
        <!--
        <meta name="title" content="{$title}" />
        <meta name="author" content="" />
        <meta name="copyright" content="" />
        <meta name="language" content="{$lang}" />
        -->
        <link rel="stylesheet" href="{$mediabase}/css/vocab.css" />
      </head>
      <body>
        <div id="container">
          <div id="header">
          </div>
          <div id="main" role="main">
            <xsl:apply-templates select="$vocab"/>
          </div>
          <div id="footer">
          </div>
        </div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="*[a/owl:Ontology]">
      <div class="vocab">
        <h1><xsl:apply-templates mode="label" select="."/></h1>
        <dl class="summary">
          <dt>Namespace URI</dt>
          <dd><code><xsl:value-of select="@uri"/></code></dd>
          <xsl:for-each select="*">
            <xsl:sort select="name()"/>
            <xsl:sort select="@ref"/>
            <xsl:apply-templates mode="summary" select="."/>
          </xsl:for-each>
        </dl>

        <xsl:variable name="defs" select="$r[rdfs:isDefinedBy/@ref=current()/@uri]"/>
        <xsl:variable name="classes" select="$defs[a/*[contains(local-name(), 'Class')]]"/>
        <xsl:variable name="properties" select="$defs[a/*[contains(local-name(), 'Property')]]"/>
        <h2>Contents</h2>
        <dl class="contents">
          <dt><a href="#classes">Classes</a></dt>
          <dd>
            <ul>
              <xsl:for-each select="$classes">
                <xsl:sort select="@uri"/>
                <li>
                  <xsl:apply-templates mode="ref" select="."/>
                </li>
              </xsl:for-each>
            </ul>
          </dd>
          <dt><a href="#properties">Properties</a></dt>
          <dd>
            <ul>
              <xsl:for-each select="$properties">
                <xsl:sort select="@uri"/>
                <li>
                  <xsl:apply-templates mode="ref" select="."/>
                </li>
              </xsl:for-each>
            </ul>
          </dd>
        </dl>

        <h2>Hierarchy</h2>
        <ul id="hierarchy">
          <xsl:for-each select="$classes[
                        not( gr:get(rdfs:subClassOf)/rdfs:isDefinedBy/@ref =
                        rdfs:isDefinedBy/@ref )]">
            <xsl:sort select="@uri"/>
            <li>
                <xsl:apply-templates mode="ref" select="."/>
                <xsl:call-template name="hierarchy"/>
            </li>
          </xsl:for-each>
        </ul>

        <h2>Overview</h2>
        <table>
          <tr>
            <th>Term Name</th>
            <th>Type</th>
            <th>Definition</th>
          </tr>
          <xsl:for-each select="$defs">
            <xsl:sort select="local-name(a/*)"/>
            <xsl:sort select="@uri"/>
            <tr>
              <td>
                <xsl:apply-templates mode="ref" select="."/>
              </td>
              <td>
                <xsl:call-template name="type-ref"/>
              </td>
              <td><xsl:apply-templates select="rdfs:comment"/></td>
            </tr>
          </xsl:for-each>
        </table>

        <xsl:call-template name="defs">
          <xsl:with-param name="id" select="'classes'"/>
          <xsl:with-param name="label">Classes</xsl:with-param>
          <xsl:with-param name="defs" select="$classes"/>
        </xsl:call-template>
        <xsl:call-template name="defs">
          <xsl:with-param name="id" select="'properties'"/>
          <xsl:with-param name="label">Properties</xsl:with-param>
          <xsl:with-param name="defs" select="$properties"/>
        </xsl:call-template>

      </div>
  </xsl:template>

  <xsl:template name="hierarchy">
    <xsl:variable name="sub" select="$r[rdfs:subClassOf/@ref = current()/@uri]"/>
    <xsl:if test="$sub">
      <ul>
        <xsl:for-each select="$sub">
          <xsl:sort select="@uri"/>
          <li>
            <xsl:apply-templates mode="ref" select="."/>
            <xsl:call-template name="hierarchy"/>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:if>
  </xsl:template>

  <xsl:template name="defs">
    <xsl:param name="id"/>
    <xsl:param name="label"/>
    <xsl:param name="defs"/>
    <div id="{$id}">
      <h2><xsl:value-of select="$label"/></h2>
      <xsl:for-each select="$defs">
        <xsl:sort select="@uri"/>
        <xsl:apply-templates mode="def" select="."/>
      </xsl:for-each>
    </div>
  </xsl:template>

  <xsl:template mode="def" match="*">
    <xsl:variable name="term" select="gr:term(@uri)"/>
    <div class="def" id="{$term}">
      <h3>
        <xsl:apply-templates select="rdfs:label"/>
      </h3>
      <p>
        <xsl:apply-templates select="rdfs:comment"/>
      </p>
      <dl class="summary">
        <dt>URI</dt>
        <dd>
          <a href="{@uri}">
            <code><xsl:value-of select="@uri"/></code>
          </a>
        </dd>
        <xsl:apply-templates mode="summary" select="*"/>
      </dl>
      <dl class="usage">
        <!-- TODO -->
        <dt>Properties include:</dt>
        <dd></dd>
        <dt>Used with:</dt>
        <dd></dd>
        <dt>Has subclasses:</dt>
        <dd></dd>
        <dt>Disjoint with:</dt>
        <dd></dd>
      </dl>
      <div class="footer">
        <a class="tool" href="#{$term}">[#]</a>
        <a class="tool" href="#main">[top]</a>
      </div>
    </div>
  </xsl:template>


  <xsl:template mode="label" match="*[a/owl:Ontology]">
      <xsl:apply-templates select="dct:title | dcelem:title | rdfs:label"/>
  </xsl:template>

  <xsl:template mode="ref" match="*">
    <a href="#{gr:term(@uri)}">
      <xsl:apply-templates select="rdfs:label"/>
    </a>
  </xsl:template>

  <xsl:template match="*[@ref]" priority="-1">
    <code><xsl:value-of select="@ref"/></code>
  </xsl:template>

  <xsl:template match="*[@xml:lang]">
    <xsl:if test="$lang and @xml:lang = $lang or @xml:lang = ''">
      <xsl:value-of select="."/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xsd:dateTime">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template name="type-ref">
    <xsl:for-each select="a/*">
      <xsl:if test="position() != 1">, </xsl:if>
      <xsl:call-template name="meta-ref"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="meta-ref">
    <a href="{gr:name-to-uri(.)}">
      <code><xsl:value-of select="name(.)"/></code>
    </a>
  </xsl:template>


  <xsl:template mode="summary" match="a">
    <dt>Type</dt>
    <dd>
      <xsl:for-each select="*">
        <xsl:if test="position() != 1">, </xsl:if>
        <xsl:call-template name="meta-ref"/>
      </xsl:for-each>
    </dd>
  </xsl:template>

  <xsl:template mode="summary" match="dct:created">
    <dt>Created</dt>
    <dd><xsl:apply-templates select="."/></dd>
  </xsl:template>

  <xsl:template mode="summary" match="dct:issued">
    <dt>Issued</dt>
    <dd><xsl:apply-templates select="."/></dd>
  </xsl:template>

  <xsl:template mode="summary" match="owl:versionInfo">
    <dt>Version</dt>
    <dd><xsl:apply-templates select="."/></dd>
  </xsl:template>

  <xsl:template mode="summary" match="rdfs:domain">
    <dt>Domain (everything with this property is a)</dt>
    <dd><xsl:apply-templates select="."/></dd>
  </xsl:template>

  <xsl:template mode="summary" match="rdfs:range">
    <dt>Range (every value of this property is a)</dt>
    <dd><xsl:apply-templates select="."/></dd>
  </xsl:template>

  <xsl:template mode="summary" match="*">
    <dt>
      <xsl:call-template name="meta-ref"/>
    </dt>
    <dd>
      <xsl:apply-templates select="."/>
    </dd>
  </xsl:template>


</xsl:stylesheet>
