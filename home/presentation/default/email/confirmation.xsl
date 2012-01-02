<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  <xsl:import href='general.xsl'/>
  <!-- evcino -->
  <!-- this template-specific variables: -->
  <xsl:variable name='confirmation-url' 
                select='$response-data/confirmation-url/text()'/>
  <xsl:variable name='record' 
                select='$response-data/record'/>
  <xsl:variable name='any-research-identified' 
                select='count($record/contributions/accepted/list-item)'/>
  <xsl:template match='/data'>
    <xsl:call-template name='message'>
      <xsl:with-param name='to'>
        <xsl:text>"</xsl:text>
        <xsl:value-of select='$user-name'/>
        <xsl:text>" &lt;</xsl:text>
        <xsl:value-of select='$user-login'/>
        <xsl:text>&gt;</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='bcc'>
        <xsl:value-of select='$admin-email'/>
      </xsl:with-param>
      <xsl:with-param name='subject'>
        <xsl:text>confirm your registration</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:text>Hello </xsl:text>
        <xsl:value-of select='$user-name'/>
        <xsl:text>,&#10;&#10;welcome to the </xsl:text>
        <xsl:value-of select='$site-name-long'/>
        <xsl:text>. To finalize the &#10;registration process, please click on the following address &#10;or paste it into your browser:&#10;&#10;</xsl:text>
        <xsl:value-of select='$confirmation-url'/>
        <xsl:text>&#10;&#10;If you believe to have received this email by error, please ignore it.&#10;</xsl:text>
        <acis:phrase ref='email-confirmation-about-registering'/>
        <xsl:text>&#10;</xsl:text>  
        <xsl:choose>
          <xsl:when test='$any-research-identified'>
          </xsl:when>
          <xsl:otherwise>
            <!-- no works claimed -->
            <acis:phrase ref='email-confirmation-no-works-claimed'/>
            <xsl:text>
            </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>

