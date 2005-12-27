<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
  
  <xsl:import href='../page.xsl'/>

  <xsl:import href='../forms.xsl'/>
  


  <!--  LOGIN FORM WITH JUST PASSWORD INPUT   -->


  <xsl:template name='login-form' xml:space='preserve'>
    <xsl:param name='login'/>

    <form xsl:use-attribute-sets='form' name='loginform'
          action='{$form-action}' >
      <p>
      <xsl:call-template name='fieldset' xml:space='default'>
        <xsl:with-param name='content' xmlns='http://x' xml:space='preserve'>

          <xsl:if test='//form/value/login'>
            <label>email address:</label>
            <input name='login' type='text' readonly='' value='{//form/value/login}' />
          </xsl:if>

          <input type='hidden' name='override'/>

     <label>password:<br />
     <input name='pass' type='password' /></label><br />

     <script-onload>
document.loginform.pass.focus();
     </script-onload>



    </xsl:with-param>
  </xsl:call-template> <!-- /fieldset -->

  <br />
  <input type='submit' value='LOG IN' class='important'/>
  </p>
   

  <p>&#160;</p>

  <p><a class='int' href='{$base-url}/forgotten-password'>Forgot your password?</a>
  &#160;|&#160; <!-- &#8212; -->
  <a class='int' href='{$base-url}/new-user'>Register as a new user.</a></p>


</form>



</xsl:template>
  




  <xsl:template match='/data'>

    <xsl:call-template name='page'>
      <xsl:with-param name='title'>Re-log in</xsl:with-param>
      <xsl:with-param name='content'>
        <h1>Log in</h1>

        <xsl:call-template name='show-status'/>

        <xsl:call-template name='login-form'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>