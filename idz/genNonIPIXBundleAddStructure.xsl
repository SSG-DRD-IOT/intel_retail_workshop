<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- ************************************************************************************************************* -->
<!-- "genNonIPIXBundle.xsl" - adds nested structure to the "intel-swd-topic" element  so that -->
<!-- parent-id and hierarchy-path attribute values can be added in a later XSL script - -->
<!-- Last Updated Date: 07/31/2013 -->
	<xsl:output omit-xml-declaration="yes" indent="yes"/>
	
	<!-- Strip whitespace -->
	<xsl:strip-space elements="*"/>
	<!-- ...  except for text -->
	<xsl:preserve-space elements="text"/>
	<!-- Define a newline character -->
	<xsl:variable name="newline"><xsl:text>
	</xsl:text></xsl:variable>

<!-- ************************************************************************************************************* -->
<!--  -->
	<xsl:key name="kNestGroup" match="intel-swd-topic" use="generate-id(preceding-sibling::node()[not(self::intel-swd-topic)][1])"/>

<!-- ************************************************************************************************************* -->
<!-- Output all element, attributes, etc  -->	
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="node()[1]|@*"/>
		</xsl:copy>
		<xsl:apply-templates select="following-sibling::node()[1]"/>
	</xsl:template>

<!-- ************************************************************************************************************* -->
<!--  -->	
	<xsl:template match="intel-swd-topic[preceding-sibling::node()[1][not(self::intel-swd-topic)]]">
		<!--<xsl:apply-templates mode="intel-swd-topicgroup" select="key('kNestGroup',generate-id(preceding-sibling::node()[1]))[not(@hierarchy-level) or @hierarchy-level = 1]"/>-->
		<xsl:apply-templates mode="intel-swd-topicgroup" select="key('kNestGroup',generate-id(preceding-sibling::node()[1]))[not(@hierarchy-level) or @hierarchy-level = 0]"/>
		<xsl:apply-templates select="following-sibling::node()[not(self::intel-swd-topic)][1]"/>
	</xsl:template>

<!-- ************************************************************************************************************* -->
<!--  Match "intel-swd-topic" element -->		
	<xsl:template match="intel-swd-topic" mode="intel-swd-topicgroup">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>			
			<xsl:variable name="vNext" select="following-sibling::intel-swd-topic[not(@hierarchy-level > current()/@hierarchy-level)][1]|following-sibling::node()[not(self::intel-swd-topic)][1]"/>
			<xsl:variable name="vNextLevel" select="following-sibling::intel-swd-topic[@hierarchy-level = current()/@hierarchy-level +1][generate-id(following-sibling::intel-swd-topic[not(@hierarchy-level > current()/@hierarchy-level)][1]|following-sibling::node()[not(self::intel-swd-topic)][1])=generate-id($vNext)]"/>
			<xsl:if test="$vNextLevel">
					<xsl:apply-templates mode="intel-swd-topicgroup" select="$vNextLevel"/>
			</xsl:if>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>
