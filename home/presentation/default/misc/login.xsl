<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
  
  <xsl:import href='../page.xsl'/>

  <xsl:import href='../forms.xsl'/>
  


  <!--  LOGIN FORM  -->


  <xsl:template name='login-form' xml:space='preserve'>
    <xsl:param name='login'/>
    <xsl:param name='no-auto-login-focus'/>

    <form xsl:use-attribute-sets='form' 
          name='loginform' 
          id='loginform'>

      <table>

      <xsl:call-template name='fieldset' xml:space='default'>
        <xsl:with-param name='content' xmlns='http://x' xml:space='default'>
          
            <tr>
              <td align='right' width='30%'>
              <label for='email-login'>email address:</label>  </td>
              <td>
                <input name='login' id='email-login' size='50' tabindex='2'>
                  <name>email address</name>
                  <check nonempty=''/>
                </input>
              <xsl:for-each select='$form-input/*[name() != "login" and name() != "pass" and name != "auto-login"]'>
                <input type='hidden' name='{name()}' value='{text()}'/>
              </xsl:for-each>
              
              </td>
            </tr>

            <tr>
              <td align='right'><label for='password'>password:</label></td>
              <td><input name='pass' type='password' id='password' tabindex='3'/>

    <xsl:if test='not( //remind-password-button )'>
      <xsl:text> </xsl:text>
      <a ref='forgotten-password!' 
         tabindex='10'>
        <small>Remind you of the password?</small>
      </a>
    </xsl:if>

              </td>
            </tr>
            

          <!--
            <label>email address:<br />
            <input name='login' size='50'/></label><br />
          -->  
          <tr>
            <td align='right'>
              <label for='auto-login'>
                <small>Save login and password in 
                a cookie on this machine?</small>
              </label>
            </td>
            <td>
              <input type='checkbox' name='auto-login' id='auto-login' tabindex='3' 
                     value='true'/>
              <label for='auto-login'> Yes, remember me.</label>
            </td>
          </tr>
          
        </xsl:with-param>
        </xsl:call-template> <!-- /fieldset -->

        <tr><td></td>        
        <td>

          <input type='submit' value='Login' name='do' class='important' tabindex='4'/>

          <xsl:text> </xsl:text>

          <xsl:if test='//remind-password-button'>
            <input type='submit' 
                   name='remind-password'
                   value='Send me my password'
                   title='via email'
                   class='important'/>
          </xsl:if>

<xsl:choose xml:space='default'>
  <xsl:when test='//remind-password-button'>
          
<script-onload>
 document["loginform"].pass.focus(); 
</script-onload>

  </xsl:when>

  <xsl:when test='$no-auto-login-focus'/>
  <xsl:otherwise>
  
<script-onload>
 document["loginform"].login.focus(); 
</script-onload>

  </xsl:otherwise>
</xsl:choose>


        </td>
        </tr>
        
      </table>
        

    <xsl:if test='//show-register-invitation'>
      <p>
        <a class='int' href='{$base-url}/new-user'>Register as a new user.</a>
      </p>
    </xsl:if>


</form>



</xsl:template>
  




  <xsl:template match='/data'>

    <xsl:call-template name='page'>
      <xsl:with-param name='title'>Login required</xsl:with-param>
      <xsl:with-param name='content'>
        <h1>Log in</h1>

        <xsl:call-template name='show-status'/>

        <xsl:call-template name='login-form'>
          <!--          <xsl:with-param name='login' select='$response-data/login/text()'/> -->
        </xsl:call-template>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>