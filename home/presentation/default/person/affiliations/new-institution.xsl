<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='../affiliations-common.xsl'/>
  <xsl:import href='../../forms.xsl'/>
  
  <xsl:variable name='parents'>
    <acis:par id='affiliations'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>new-institution</xsl:variable>
  
  <!--   new institution screen   -->

  <xsl:template name='the-new-institution' xml:space='preserve'>
    
    <h1>Submit new institution record</h1>
    
    <xsl:call-template name='show-status'>
      <xsl:with-param name='fields-spec-uri' select='"fields-institution.xml"'/>
    </xsl:call-template>
      
    
    <acis:form xsl:use-attribute-sets='form'>
      
      <h2>Institution</h2>

<p>Before submitting a new institution, please make sure it is not
already listed in the database: did you use the search function on the
previous screen?</p>

<p>Also, if you are submitting a university affiliation, please submit
the department, institute or center you are affiliated with, including
its web site. Simple university affiliations will not be added to the
database. For universities, you need to have "University of X,
Department of Y" with the department web page, for example. If you are
not clear what count as a affiliation, <a
HREF='http://blog.repec.org/2011/04/26/about-author-affiliations/'
target ='new'>see here</a>.</p>

        <xsl:call-template name='fieldset'>
          <xsl:with-param name='content'>              
            <p>
              <label for='name'>Name in original language, required: </label>
              <br/>
              <acis:input name='name' id='name' size='50'/><br/>
              
              <label for='nameen'>Name in English, optional: </label><br />
              <acis:input name='name-english' id='nameen' size='50'/><br/>
              
              <label for='location'>Geographical location (country, city/town), required: </label>
              <br />
              <acis:input name='location' id='location' size='50'/><br/>
              
              <label for='homepage'>Website address, required:</label><br />
              <acis:input name='homepage' id='homepage' size='50'/><br/>
              
              <label for='email'>Email address of the institution (not yours), optional:</label><br />
              <acis:input name='email' id='email' size='50'/><br/>
              
              <!-- the following should appear in RAS and should not
                   in AuthorClaim, and this is checked by looking at
                   the $RAS-mode variable (service-mode conf param)  -->
              <xsl:if test='$RAS-mode'>
                
                <label for='postal'>Postal address</label>
                <br/>
                <acis:input name='postal' id='postal' size='50'/><br/>
                
                <label for='phone'>Phone</label>
                <br/>
                <acis:input name='phone' id='phone' size='50'/><br/>
                
                <label for='fax'>Fax</label>
                <br/>
                <acis:input name='fax' id='fax' size='50'/><br/>
                
                <xsl:if test='$form-values/id'>
                  <acis:input type='hidden' name='id'/>
                </xsl:if>              
              </xsl:if>              
            </p>
            
          
            <p>
              <acis:input type='checkbox' name='add-to-profile' id='add-to-profile' checked='checked' />
              <label for='add-to-profile'>add this institution to my affiliations profile</label>
            </p>
            
            <p>
              <label for='note'>Anything you would like to add to the above, optional:<br/></label>
              <acis:textarea name='note' id='note' cols='50' rows='4'/>
              <br/>
            </p>
            
          </xsl:with-param>
        </xsl:call-template>
        <p>
          <input type='submit' name='action' value='SUBMIT' class='important'/>
        </p>
    </acis:form> 
      
      
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