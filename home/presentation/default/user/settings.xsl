<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:acis="http://acis.openlib.org"
    exclude-result-prefixes='exsl xml acis html #default'
    version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  <xsl:import href='../forms.xsl'/>

  <xsl:variable name='current-screen-id'>account-settings</xsl:variable>


  <xsl:template match='/data'>
  
    <xsl:choose>
      <xsl:when test='$advanced-user'>

        <xsl:call-template name='user-account-page'>
          <xsl:with-param name='title'>account settings</xsl:with-param>
          <xsl:with-param name='content'>
            <xsl:call-template name='account-settings'/>
          </xsl:with-param>
        </xsl:call-template>

      </xsl:when>
      <xsl:otherwise>

        <xsl:call-template name='appropriate-page'>
          <xsl:with-param name='title'>account settings</xsl:with-param>
          <xsl:with-param name='content'>
            <xsl:call-template name='account-settings'/>
          </xsl:with-param>
        </xsl:call-template>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <xsl:template name='account-settings'>
    
    
    <h1>Your account</h1>
    
    <xsl:call-template name='show-status'/>
    
    <acis:form xsl:use-attribute-sets='form' name='set'>
      
      <xsl:call-template name='fieldset'> 
        
        <xsl:with-param name='content'>
          
          <h2>Login</h2>
          
          <p>
            
            <label for='email-inp'>Login name/email address: </label>
            <br />
            <acis:input name='email' id='email-inp' size='50'>
              <acis:check nonempty=''/>
            </acis:input>
            <br />
            
            <xsl:if test='$record-about-owner'>
              <acis:input type='checkbox' name='record-email' id='record-email' checked=''/>
              <label for='record-email'> Also update my record's contact details 
              accordingly</label>
              <br />
            </xsl:if>
            
            <acis:input type='checkbox' name='remember-login' id='rem-l'
                        onchange='control_remember_password_switch();'/>
            <label for='rem-l'
                   title='Cookie is a bit of information, stored on your computer'>
              <xsl:text> Remember email address in a cookie.</xsl:text>
            </label>
          </p>
          
          <acis:onsubmit>
            var pass_old_e  = getRef("old");
            var pass_new_e  = getRef("new");
            var pass_conf_e = getRef("conf");
            
            var pass_old  = pass_old_e.value;
            var pass_new  = pass_new_e.value;
            var pass_conf = pass_conf_e.value;
            
            if ( pass_new || pass_conf ) {
               if ( pass_old == '' ) {
                alert( "To change your password, first enter your current password." );
                pass_old_e.focus();
                return false;
              }

              if ( !pass_new || !pass_conf || pass_new != pass_conf ) {
                alert( "New password and confirm values shall be the same.  Please try again." );
                pass_new_e.focus();
                return false;
              }
            }
          </acis:onsubmit>
          
          
          <h2>Password</h2>
          
          <table id='passwords'>
            <tr>
              <td>
                <label for='old'>current:</label>
              </td>
              <td>
                <acis:input name='pass' type='password' id='old' 
                            onchange='control_remember_password_switch();'>
                  <acis:name>current password</acis:name>
                </acis:input>
                
              </td>
            </tr>

            <tr>
              <td>
                <label for='new'>new:</label>
              </td>
              <td>
                <acis:input name='pass-new' type='password' id='new'>
                  <acis:hint side=''>Minimum 6 digits or English letters.</acis:hint>
                </acis:input>
              </td>
            </tr>
            
            <tr>
              <td>
                <label for='conf'>confirm:</label>
              </td>
              <td>
                <acis:input name='pass-confirm' type='password' id='conf'>
                  <!-- check test='value &amp;&amp; value != getRef("new").value'>
                       <do>
                       alert( "New password and confirm values shall be the same.  Please try again." );
                       getRef("new").focus();
                       return false;
                       </do>
                       </check -->
                </acis:input>
              </td>
            </tr>
            
            <tr>
              <td>
              </td>
              <td>
                
                <acis:input type='checkbox' name='remember-pass' id='rem-p' />
                <label for='rem-p'
                       title='Will only work if you also choose to store your email in a cookie. See above.'>
                  <xsl:text> Remember password in a cookie.</xsl:text>
                </label>
                
                <acis:script-onload>control_remember_password_switch();</acis:script-onload>


              </td>
            </tr>

          </table>
          
          <!--          <p>
               <label>old:<br />
               <acis:input name='pass-old' type='password'/>
               </label><br />
               
               <label>new:<br />
               <acis:input name='pass-new' type='password'/>
               </label><br />
               
               <label>confirm:<br />
               <acis:input name='pass-conf' type='password'/>
               </label>
               </p>
               
          -->  
          
          <h2>Owner</h2>
          
          <p>
            <label for='name-input'>Account owner name:</label><br />
            <acis:input name='name' id='name-input' size='50'>
              <acis:check nonempty=''/>
            </acis:input>
          </p>
          
          
          
          <p>
            <input type='submit' name='continue' value='SAVE' class='important'/>
          </p>
          
        </xsl:with-param>
      </xsl:call-template>
      
    </acis:form>
    
  </xsl:template>
  
  
  <xsl:variable name='to-go-options'>
    
    <xsl:choose>
      <xsl:when test='$advanced-user'>
        <acis:op>
          <a ref='@menu' >records menu page</a>
        </acis:op>
      </xsl:when>
      <xsl:otherwise>
        <acis:root/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:variable>


</xsl:stylesheet>