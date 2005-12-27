<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
 
  <xsl:import href='new-account-record.xsl'/>

<!-- this template-specific variables: -->
<!-- inherited from new-account-record.xsl stylesheet -->

<xsl:variable name='person' select='//import/real-user/name'/>

<xsl:template match='/data'
  ><xsl:call-template name='message'>
  <xsl:with-param name='to'>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$user-email'/>&gt;</xsl:with-param>
  <xsl:with-param name='subject'>another person record added to your account on <xsl:value-of select='$site-name'/></xsl:with-param>
  <xsl:with-param name='content'>
Hello <xsl:value-of select='$user-name'/>.

We imported the personal record of <xsl:value-of select='$person'/>
and added it to your account on <xsl:value-of select='$site-name'/>.
You now can manage that personal record through your account.

You may wish to check the imported profile page at:

<xsl:value-of select='$response-data/permalink'/>

<xsl:text>
</xsl:text>

</xsl:with-param>
</xsl:call-template>
</xsl:template>




</xsl:stylesheet>

