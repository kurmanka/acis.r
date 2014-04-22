<?xml version="1.0" encoding="utf-8"?>
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
        <xsl:text>reset password</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='content'>        
        <h1>
          <xsl:text>Reset Password</xsl:text>
        </h1>
        
        <xsl:call-template name='show-status'/>

        <xsl:if test='$success'>
        
           <p>The new password has been set. You now can <a ref='/'>login</a> to enter the system.</p>

        </xsl:if>

        <xsl:if test='not($success)'>
        
           <p>We were not able to set the password for some reason. Please try 
           again a little later or contact the administrator for support.</p>

        </xsl:if>
        
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
