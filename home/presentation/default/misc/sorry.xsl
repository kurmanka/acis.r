<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='../page.xsl'/>
  
  <xsl:template match='/'>

    <xsl:call-template name='page'>
      <xsl:with-param name='title'>problem</xsl:with-param>
      <xsl:with-param name='body-title'>Sorry</xsl:with-param>
      <xsl:with-param name='content'>

        <xsl:call-template name='show-errors'/>

        <p>Contact system administrator if you need help with this problem.</p>

      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>