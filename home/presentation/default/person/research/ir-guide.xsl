<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  <!-- cardiff -->
  <xsl:import href='main.xsl'/>  
  <xsl:template name='research-main'>
    <h1>Research profile</h1>
    <xsl:call-template name='show-status'/>
    <h2>Accepted works</h2>     
    <p>
      <xsl:text>You now have </xsl:text>
      <a ref='@research/accepted'>
        <xsl:choose>
          <xsl:when test='$current-count &gt; 1'>
            <xsl:value-of select='$current-count'/>
            <xsl:text> works</xsl:text>
          </xsl:when>
          <xsl:when test='$current-count = 1'>
            <xsl:text> one work</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>no accepted works</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> in your profile</xsl:text>
      </a>
      <xsl:text>.</xsl:text>
    </p>
  </xsl:template>
  <xsl:variable name='to-go-options'>
    <acis:op>
      <a ref='@research' >main research page</a>
    </acis:op>
    <acis:root/>
  </xsl:variable>
</xsl:stylesheet>