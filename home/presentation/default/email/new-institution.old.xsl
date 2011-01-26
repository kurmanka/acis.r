<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
 
  <xsl:import href='general.xsl'/>
  <xsl:import href='../indent.xsl'/>

<!-- this template-specific variables: -->

<xsl:template match='/data'>

  <xsl:variable name='institution' select='$response-data/institution'/>

<xsl:call-template name='message'>
  <xsl:with-param name='to'><xsl:value-of select='$config/institutions-maintainer-email'/></xsl:with-param>
  <xsl:with-param name='cc'>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$user-login'/>&gt;</xsl:with-param>
  <xsl:with-param name='subject'>new institution</xsl:with-param>
  <xsl:with-param name='content'>

name: <xsl:value-of select='$institution/name'/>
<xsl:if test='$institution/name-english'>
name-english: <xsl:value-of select='$institution/name-english'/>
</xsl:if>
<xsl:if test='$institution/location'>
location: <xsl:value-of select='$institution/location'/>
</xsl:if>
homepage: <xsl:value-of select='$institution/homepage'/>
<xsl:if test='$institution/email'>
email: <xsl:value-of select='$institution/email'/>
</xsl:if>
<xsl:if test='$institution/phone'>
phone: <xsl:value-of select='$institution/phone'/>
</xsl:if>
<xsl:if test='$institution/postal'>
postal:<xsl:call-template name='indent'>
<xsl:with-param name='tail' select='$institution/postal/text()'/>
</xsl:call-template>
</xsl:if>
<xsl:if test='$institution/fax'>
fax: <xsl:value-of select='$institution/fax'/>
</xsl:if>
<xsl:if test='$institution/id'>
handle: <xsl:value-of select='$institution/id'/>
</xsl:if>
<xsl:if test='string-length( $institution/note/text() )'>
note: <xsl:call-template name='indent'>
<xsl:with-param name='tail' select='$institution/note/text()'/>
</xsl:call-template>
</xsl:if>

Submitted by user: <xsl:value-of select='$user-name'/> &lt;<xsl:value-of select='$user-login'/>&gt;
while editing record <xsl:value-of select='$record-id'/>

Added to the record? <xsl:choose>
<xsl:when test='$institution/add-to-profile = "true"'>yes</xsl:when>
<xsl:otherwise>no</xsl:otherwise>
</xsl:choose>

<xsl:text>
</xsl:text>

</xsl:with-param>
</xsl:call-template>
</xsl:template>




</xsl:stylesheet>

