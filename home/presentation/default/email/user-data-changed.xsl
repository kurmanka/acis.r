<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
 
  <xsl:import href='general.xsl'/>

<!-- this template-specific variables: -->

<xsl:variable name='rec' select='$response-data/record'/>

<xsl:template match='/data'
  ><xsl:call-template name='message'>
  <xsl:with-param name='to'>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$user-login'/>&gt;</xsl:with-param>
  <xsl:with-param name='subject'>your profile data has changed</xsl:with-param>
  <xsl:with-param name='content'>
Hello <xsl:value-of select='$user-name'/>.
<!-- 
<xsl:choose>
<xsl:when test='$response-data/record/about-owner'>
You or someone used your login and password to change 
your personal profile in <xsl:value-of select='$site-name'/>.
</xsl:when>
<xsl:otherwise>
User <xsl:value-of 

Your profile in our system was changed by user ... this and that.

-->
We noticed you changed your profile in <xsl:value-of select='$site-name'/> system.

You may wish to check the updated profile at:

<xsl:value-of select='$response-data/permalink'/>

<xsl:text>
</xsl:text>

</xsl:with-param>
</xsl:call-template>
</xsl:template>




</xsl:stylesheet>

