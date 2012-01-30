<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  <xsl:import href='../forms.xsl'/>
  
  <xsl:variable name='current-screen-id'>personal-deceased</xsl:variable>
  
  <xsl:template name='deceased-details' xml:space='default'>
    
    <h1>Deceased</h1>
    
    <xsl:call-template name='show-status'/>
    
    <xsl:call-template name='fieldset'>
      <xsl:with-param name='content'>
        <acis:form xsl:use-attribute-sets='form' >

          <p>
            <acis:input type='checkbox' name='dead'/>  
            <label for='dead'>the person is deceased</label>
            <br />
            <label for='date'>Date of death: </label>
            <acis:input name='date-y' id='date-y' size='4'/>
            <xsl:text>-</xsl:text>
            <acis:input name='date-m' id='date-m' size='2'/>
            <xsl:text>-</xsl:text>
            <acis:input name='date-d' id='date-d' size='2'/>
            <br />
          </p>
          
          <p xml:space='default'>
            <input type='submit' class='important'
                   value='SAVE AND RETURN TO MENU' name='continue' />
          </p>
        </acis:form>      
        
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match='/data'>
    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>Deceased</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='deceased-details'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>





