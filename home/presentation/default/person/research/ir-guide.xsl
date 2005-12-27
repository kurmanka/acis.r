<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl xml x'
  xmlns:x='http://x'
  version="1.0">

  <xsl:import href='main.xsl'/>

  
  <xsl:template name='research-main'>

    <h1>Research profile</h1>

    <xsl:call-template name='show-status'/>

      <h2>Identified works</h2>
      
      <p>
            <xsl:text>You now have </xsl:text>
            <a ref='@research/identified'>
              <xsl:choose>
                <xsl:when test='$current-count &gt; 1'>
                  <xsl:value-of select='$current-count'/>
                  <xsl:text> works</xsl:text>
                </xsl:when>
                <xsl:when test='$current-count = 1'>
                  <xsl:text> one work</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>no identified works</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text> in your profile</xsl:text>
            </a>
            <xsl:text>.</xsl:text>
      </p>


  </xsl:template>

  

  <xsl:variable name='to-go-options'>
    <op><a ref='@research' >main research page</a></op>
    <root/>
  </xsl:variable>


</xsl:stylesheet>