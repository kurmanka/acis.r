<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0"> 
  <xsl:import href='general.xsl'/>
  <xsl:import href='../indent.xsl'/>
  <!-- this email is only sent when the user logs out -->
  <!-- this template-specific variables: -->
  <xsl:template match='/data'>    
  <xsl:variable name='institution' 
                select='$response-data/institution'/>
  <xsl:call-template name='message'>
    <xsl:with-param name='to'>
      <xsl:value-of select='$config/institutions-maintainer-email'/>
    </xsl:with-param>
    <xsl:with-param name='cc'>
      <xsl:text>"</xsl:text>
      <xsl:value-of select='$user-name'/>
      <xsl:text>" &lt;</xsl:text>
      <xsl:value-of select='$user-login'/>
      <xsl:text>&gt;</xsl:text>
    </xsl:with-param>
    <xsl:with-param name='subject'>
      <xsl:text>new institution</xsl:text>
    </xsl:with-param>
    <xsl:with-param name='content'>
      <xsl:text>&#10;&#10;&lt;organization id="</xsl:text>
      <xsl:choose>
        <xsl:when test='$institution/id/text()'>
          <xsl:value-of select='$institution/id'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>info:lib/we:.....</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>"&gt;</xsl:text>
      <xsl:text>&#10;  &lt;name&gt;</xsl:text>
      <xsl:value-of select='$institution/name'/>
      <xsl:text>  &lt;/name&gt;</xsl:text>
      <xsl:if test='$institution/name-english/text()'>
        <xsl:text>&#10;  &lt;name xml:lang="en"&gt;</xsl:text>
        <xsl:value-of select='$institution/name-english'/>
        <xsl:text>  &lt;/name&gt;</xsl:text>
      </xsl:if>
      <xsl:if test='$institution/location/text()'>
        <xsl:text>&#10;  &lt;we:location&gt;</xsl:text>
        <xsl:value-of select='$institution/location'/>
        <xsl:text>&lt;/we:location&gt;</xsl:text>
      </xsl:if>
      <xsl:text>&#10;  &lt;homepage&gt;</xsl:text>
      <xsl:value-of select='$institution/homepage'/>
      <xsl:text>&lt;/homepage&gt;</xsl:text>
      <xsl:if test='$institution/email'>
        <xsl:text>&#10;  &lt;email&gt;</xsl:text>
        <xsl:value-of select='$institution/email'/>
        <xsl:text>&lt;/email&gt;</xsl:text>
      </xsl:if>
      <xsl:if test='$institution/phone/text()'>
        <xsl:text>&#10;  &lt;phone&gt;</xsl:text>
        <xsl:value-of select='$institution/phone'/>
        <xsl:text>&lt;/phone&gt;</xsl:text>
      </xsl:if>
      <xsl:if test='$institution/postal/text()'>
        <xsl:text>&#10;  &lt;postal&gt;</xsl:text>
        <xsl:call-template name='indent'>
          <xsl:with-param name='tail' 
                          select='$institution/postal/text()'/>
        </xsl:call-template>
        <xsl:text>&lt;/postal&gt;</xsl:text>
      </xsl:if>
      <xsl:if test='$institution/fax/text()'>
        <xsl:text>&#10;  &lt;fax&gt;</xsl:text>
        <xsl:value-of select='$institution/fax'/>
        <xsl:text>&lt;/fax&gt;</xsl:text>
      </xsl:if>
      <xsl:text>&#10;&lt;/organization&gt;</xsl:text>
      <xsl:if test='string-length( $institution/note/text() )'>
        <xsl:text>&#10;&#10;note: </xsl:text>
        <xsl:call-template name='indent'>
          <xsl:with-param name='tail' 
                          select='$institution/note/text()'/>
        </xsl:call-template>
      </xsl:if>
      <xsl:text>&#10;&#10;Submitted by user: </xsl:text>
      <xsl:value-of select='$user-name'/>
      <xsl:text> </xsl:text>
      <xsl:text>&lt;</xsl:text>
      <xsl:value-of select='$user-login'/>
      <xsl:text>&gt;&#10;while editing record </xsl:text>
      <xsl:value-of select='$record-id'/>
      <xsl:text>&#10;Added to the record? </xsl:text>
      <xsl:choose>
        <xsl:when test='$institution/add-to-profile = "true"'>
          <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>no</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#10;</xsl:text>
    </xsl:with-param>
  </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>

