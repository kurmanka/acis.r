<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"    
    xmlns:acis="http://acis.openlib.org"
    exclude-result-prefixes='xsl acis'
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

          <acis:onsubmit>
            var pass_old_e  = getRef("old");
            var pass_new_e  = getRef("new");
            var pass_conf_e = getRef("conf");
            
            var pass_old  = pass_old_e.value;
            var pass_new  = pass_new_e.value;
            var pass_conf = pass_conf_e.value;

            if ( pass_old == '' ) {
                alert( "Enter your current password to make any changes on this screen." );
                pass_old_e.focus();
                return false;
            }

            if ( pass_new || pass_conf ) {
              if ( !pass_new || !pass_conf || pass_new != pass_conf ) {
                alert( "New password and confirm values shall be the same.  Please try again." );
                pass_new_e.focus();
                return false;
              }
            }
          </acis:onsubmit>
          
          <h2>Current password</h2>
        
          <p><label for='old'>You must enter valid current password to make any changes to 
            your settings.</label><br/>
            <acis:input name='pass' type='password' id='old'>
              <acis:name>current password</acis:name>
            </acis:input>
          </p>

  
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
          </p>
          
          
          <h2>Set new password</h2>
          
          <table id='passwords'>
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
                <label for='conf'>confirm new:</label>
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
            
          </table>

          <h2>Persistent login</h2>

            <p>
                <acis:input type='checkbox' name='remember-me' id='rem-p'/>
                <label for='rem-p'
                       title=''>
                  <xsl:text> Persistent login on this computer (via a browser cookie).</xsl:text>
                </label>
            </p>
<!-- XXX
<acis:script-onload>control_remember_password_switch();</acis:script-onload>
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
