<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">
  
  <xsl:import href='../page.xsl'/>
  
  <xsl:template match='/'>

    <xsl:call-template name='page'>
      <xsl:with-param name='title'>Application Error</xsl:with-param>
      <xsl:with-param name='body-title'>Application Error</xsl:with-param>
      <xsl:with-param name='content'>

        <xsl:call-template name='show-errors'/>

        <p>We are sorry.  A problem happened inside our system.  It is not your fault.  Here is what happened:</p>
        
        <p><pre><xsl:value-of select='$dot/handlererror'/></pre></p>
        
        <p>You may try:</p>

        <ul><li>repeating the request: click on the "Refresh" button in your browser</li>
        <li>going back in history</li>
        <li>contacting system administrator.</li>
        </ul>

      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>