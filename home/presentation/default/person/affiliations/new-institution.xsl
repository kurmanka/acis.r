<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
  
  <xsl:import href='../affiliations-common.xsl'/>
  <xsl:import href='../../forms.xsl'/>
  
  <xsl:variable name='parents'>
    <par id='affiliations'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>new-institution</xsl:variable>

  
  <!--   new institution screen   -->

  <xsl:template name='the-new-institution' xml:space='preserve'>

      <h1>Submit new institution record</h1>

      <xsl:call-template name='show-status'><xsl:with-param name='fields-spec-uri' 
      select='"fields-institution.xml"'/></xsl:call-template>
          

        <form xsl:use-attribute-sets='form'>

        <h2>Institution</h2>

          <xsl:call-template name='fieldset'><xsl:with-param name='content' xmlns='http://x'>

              <p>
        <label for='name'>Name in original language, required: </label>
        <br />
        <input name='name' id='name' size='50'/><br/>
        
        <label for='nameen'>Name in English, optional: </label><br />
        <input name='name-english' id='nameen' size='50'/><br/>

        <label for='location'>Geographical location (country, city/town), required: </label>
        <br />
        <input name='location' id='location' size='50'/><br/>
         

        <label for='homepage'>Website address, required:</label><br />
        <input name='homepage' id='homepage' size='50'/><br/>

        <label for='email'>Email address, optional:</label><br />
        <input name='email' id='email' size='50'/><br/>
         
        <xsl:if test='$form-values/id'>

          <label for='postal'>Postal address
          </label>
          <br/>
          <input name='postal' id='postal' size='50'/><br/>
        
          <label for='phone'>Phone</label>
          <br/>
          <input name='phone' id='phone' size='50'/><br/>
          
          <label for='fax'>Fax</label>
          <br/>
          <input name='fax' id='fax' size='50'/><br/>
          
          <input type='hidden' name='id'/>
          
        </xsl:if>

</p>


        <p>
        <input type='checkbox' name='add-to-profile' id='add-to-profile' checked='yes' />
        <label for='add-to-profile'>
          add this institution to my affiliations profile
        </label></p>

        <p><label for='note'>
        Anything you would like to add to the above, optional:<br />
        </label>
        <textarea name='note' id='note' cols='50' rows='4'/>
        <br/>
        
        <input type='submit' name='action' value='SUBMIT' class='important'/>
      </p>

     </xsl:with-param></xsl:call-template>
   </form> 


 </xsl:template>




  <!--   n o w   t h e   p a g e   t e m p l a t e    -->

  
  <xsl:template match='/data'>

    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>submit a new institution record</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='the-new-institution'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

    



</xsl:stylesheet>