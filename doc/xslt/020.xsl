<xsl:stylesheet
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:exsl="http://exslt.org/common"
 exclude-result-prefixes='exsl'
 version="1.0">

  <xsl:template match='/'>
    <index>
      <xsl:apply-templates/>
    </index>
  </xsl:template>

  <xsl:template match='text()'/>

  <xsl:template match='*[@id]'>
<xsl:text> 
   </xsl:text>    
    <item id='{@id}' file='{ancestor::text/@file}'/>
  </xsl:template>

  <xsl:template match='*[C or F]'>
    
    <xsl:variable name='name'>
      <xsl:apply-templates select='C|F' mode='text'/>
    </xsl:variable>      
    
    <xsl:variable name='id'>
      <xsl:choose>
        <xsl:when test='@id'>
          <xsl:value-of select='@id'/>
        </xsl:when>
        <xsl:when test='C[@id]'>
          <xsl:value-of select='C/@id'/>
        </xsl:when>
        <xsl:when test='C|F'>
          <xsl:value-of select='$name'/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

<xsl:text> 
   </xsl:text>    
    <item name='{$name}' id='{$id}' file='{ancestor::text/@file}'/>
    
  </xsl:template>

  <xsl:template mode='text' match='text()'>
    <xsl:copy/>
  </xsl:template>
 

</xsl:stylesheet>