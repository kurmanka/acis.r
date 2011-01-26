<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">
  
  <xsl:import href='../global.xsl'/>
  <xsl:import href='../indent.xsl'/>
  
  <xsl:output method='text' encoding='utf-8'/>
  
  <xsl:template match='text()'/>

  <xsl:template match='//record[id and type="person"]'>
Template-Type: ReDIF-Person 1.0<xsl:text />
<xsl:if test='name/prefix/text()'>
Name-Prefix: <xsl:value-of select='name/prefix'/>
</xsl:if>
Name-First: <xsl:value-of select='name/first'/>
<xsl:if test='name/middle/text()'>
Name-Middle: <xsl:value-of select='name/middle'/>
</xsl:if>
Name-Last: <xsl:value-of select='name/last'/>
<xsl:if test='name/suffix/text()'>
Name-Suffix: <xsl:value-of select='name/suffix'/>
</xsl:if>
Name-Full: <xsl:value-of select='name/full'/>

<xsl:if test='name/latin/text()'>
Name-ASCII: <xsl:value-of select='name/latin'/>
</xsl:if>

<xsl:for-each select='affiliations/list-item' >
  <xsl:choose>
    <xsl:when test='name'><!-- organization cluster -->
Workplace-Name: <xsl:value-of select='name'/>
Workplace-Location: <xsl:value-of select='location'/>
      <xsl:if test='name-english/text()'>
Workplace-Name-English: <xsl:value-of select='name-english'/>
      </xsl:if>
      <xsl:if test='homepage/text()'>
Workplace-Homepage: <xsl:value-of select='homepage'/>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>
Workplace-Organization: <xsl:value-of select='text()'/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:for-each>

<xsl:for-each select='contact'>
  <xsl:if test='email/text()'>
    <xsl:if test='email-pub="true"'>
Email: <xsl:value-of select='email'/>
    </xsl:if>
  </xsl:if>
  <xsl:if test='homepage/text()'>
Homepage: <xsl:value-of select='homepage'/>
  </xsl:if>
  <xsl:if test='postal/text()'>
Postal: <xsl:call-template name='indent'>
<xsl:with-param name='tail' select='postal/text()'/>
</xsl:call-template>
  </xsl:if>
  <xsl:if test='phone/text()'>
Phone: <xsl:value-of select='phone'/>
  </xsl:if>
  <xsl:if test='fax/text()'>
Fax: <xsl:value-of select='fax'/>
  </xsl:if>
</xsl:for-each>

<xsl:for-each select='contributions/accepted/list-item'>
<xsl:if test='type/text() and role/text() and not(starts-with(type/text(),"ReDIF-"))'>
  <xsl:text>
</xsl:text>
  <xsl:value-of select='role'/>-<xsl:value-of select='type'/>: <xsl:value-of select='id'/>
</xsl:if>
</xsl:for-each>

<xsl:if test='interests/jel/text()'>
Classification-Jel: <xsl:value-of select='interests/jel'/>
</xsl:if>

<xsl:if test='interests/freetext/text()'>
Interests: <xsl:value-of select='interests/freetext'/>
</xsl:if>

<xsl:if test='photo/url/text()'>
Photo-URL: <xsl:value-of select='photo/url'/>
</xsl:if>

<xsl:text></xsl:text>
Short-Id: <xsl:value-of select='sid'/>
Handle: <xsl:value-of select='id'/>

<xsl:choose>
<xsl:when test='//profile-owner/last-login-date'>
Last-Login-Date: <xsl:value-of select='//profile-owner/last-login-date'/>
</xsl:when>

<xsl:otherwise>
<xsl:if test='//profile-owner/imported/last-login-date'>
Last-Login-Date: <xsl:value-of select='//profile-owner/imported/last-login-date'/>
</xsl:if>
</xsl:otherwise>
</xsl:choose>

<xsl:if test='//profile-owner/initial-registered-date'>
Registered-Date: <xsl:value-of select='//profile-owner/initial-registered-date'/>
</xsl:if>

<!-- Last-Modified-Date: -->

</xsl:template>



</xsl:stylesheet>