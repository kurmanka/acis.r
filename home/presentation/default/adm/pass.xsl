<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  
  <xsl:template match='/data'>
    <xsl:call-template name='appropriate-page-soft'>
      <xsl:with-param name='title' select='"admin?"'/>
      <xsl:with-param name='content'  xml:space='default'>

        <h1>Confirm your competence</h1>

        <form xsl:use-attribute-sets="form">
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
        </form>

      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>
