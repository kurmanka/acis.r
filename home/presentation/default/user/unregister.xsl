<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:acis="http://acis.openlib.org"
    exclude-result-prefixes='exsl xml acis html #default'
  version="1.0">  
  <xsl:import href='page.xsl'/>
  <xsl:variable name='current-screen-id'>
    <xsl:text>delete-account</xsl:text>
  </xsl:variable>
  <xsl:template match='/data'>
    <xsl:call-template name='user-account-page'>
      <xsl:with-param name='title'>
        <xsl:text>delete account</xsl:text>
      </xsl:with-param>
      <!-- there was an xml:space=preserve -->
      <xsl:with-param name='content'>
        <h1>
          <xsl:text>Delete your account</xsl:text>
        </h1>
        <xsl:call-template name='show-status' />
        <acis:form>
          <p>
            <input type='submit'
                   name='action'
                   value='Proceed'
                   class='important' />
            <xsl:text>, if you really want to delete the account and the profile.</xsl:text>
            <input type='hidden'
                   name='confirm-it'
                   value='yes'/>
          </p>          
          <p>
            <xsl:text>Press Back button of your browser otherwise.</xsl:text>
          </p>
        </acis:form>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
