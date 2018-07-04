<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://icl.com/saxon" extension-element-prefixes="saxon">
<!-- Last Updated Date: 07/31/2013 -->
	<xsl:output method="xml" encoding="utf-8" indent="yes"/>
	
	<!-- ************************************************************************************************************* -->
	<!-- Strip whitespace -->
	<xsl:strip-space elements="*"/>
	<!-- ...  except for text -->
	<xsl:preserve-space elements="text"/>
	
	<!-- ************************************************************************************************************* -->
	<!-- Define a newline character -->
	<xsl:variable name="newline"><xsl:text>
	</xsl:text></xsl:variable>

	<!-- ************************************************************************************************************* -->
	<!-- Match Root node -->
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- ************************************************************************************************************* -->	
	<!-- Output all elements and attribtues -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>

	<!-- ************************************************************************************************************* -->
	<!-- Populate "@hierarchy-path" value in "intel-swd-topic" -->
	<xsl:template match="@hierarchy-path[parent::intel-swd-topic]">
		<xsl:variable name="tmp-hierarchy-path">
			<xsl:for-each select="ancestor-or-self::intel-swd-topic">
				<xsl:sort select="count(ancestor::*)" order="ascending"/>
				<xsl:value-of select="concat('//', @id)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="hierarchy-path" select="substring-after($tmp-hierarchy-path,'//')"/>   
		<xsl:attribute name="hierarchy-path">
			<xsl:value-of select="$hierarchy-path"/>
		</xsl:attribute>
	</xsl:template>

	<!-- ************************************************************************************************************* -->
	<!-- Populate "@parent-id" value in "intel-swd-topic" -->
	<xsl:template match="@parent-id[parent::intel-swd-topic]">
		<xsl:attribute name="parent-id">
			<xsl:value-of select="../../@id"/>
		</xsl:attribute>
	</xsl:template>

</xsl:stylesheet>
