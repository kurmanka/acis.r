<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
  
  <xsl:import href='page.xsl'/>
  
  <xsl:variable name='current-screen-id'>delete-account</xsl:variable>

  <xsl:template match='/data'>
    <xsl:call-template name='user-account-page'>

      <xsl:with-param name='title'>delete account</xsl:with-param>

      <xsl:with-param name='content' xml:space='preserve'>

        <h1>Delete your account</h1>

        <xsl:call-template name='show-status' />

        <form>
          <p>
            <input type='submit' name='action' value='Proceed'
                   class='important' />, if you really want to delete the account and
                   the profile.
                   <input type='hidden' name='confirm-it' value='yes'/>
          </p>
          
          <p>Press Back button of your browser otherwise.</p>
        </form>

      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
    
</xsl:stylesheet>
  