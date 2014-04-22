<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:date="http://exslt.org/dates-and-times"
    exclude-result-prefixes="exsl xml html acis date"
    version="1.0">  

  <xsl:import href='index.xsl'/>

  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>Logs: <xsl:value-of select='$form-input/log'/></xsl:with-param>
      
      <xsl:with-param name='content'>

        <xsl:choose>
          <xsl:when test='$form-input/log'>
            
            <h1 id='top'>Logs: <xsl:value-of select='$form-input/log'/></h1>
            
          </xsl:when>
          <xsl:otherwise>
            
            <h1 id='top'>Logs</h1>
            
          </xsl:otherwise>
        </xsl:choose>
        
        <xsl:text> </xsl:text>

        <acis:form>
          <p>
            <label for='log'>Log: </label>
            <input type='text' id='log' name='log' value='{$form-input/log}' size='12'/>
            <br/>
            
            <label for='tail'>how much: </label>
            <input type='text' id='tail' name='tail' value='{$form-input/tail}'/>
            <br/>

            <label for='key'>search: </label>
            <input type='text' id='key' name='key' value='{$form-input/key}'/>
            <br/>

            <input type='submit' value='Go get it' class='important' />
          </p>          
        </acis:form>

        <xsl:choose>
          <xsl:when test='//logdata'>
            
            <h2>The log:</h2>
            
            <pre><xsl:value-of select='//logdata' /></pre>
            
            <p><a href='#top'>Return to top</a></p>
            
          </xsl:when>
        </xsl:choose>
        
        <xsl:call-template name='adm-menu'/>
        
      </xsl:with-param>
      
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>