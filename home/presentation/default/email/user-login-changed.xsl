<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0"> 

  <xsl:import href='general.xsl'/>

  <!-- this template-specific variables: -->
  <xsl:variable name='modified-owner' select='//modified-owner'/>

  <xsl:variable name='old-login'      select='$user/old-login'/>


  <xsl:template match='/data'>
    <xsl:choose>
      <xsl:when test='$modified-owner'>
        <xsl:call-template name='admin-for-user'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name='user-himself'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name='admin-for-user'>
    <xsl:call-template name='message'>
    <xsl:with-param name='to'>
      <xsl:text>"</xsl:text>
      <xsl:value-of select='$modified-owner/name'/>
      <xsl:text>" &lt;</xsl:text>
      <xsl:value-of select='$modified-owner/login'/>
      <xsl:text>&gt;</xsl:text>
    </xsl:with-param>
    <xsl:with-param name='cc'>
      <xsl:value-of select='$modified-owner/old-login'/>
    </xsl:with-param>
    <xsl:with-param name='subject'>
      <xsl:text>login name (email address) changed</xsl:text>
    </xsl:with-param>
    <xsl:with-param name='content'>
      <xsl:text>Hello </xsl:text>
      <xsl:value-of select='$modified-owner/name'/>
      <xsl:text>,&#10;&#10;The admin of </xsl:text>
      <xsl:value-of select='$site-name-long'/>
      <xsl:text> has changed your login and email address from: &#10;&#10;</xsl:text>
      <xsl:value-of select='$modified-owner/old-login'/>
      <xsl:text>&#10;&#10;to&#10;&#10;</xsl:text>
      <xsl:value-of select='$modified-owner/login'/>
      <xsl:text>&#10;&#10;If you think this is wrong, please write to the system administrator&#10;at </xsl:text>
      <xsl:value-of select='$admin-email'/>
    </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name='user-himself'>
    <xsl:call-template name='message'>
    <xsl:with-param name='to'>
      <xsl:text>"</xsl:text>
      <xsl:value-of select='$user-name'/>
      <xsl:text>" &lt;</xsl:text>
      <xsl:value-of select='$old-login'/>
      <xsl:text>&gt;</xsl:text>
    </xsl:with-param>
    <xsl:with-param name='cc'>
      <xsl:text>"</xsl:text>
      <xsl:value-of select='$user-name'/>
      <xsl:text>" &lt;</xsl:text>
      <xsl:value-of select='$user-login'/>
      <xsl:text>&gt;</xsl:text>
    </xsl:with-param>
    <xsl:with-param name='subject'>
      <xsl:text>login name (email address) changed</xsl:text>
    </xsl:with-param>
    <xsl:with-param name='content'>
      <xsl:text>Hello </xsl:text>
      <xsl:value-of select='$user-name'/>
      <xsl:text>,&#10;&#10;You or someone else used your login and password to log into the&#10;</xsl:text>
      <xsl:value-of select='$site-name-long'/>
      <xsl:text> and changed the login name&#10;(email address) from: &#10;&#10;</xsl:text>
      <xsl:value-of select='$old-login'/>
      <xsl:text>&#10;&#10;to&#10;&#10;</xsl:text>
      <xsl:value-of select='$user-login'/>
      <xsl:text>&#10;&#10;If you think this is wrong, please write to the system administrator&#10;at </xsl:text>
      <xsl:value-of select='$admin-email'/>
      <xsl:text>&#10;&#10;</xsl:text>
      <xsl:text>If this email change coincides with an affiliation change,&#10;make sure to adjust your affiliation(s) as well.</xsl:text>
      <xsl:text>&#10;</xsl:text>
    </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>

