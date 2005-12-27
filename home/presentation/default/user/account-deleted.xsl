<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
  
  <xsl:import href='page.xsl'/>
  
  <xsl:variable name='current-screen-id'>account-deleted</xsl:variable>

  <xsl:variable name='session-id'/>


  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>delete account</xsl:with-param>

      <xsl:with-param name='content' xml:space='preserve'>

        <h1>Delete your account</h1>

        <xsl:call-template name='show-status' />

        <xsl:choose xml:space='default'>
          <xsl:when test='$success'>
            <p>Thank you for trying our service.</p>
          </xsl:when>
          <xsl:otherwise>

            <p>Something didn't work out.  You shall not see this; probably an
            error happened.</p>

          </xsl:otherwise>
        </xsl:choose>

      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
    
</xsl:stylesheet>
  