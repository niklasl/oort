<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

    <!--
    Title: Grit to RDF/XML GRDDL
    Last modified: 2010-03-27
    Copyright: Niklas Lindström [lindstream@gmail.com]
    License: BSD-style
    -->

    <xsl:param name="base" select="/*/@xml:base[position()=1]"/>
    <xsl:variable name="all-namespaces" select="//*/namespace::*"/>

    <xsl:template match="graph">
        <rdf:RDF>
            <xsl:copy-of select="$all-namespaces"/>
            <xsl:copy-of select="$base"/>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="resource" name="resource">
        <rdf:Description>
            <xsl:apply-templates select="@*|*"/>
        </rdf:Description>
    </xsl:template>

    <xsl:template match="a">
        <rdf:type rdf:resource="{namespace-uri(*)}{local-name(*)}"/>
    </xsl:template>

    <xsl:template match="*/li">
        <xsl:attribute name="rdf:parseType">Collection</xsl:attribute>
    </xsl:template>

    <xsl:template match="li">
        <xsl:call-template name="resource"/>
    </xsl:template>

    <xsl:template match="*[@fmt='datatype']">
        <xsl:copy>
            <xsl:attribute name="rdf:datatype">
                <xsl:value-of select="concat(namespace-uri(*), local-name(*))"/>
            </xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@fmt='xml']">
        <xsl:copy-of select="node()"/>
    </xsl:template>

    <xsl:template match="@uri">
        <xsl:attribute name="rdf:about"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>

    <xsl:template match="@ref">
        <xsl:attribute name="rdf:resource"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>

    <xsl:template match="*">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="*">
                    <xsl:call-template name="resource"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
