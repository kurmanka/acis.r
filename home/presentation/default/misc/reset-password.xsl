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
          <p>Please set a new password for your account.</p>

          <acis:form xsl:use-attribute-sets='form' 
                   name='theform' 
                   id='theform'>
            <p>
            <label for='pass1'>
              <xsl:text>new password:</xsl:text>
            </label>
            <br/>
            <input name='pass' id='pass1'
                   size='50' type='password'/>
            </p>

            <p>
            <label for='pass2'>
              <xsl:text>password confirmation:</xsl:text>
            </label>
            <br/>
            <input name='pass-confirm' id='pass2'
                   size='50' type='password'/>
            </p>

            <p>
            <xsl:text> </xsl:text>            
            <input type='submit' class='important' 
                   value='Set my new password' />
            <acis:script-onload>
              document.theform.pass.focus();
            </acis:script-onload>                       
            </p>        
          </acis:form>

        </xsl:if>
        
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
