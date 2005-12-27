<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                version="1.0"
                xmlns:exsl="http://exslt.org/common"
                exclude-result-prefixes='exsl xml'
                >

  <xsl:template name='tabset'>
    <xsl:param name='id'/>
    <xsl:param name='tabs'/>
    <xsl:param name='content'/>
    
    <div class='tabset' id='{$id}'>
      
      <div class='tabs'>

        <xsl:for-each select='exsl:node-set($tabs)//tab'>
          <xsl:choose>
            <xsl:when test='@selected'>
              <div class='current'>
                <xsl:copy-of select='*|text()'/>
              </div>
            </xsl:when>
            <xsl:otherwise>
              <div class='tab'>
                <xsl:copy-of select='*|text()'/>
              </div>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>

        <div class='last'>&#160;</div>

      </div>

      <xsl:copy-of select='$content'/>
      
    </div>

  </xsl:template>

</xsl:stylesheet>