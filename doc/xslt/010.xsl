<xsl:stylesheet
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:exsl="http://exslt.org/common"
 exclude-result-prefixes='exsl'
 version="1.0">

  <xsl:output method='xml'/>

  <xsl:template match='/'>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match='text'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:text>
      </xsl:text>
      <xsl:apply-templates/>
      <xsl:text>
</xsl:text>
    </xsl:copy>
<xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match='*'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match='text()'>
    <xsl:copy/>
  </xsl:template>


  <xsl:template match='p[@id]'>
    <xsl:copy>
      <xsl:copy-of select='@id'/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>


  <xsl:template match='h1|h2|h3|h4|h5|h6'>

<xsl:text>
   </xsl:text>

    <xsl:copy>
      <xsl:attribute name='id'><xsl:value-of select='generate-id(.)'/></xsl:attribute>
      <xsl:copy-of select='@*'/>
      <xsl:if test='C'>
        <xsl:call-template name='element-with-C-attr'/>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:copy>


  </xsl:template>

  <xsl:template match='ignore'/>


  <xsl:template match='*[C]'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:call-template name='element-with-C-attr'/>

      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>


  <xsl:template name='element-with-C-attr'>
    <xsl:variable name='CCC'>
      <xsl:apply-templates select='C/text()' mode='text'/>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test='@id'/>
      <xsl:when test='C[@id]'>
        <xsl:attribute name='id'><xsl:value-of select='C/@id'/></xsl:attribute>
      </xsl:when>
      <xsl:when test='C'>
        <xsl:attribute name='id'>
          <xsl:value-of select='translate($CCC,"/:.","")'/>
        </xsl:attribute>
<!--
-->
      </xsl:when>
    </xsl:choose>
    
    <xsl:attribute name='C'><xsl:value-of select='C/text()'/></xsl:attribute>
  </xsl:template>


  <xsl:template match='*[F]'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:call-template name='element-with-F-attr'/>

      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>


  <xsl:template name='element-with-F-attr'>
    <xsl:variable name='CCC'>
      <xsl:apply-templates select='F/text()' mode='text'/>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test='@id'/>
      <xsl:when test='F'>
        <xsl:attribute name='id'>
          <xsl:value-of select='translate($CCC,"/.:","")'/>
        </xsl:attribute>
      </xsl:when>
    </xsl:choose>
    
<!--    <xsl:attribute name='C'><xsl:value-of select='C/text()'/></xsl:attribute> -->
  </xsl:template>



</xsl:stylesheet>