<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"

  version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  
  <xsl:template match='/data'>
    <xsl:call-template name='appropriate-page-soft'>
      <xsl:with-param name='title' select='"admin?"'/>
      <xsl:with-param name='content'  xml:space='default'>

        <h1>Confirm your competence</h1>

        <acis:form xsl:use-attribute-sets="form">
          <p><label>Pass: 
          <input name='pass' type='text' size='12'/>
          </label>

          <xsl:text> </xsl:text>

          <label title='set a cookie?' for='remember-me'
          ><input type='checkbox' 
                  name='remember-me' 
                    id='remember-me'
          value='1'/> Remember? </label>
          </p>
        </acis:form>

      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>
