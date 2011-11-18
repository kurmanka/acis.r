<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">
  
  <xsl:import href='../page.xsl'/>

  <xsl:import href='../forms.xsl'/>
  


  <!--  LOGIN FORM WITH JUST PASSWORD INPUT   -->


  <xsl:template name='login-form' xml:space='preserve'>
    <xsl:param name='login'/>

    <!-- there was  name='loginform' -->
    <acis:form xsl:use-attribute-sets='form' action='{$form-action}' >
      <p>
        <xsl:call-template name='fieldset' xml:space='default'>
          <xsl:with-param name='content' xml:space='preserve'>
            <xsl:if test='//form/value/login'>
              <label>email address:</label>
              <acis:input name='login' type='text' readonly='' value='{//form/value/login}' />
            </xsl:if>
            <acis:input type='hidden' name='override'/>
            <label>password:<br />
            <acis:input name='pass' type='password' />
            </label><br />            
            <acis:script-onload>
              document.loginform.pass.focus();
            </acis:script-onload>
          </xsl:with-param>
        </xsl:call-template>
        <br/>
        <input type='submit' value='LOG IN' class='important'/>
      </p>
      
      
      <p>&#160;</p>

      <p><a href='{$base-url}/forgotten-password' class='int'>Forgot your password?</a>
      &#160;|&#160; <!-- &#8212; -->
      <a href='{$base-url}/new-user' class='int'>Register as a new user.</a></p>


    </acis:form>



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