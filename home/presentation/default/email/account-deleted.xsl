<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
 
  <xsl:import href='general.xsl'/>

<!-- this template-specific variables: -->

<xsl:template match='/data'
  ><xsl:call-template name='message'>
  <xsl:with-param name='to'>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$user-login'/>&gt;</xsl:with-param>
  <xsl:with-param name='subject'>account removed</xsl:with-param>
  <xsl:with-param name='content'>

Hello <xsl:value-of select='$user-name'/>.

Your account in our system was removed per your request.
If you think this is a mistake, contact system administrator
to restore it.</xsl:with-param>

</xsl:call-template>
</xsl:template>




</xsl:stylesheet>

