<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">

  <xsl:template name='indent'>
    <xsl:param name='tail' select='""'/>
    
    <xsl:variable name='line'>
      <xsl:choose>
        <xsl:when test='contains( $tail, "&#x0a;" )'>
          <xsl:value-of select='substring-before( $tail, "&#x0a;" )'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='$tail'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name='nexttail' select='substring-after( $tail, "&#x0a;" )' />

    <xsl:text> </xsl:text>
    <xsl:value-of select='$line'/>

    <xsl:if test='string-length($nexttail)'>
<xsl:text>
</xsl:text>
      <xsl:call-template name='indent'>
        <xsl:with-param name='tail' select='$nexttail'/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>