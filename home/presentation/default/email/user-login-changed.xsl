<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
 
  <xsl:import href='general.xsl'/>

  <!-- this template-specific variables: -->

  <xsl:variable name='old-login' select='$user/old-login'/>


<xsl:template match='/data'
  ><xsl:call-template name='message'>
  <xsl:with-param name='to'>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$old-login'/>&gt;</xsl:with-param>
  <xsl:with-param name='cc'>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$user-login'/>&gt;</xsl:with-param>
  <xsl:with-param name='subject'>login name (email address) change</xsl:with-param>
  <xsl:with-param name='content'>

Hello <xsl:value-of select='$user-name'/>, 

You or someone used your login and password to log into 
<xsl:value-of select='$site-name-long'/> 
and change the login name (email address) from: 

  <xsl:value-of select='$old-login'/>

to

  <xsl:value-of select='$user-login'/>

If you think this is wrong, please contact system administrator at
<xsl:value-of select='$admin-email'/>


</xsl:with-param>
</xsl:call-template>
</xsl:template>




</xsl:stylesheet>

