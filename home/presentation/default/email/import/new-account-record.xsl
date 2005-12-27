<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
 
  <xsl:import href='../general.xsl'/>

<!-- this template-specific variables: -->

<xsl:variable name='rec'        select='$response-data/record'   />
<xsl:variable name='user-name'  select='//real-user/name/text()' />
<xsl:variable name='user-email' select='//real-user/email/text()'/>
<xsl:variable name='password'   select='//import/password/text()'/>

<xsl:template match='/data'
  ><xsl:call-template name='message'>
  <xsl:with-param name='to'>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$user-email'/>&gt;</xsl:with-param>
  <xsl:with-param name='subject'>Your profile has been transfered</xsl:with-param>
  <xsl:with-param name='cc'><xsl:value-of select='$admin-email'/></xsl:with-param>

  <xsl:with-param name='content'>
Hello <xsl:value-of select='$user-name'/>

your profile has been transfered to the new RePEc Author Service.
You may wish to check your new profile page at its new 
permanent address:

<xsl:value-of select='$response-data/permalink'/>

To change anything in your profile, login at
<xsl:value-of select='$home-url'/>?login=<xsl:value-of select='$user-email'/>
and use:

     email: <xsl:value-of select='$user-email'/>
  password: <xsl:value-of select='$password'/> 

to login.

<phrase ref='email-account-imported-footer'/>

</xsl:with-param>
</xsl:call-template>
</xsl:template>


</xsl:stylesheet>

