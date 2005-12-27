<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
  
  <xsl:import href='page.xsl'/>
  <xsl:import href='profile-show.xsl'/>

  <xsl:variable name='current-screen-id'>personal-overview</xsl:variable>



  <xsl:template match='/data'>

    <xsl:variable name='person' select='$response-data/record'/>

    <xsl:call-template name='user-page'>
      <xsl:with-param name='title'
>current state of the profile: <xsl:value-of select='$person/name/full'/></xsl:with-param>
      <xsl:with-param name='content' xml:space='preserve'>
        
        <xsl:call-template name='personal-profile' xml:space='default'>
          <xsl:with-param name='person' select='$person'/>
        </xsl:call-template>
        
      </xsl:with-param>
    </xsl:call-template> <!-- /page -->
    
  </xsl:template>

</xsl:stylesheet>

