<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">

  <xsl:import href='../page.xsl'/>  

  <xsl:template match='/'>
    <xsl:call-template name='page'>
      <xsl:with-param name='title'>
        <xsl:text>Application Error</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='body-title'>
        <xsl:text>Application Error</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='show-errors'/>
        <p>
          <xsl:text>We are sorry.  A problem occurred inside our system.  It is not your fault.</xsl:text>
          <br/>
          <xsl:text>Here is what happened:</xsl:text>
        </p>        
        <p>
          <pre>
            <xsl:value-of select='$dot/handlererror'/>
          </pre>
        </p>        
        <p>
          <xsl:text>You may try:</xsl:text>
        </p>       
        <ul>
          <li>
            <xsl:text>repeating the request: click on the “Refresh” button in your browser</xsl:text>
          </li>
          <li>
            <xsl:text>going back in history</xsl:text>
          </li>
          <li>
            <xsl:text>emailing us (email link in the page footer).</xsl:text>
          </li>
        </ul>      
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
