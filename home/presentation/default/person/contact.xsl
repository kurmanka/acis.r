<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
        
    <form xsl:use-attribute-sets='form'>

     <xsl:call-template name='fieldset'><xsl:with-param name='content' xmlns='http://x'>

       <p>
        <label for='em'>Email address.  Required: <br />
         <input name="email" id='em' size="50" maxsize="60" />
        </label><br />

        <label for='pub'>
          <input name="email-pub" id='pub' type="checkbox" value='true' /> Show address in my
         public profile</label>
       </p>
              
       <p>
        <label for='hp'>Your personal homepage, optional:<br />
         <input name="homepage" id='hp' size="50" maxsize="90" />
        </label><br />
                  
        <label for='ph'>Your phone number, optional:<br />
         <input name="phone" id='ph' size="20" maxsize="40" />
        </label><br />
                    
        <label for='post'>Your postal address, optional:<br />
         <textarea name="postal" id='post' type="text" rows="5" cols="50"/>
        </label>
       </p>
                


     </xsl:with-param></xsl:call-template>

     <input type='submit' class='important' value='SAVE AND RETURN TO THE MENU' />
     

    </form>

  </xsl:with-param>
</xsl:call-template>

</xsl:template>


  <xsl:variable name='to-go-options'>
    <root/>
  </xsl:variable>



</xsl:stylesheet>


