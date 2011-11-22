<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common"
                xmlns:acis="http://acis.openlib.org"
                xmlns:html="http://www.w3.org/1999/xhtml"
                
                exclude-result-prefixes="exsl xml html acis"
                version="1.0">

  <xsl:import href='../page-universal.xsl'/>
  <xsl:variable name='doc-file' select='$response-data/filename'/>
  <xsl:variable name='doc'      select='document( $doc-file )'/>
  <xsl:variable name='doc-root' select='$doc/*'/>
  <xsl:variable name='title'    select='$doc-root/html:title/text()'/>
  <!-- ToK 2008-04-01: introduce a html:div to partially avoid namespace trouble -->
  <xsl:variable name='content'  select='$doc-root/html:div[@class="contents"]/*'/>

  <xsl:variable name='current-screen-id'>
    <xsl:value-of select='$doc-root/@name' />
  </xsl:variable>

  <xsl:template match='html:title|acis:content' mode='pass'>
    <xsl:apply-templates mode='pass'/>
  </xsl:template>

  <xsl:template match='*' mode='pass'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:apply-templates mode='pass'/>
    </xsl:copy>
  </xsl:template>
  

  <xsl:template match='/'>
    <xsl:call-template name='appropriate-page-soft'>
      <xsl:with-param name='title' select='$title'/>
      <xsl:with-param name='content'>
        <xsl:copy-of select='$doc-root/html:style'/>
        <xsl:copy-of select='$doc-root/html:script'/>
        <xsl:copy-of select='$content'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>


  