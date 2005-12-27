<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
 
  <xsl:import href='general.xsl'/>

<!-- this template-specific variables: -->

<xsl:template match='/data'
  ><xsl:call-template name='message'>
  <xsl:with-param name='to'>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$user-login'/>&gt;</xsl:with-param>
  <xsl:with-param name='subject'>password reminder</xsl:with-param>
  <xsl:with-param name='content'>

Hello <xsl:value-of select='$user-name'/>,

Someone (may be you) requested for your password at <xsl:value-of select='$site-name'/>.
The password is: 

  <xsl:value-of select='$user-pass'/>

<xsl:text>

</xsl:text>

</xsl:with-param>
</xsl:call-template>
</xsl:template>




</xsl:stylesheet>

