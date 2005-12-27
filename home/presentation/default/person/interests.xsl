<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
  
  <xsl:import href='../forms.xsl'/>
  
  <xsl:import href='page.xsl'/>

  <xsl:variable name='current-screen-id'>personal-interests</xsl:variable>

  
  <xsl:template match='/data'>
    <xsl:call-template name='user-page'>
      <xsl:with-param name='title'>research interests</xsl:with-param>
        <xsl:with-param name='content' xml:space='preserve'>

          <h1>Areas of research interest</h1>

          <xsl:call-template name='show-status'/>

          <xsl:call-template name='fieldset'><xsl:with-param name='content' xmlns='http://x'>
          
              <form xsl:use-attribute-sets='form'>

                <p>Please enter areas of your interest, as keywords
                or phrases.  One item per line.</p>

                <p>
                  <textarea name='inter' cols='50' rows='6'/><br/>
                  <input type='submit' value='save and return to the menu' class='important'/>
                </p>
              </form>
              
            </xsl:with-param></xsl:call-template> <!-- /fieldset -->

            <xsl:choose xml:space='default'>
              <xsl:when test='$session-type = "user"'>
                <p><a ref='@menu'>Return to the main menu.</a></p>
              </xsl:when>
            </xsl:choose>

        </xsl:with-param>
      </xsl:call-template> <!-- /page -->

    </xsl:template>
    
</xsl:stylesheet>
