<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">

 
  <xsl:import href='general.xsl'/>


<!-- this template-specific variables: -->

<xsl:variable name='confirmation-url' select='$response-data/confirmation-url/text()'/>

<xsl:variable name='record' select='$response-data/record'/>

<xsl:variable name='any-research-identified' select='count($record/contributions/accepted/list-item)'/>


<xsl:template match='/data'
  ><xsl:call-template name='message'>
  <xsl:with-param name='to'
>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$user-login'/>&gt;</xsl:with-param>
  <xsl:with-param name='bcc'><xsl:value-of select='$admin-email'/></xsl:with-param>
  <xsl:with-param name='subject'>confirm your registration</xsl:with-param>
  <xsl:with-param name='content'>

Hello <xsl:value-of select='$user-name'/>,

welcome to the <xsl:value-of select='$site-name-long'/>. To finalize the registration 
process, please click on the following address or paste it in your
browser:

<xsl:value-of select='$confirmation-url'/>

If you believe to have received this email by error, please ignore it.

<phrase ref='email-confirmation-about-registering'/>
<xsl:text>
</xsl:text>

<xsl:choose>
  <xsl:when test='$any-research-identified'>
  </xsl:when>
  <xsl:otherwise>
    <!-- no works claimed -->
    <phrase ref='email-confirmation-no-works-claimed'/>
    <xsl:text>
    </xsl:text>
  </xsl:otherwise>
</xsl:choose>


</xsl:with-param>
</xsl:call-template>
</xsl:template>




</xsl:stylesheet>

