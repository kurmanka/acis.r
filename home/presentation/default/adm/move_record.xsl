<xsl:stylesheet
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:exsl="http://exslt.org/common"
   exclude-result-prefixes="exsl"
   version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  
  <xsl:template match='/data'>
    <xsl:call-template name='appropriate-page-soft'>
      <xsl:with-param name='title' select='"move profile"'/>
      <xsl:with-param name='content'  xml:space='default'>

        <xsl:choose>
          <xsl:when test='$success'>

            <p>Successfully added profile of <xsl:value-of select='//new-record-name'/> to your account.</p>

            <p>Would you like to see his/hers <a ref='{//new-record-sid}/overview'>profile overview</a>
            or <a ref='{//new-record-sid}/deceased'>deceased details</a>?</p>

          </xsl:when>
          <xsl:otherwise>

            <p>Failed while moving record <xsl:value-of select='$form-input/sid'/> to your account.</p> 

          </xsl:otherwise>
        </xsl:choose>
        

      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>
