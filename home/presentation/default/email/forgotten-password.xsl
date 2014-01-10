<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis str"
    version="1.0">

  <xsl:import href='general.xsl'/>  

  <xsl:template match='/data'>
    <xsl:call-template name='message'>
      <xsl:with-param name='to'>
        <xsl:text>"</xsl:text>
        <xsl:value-of select='$user-name'/>
        <xsl:text>" &lt;</xsl:text>
        <xsl:value-of select='$user-login'/>
        <xsl:text>&gt;</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='subject'>
        <xsl:text>password reset link</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:text>&#10;&#10;&#10;Hello </xsl:text>
        <xsl:value-of select='$user-name'/><xsl:text>,&#10;&#10;Someone (may be you) requested a password reset at </xsl:text>
        <xsl:value-of select='$site-name'/>
        <xsl:text>.&#10;&#10;Please follow this link to set a new password for your account:&#10;&#10;</xsl:text>
        <xsl:value-of select='$base-url'/>
        <xsl:text>/reset/</xsl:text>
        <!-- http://www.exslt.org/str/functions/encode-uri/str.encode-uri.html -->
        <xsl:value-of select='str:encode-uri(//token_string/text(),true())'/>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>  

</xsl:stylesheet>

