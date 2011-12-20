<xsl:stylesheet
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="1.0">  
  
  <xsl:import href='page.xsl'/>

  <xsl:variable name='current-screen-id'>
    <xsl:text>account-deleted</xsl:text>
  </xsl:variable>

  <xsl:template match='/data'>
    <xsl:call-template name='page'>
      <xsl:with-param name='title'>
        <xsl:text>delete account</xsl:text>
      </xsl:with-param>

      <xsl:with-param name='content'>
        <h1>
          <xsl:text>Delete your account</xsl:text>
        </h1>

        <xsl:call-template name='show-status'/>

        <xsl:choose>
          <xsl:when test='$success'>
            <p>
              <xsl:text>Thank you for trying our service.</xsl:text>
            </p>
          </xsl:when>
          <xsl:otherwise>
            <p>
              <xsl:text>Something didn’t work out. You should not be seeing this. Probably an error happened.</xsl:text>
            </p>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
  
