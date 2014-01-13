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

        <p>
          <xsl:text>We have sent you a secure, one-time password reset link by email.
          Please set a new password for your account.
          If you no longer have access to your email, contact the administrator.</xsl:text>
        </p>

        <acis:form xsl:use-attribute-sets='form' 
                   name='theform' 
                   id='theform'>
          <p>
            <label for='login'>
              <xsl:text>email address:</xsl:text>
            </label>
            <br/>
            <input name='login'
                   id='login'
                   size='50'/>
            <xsl:text> </xsl:text>            
            <input type='submit' 
                   class='important' 
                   value='Let me reset my password'
                   title='via email'/>
            <acis:script-onload>
              document.theform.login.focus();
            </acis:script-onload>                       
          </p>        
        </acis:form>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
