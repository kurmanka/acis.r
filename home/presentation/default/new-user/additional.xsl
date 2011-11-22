<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='page.xsl'/>
  <xsl:import href='../forms.xsl'/>
  
  <xsl:template match='/data'>
    <xsl:call-template name='new-user-page'>
      <xsl:with-param name='title'>name variations</xsl:with-param>
      <xsl:with-param name='content' xml:space='preserve'>

        <h1>Name details</h1>
        
        
        <xsl:call-template name='show-status'/>
        
        
        <acis:form xsl:use-attribute-sets='form' name='theform'>
          <xsl:call-template name='fieldset'>
            <xsl:with-param name='content'>
            
              <xsl:if test='$response-data/ask-latin-name or $form-values/name-latin/text()'>
                
                <h2>Your name in Latin letters</h2>
                
                <p>
                  <label>For international users to be able to read and write your
                  name; required:</label>
                  <br/>
                  <acis:input name='name-latin' size='50'/>
                </p>
                
              </xsl:if>
              
              <h2>Variations of your name</h2>
              <p>
                <label for='name-variations'>
                  Your name may appear in different ways in bibliographies.  We need to
                  know those ways to recognize your works in the bibliographic
                  database.  Please review and, if necessary, amend the list below.  Put
                  one variation per line:
                </label>
              <br />
              
              <acis:textarea class='edit' name='name-variations' cols='50' rows='10'/>
              </p>
            
              <!--
                  <h2>Areas of research interest</h2>
                  <p>
                  <label class='form-field'>Please list your areas of interests in research.
                  Type keywords or phrases, one per line.<br/>
                  
                  <acis:textarea class='edit' name='inter' cols='50' rows='6'/>
                  </label>
                  </p>
              -->
            </xsl:with-param>
          </xsl:call-template>
          
          <xsl:call-template name='continue-button'/>
          
        </acis:form>
        
        <acis:script-onload>
          <xsl:choose xml:space='default'>
            <xsl:when test='$response-data/ask-latin-name'>
              document.theform.elements['name-latin'].focus();
            </xsl:when>
            <xsl:otherwise>
              document.theform.elements['name-variations'].focus();
            </xsl:otherwise>
          </xsl:choose>
        </acis:script-onload>
        
        
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>