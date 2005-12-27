<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">
  
  <xsl:import href='page.xsl'/>
  <xsl:import href='../forms.xsl'/>
  
  <xsl:template match='/data'>
    <xsl:call-template name='new-user-page'>
      <xsl:with-param name='title' select='"new registration"'/>
      <xsl:with-param name='content'  xml:space='default'>

        <phrase ref='new-registration-intro'/>

        <h1>Introduce yourself</h1>

        <p>This is the 1<sup>st</sup> of 6 steps of registering.</p>

        <form xsl:use-attribute-sets='form' name='theform' class='important'>


          <xsl:call-template name='fieldset'>
            <xsl:with-param name='content' xmlns='http://x'>
              <h2>Login details</h2>
              
              <xsl:call-template name='show-status'>
                <xsl:with-param name='fields-spec-uri'
                                select='"fields.xml"'/>
              </xsl:call-template>
          
              <p>
                <label for='email-input' >Email address (your login id).  Required:</label>
                <br/>
                <input name='email'
                       id='email-input'
                       size='50'
                       >
                  <hint>Must be a working address at which you receive email.
                  It will become your login id.</hint>
                  <check nonempty=''/>
                  <name>email address</name>
                </input>

<script-onload>
// XX 
// document.theform.email.focus();
</script-onload>
                
              </p>
              <p>
                <input name="email-pub" id='email-pub-cb'
                       type="checkbox" value='true'/>
                <label for='email-pub-cb'> Publish the email address in my
                  public profile.</label>
                <br />
                <small><strong>Note</strong>: we make every effort to prevent
                robots from gathering email addresses from our websites by
                encoding them.</small>
              </p>

              <p>
                <label for='pass-in'>Password, required:</label><br />
                <input name='pass' id='pass-in' type='password'>
                  <hint side=''>Minimum 6 digits or english letters.</hint>
                  <check nonempty=''/>
                  <name>password</name>
                </input>
                    
                <br />
                
                <label for='pass-conf-in'>Password confirmation, required:</label><br />
                <input class='edit' name='pass-confirm' id='pass-conf-in'
                       type='password'>
                  <hint side=''>Repeat the password.</hint>
                  <check nonempty=''/>
                  <name>password confirmation</name>
                </input>
                
                <br />

                  <input id='cook-cb' name="remember-me" type="checkbox"
                         class='checkbox'
                         value='true' />
                  <label for='cook-cb'>
                    <span title=
'Check this box if you now work from your own computer and want quick access to your account'
> Remember email and password for automatic login from this my
                  computer (in a cookie).</span>
                  </label>

              </p>


              
              <h2>Your name</h2>
              
              <p>
                <label for='fn'>First (given), required:</label><br/>
                <input name='first-name' id='fn' size='50'>
                  <check nonempty=''/>
                  <name>your first name</name>
                </input>
                <br/>
                
                <label for='mn'>Middle (given), optional:</label><br />
                <input name='middle-name' id='mn' size='50'>
                  <onsubmit>
  if ( value.length == 1 ) {
     var initial = confirm ( "You entered middle name: &#x201C;" + value + 
     "&#x201D;.  Is it the initial of your middle name?\n\nPress OK if yes." );
     if ( initial ) {
        element.value = value + '.';
     }
  }
                  </onsubmit>
                </input>
                  <br />
                
                <label for='ln'>Last (family), required:</label><br />
                <input name='last-name' id='ln' size='50'>
                  <check nonempty=''/>
                  <name>your last name</name>
                </input><br />
                
                <label for='ns'>Name suffix, if any:</label><br />
                <select name='name-suffix' id='ns' size='1'>
                  <option selected='' value=''>- none -</option>
                  <option>Sr.</option>
                  <option>Jr.</option>
                  <option>II</option>
                  <option>III</option>
                  <option>IV</option>
                  <option>V</option>
                </select>
                
              </p>
              
     <h2>Other</h2>
     <p>
      <label class='form-field' for='year-input'
       >A date (for identification purposes), YYYY-MM-DD:</label>
       <br />
       <span class='digit'>
         <input name='year' id='year-input' type='text' size='4'
                maxlength='4' class='edit digit'/>
         <xsl:text>-</xsl:text>
         <input name='month' type='text' size='2' maxlength='2' class='edit digit'/>
         <xsl:text>-</xsl:text>
         <input name='day'   type='text' size='2' maxlength='2' class='edit digit'/>
       </span>
       <br />
      
      <label for='hp'>Your personal homepage, optional:</label><br />
       <input name="homepage" id='hp' 
              size="50" maxlength="100" />

       <script-onload>
         var hp = getRef("hp");
         if ( hp.value == "" ) { 
            hp.value = "http://";
         }
       </script-onload>
       
       <onsubmit>
         var hp = getRef("hp");
         if ( hp.value == "http://" 
              || hp.value == "http://none" ) {
            hp.value = '';
         }
       </onsubmit>
         
       
     </p>
    
   </xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name='continue-button'/>

</form>
  </xsl:with-param>
  </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
