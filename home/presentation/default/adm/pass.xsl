<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  
  <xsl:template match='/data'>
    <xsl:call-template name='appropriate-page-soft'>
      <xsl:with-param name='title' select='"admin"'/>
      <xsl:with-param name='content'  xml:space='default'>

          <h1>Access denied</h1>

      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>
