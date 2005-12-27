<xsl:stylesheet
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 version="1.0">
  
 <xsl:import href='../page.xsl'/>
  
 <xsl:template match='/'>
  <xsl:call-template name='page'>
   <xsl:with-param name='title'>Password reminder</xsl:with-param>
   <xsl:with-param name='content'>

    <h1>Request forgotten password</h1>

    <xsl:call-template name='show-status'/>

    <p>We will send you the password reminder by email.  If you no longer have
    access to your email, contact administrator.</p>

    <form xsl:use-attribute-sets='form' name='theform' id='theform'>

     <p>
      <label for='login'>email address:</label>
      <br />
      <input name='login' id='login' size='50'/>
      <xsl:text> </xsl:text>

      <input type='submit' class='important' 
             value='Send me my password'
             title='via email'/>

<script-onload>
document.theform.login.focus();
</script-onload>
      

     </p>
        
    </form>
   </xsl:with-param>
  </xsl:call-template>
 </xsl:template>


</xsl:stylesheet>