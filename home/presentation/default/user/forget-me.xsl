<xsl:stylesheet xmlns:acis="http://acis.openlib.org"
                xmlns:exsl="http://exslt.org/common"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="exsl xml acis html"
                version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  <xsl:import href='../forms.xsl'/>

  <xsl:variable name='form-action'>
    <xsl:value-of select='$base-url'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>account-forget-me</xsl:variable>

  <xsl:template match='/data'>
    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'><xsl:text>Removing persistent login</xsl:text></xsl:with-param>
      
      <xsl:with-param name='content'>

        <h1>Removing persistent login cookie</h1>
        
        <xsl:call-template name='show-status'/>

        <xsl:choose>
          <xsl:when test='//persistent_login_cookie_removed'>
        
            <p>This browser's persistent login cookie has been removed. We'll ask for 
            your password on your next visit.</p>
            
          </xsl:when>
          <xsl:otherwise>
          
            <p>This browser does not have a valid persistent login cookie. So there 
            was nothing to remove.</p>

            <p>We'll ask for your password on your next visit.</p>
            
          </xsl:otherwise>
        </xsl:choose>
        
        <xsl:if test='$session-id'>
            <p>Go <a ref='settings'>back to Settings</a>?</p>
        </xsl:if>
        
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template>
  
  
</xsl:stylesheet>
