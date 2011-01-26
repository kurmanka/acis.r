<xsl:stylesheet 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"

  version="1.0">

  <xsl:import href='../page-universal.xsl' />
  <xsl:import href='../forms.xsl'/>


  <xsl:variable name='current-screen-id'>personal-contact</xsl:variable>


  <!--    t h e   p a g e  -->
  
  <xsl:template match='/data'>
    <xsl:call-template name='user-page'>
      <xsl:with-param name='title'>Contact details</xsl:with-param>
      <xsl:with-param name='content' xml:space='preserve'>

        <h1>Contact details</h1>
        
        <xsl:call-template name='show-status'/>
        
        <acis:form xsl:use-attribute-sets='form'>
          
          <xsl:call-template name='fieldset'>
            <xsl:with-param name='content' xmlns='http://acis.openlib.org/fieldset'>
              
              <p>
                <label for='em'>Email address.  Required: <br />
                <acis:input name="email" id='em' size="50" maxlength="60" />
                </label><br />
                
                <label for='pub'>
                  <acis:input name="email-pub" id='pub' type="checkbox" value='true' />
                  Show address in my public profile</label>
              </p>
              
              <p>
                <label for='hp'>Your personal homepage, optional:<br />
                <acis:input name="homepage" id='hp' size="50" maxlength="90" />
                </label><br />
                
                <label for='ph'>Your phone number, optional:<br />
                <acis:input name="phone" id='ph' size="20" maxlength="40" />
                </label><br />
                
                <label for='post'>Your postal address, optional:<br />
                <acis:textarea name="postal" id='post' rows="5" cols="50"/>
                </label>
              </p>
                    
          
            </xsl:with-param>
          </xsl:call-template>
          <p>
            <input type='submit' class='important' value='SAVE AND RETURN TO THE MENU' />
          </p>
          
        </acis:form>
        
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template>
  
  
  <xsl:variable name='to-go-options'>
    <acis:root/>
  </xsl:variable>
  


</xsl:stylesheet>


