<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    
    version="1.0">
  
  <xsl:template name='time-difference-in-seconds'>
    <xsl:param name='diff'/>
    
    <xsl:variable name='minutes' select='floor( number( $diff ) div 60 )' />
    <xsl:variable name='hours'   select='floor( $minutes div 60 )' />
    <xsl:variable name='days'    select='floor( $hours   div 24 )' />

    <xsl:variable name='hours-minus-days' 
                  select='$hours - $days * 24'/>
    <xsl:variable name='minutes-minus-hours' 
                  select='$minutes - $hours * 60'/>


    <xsl:choose>

      <xsl:when test='$days &gt; 0'>
        <xsl:choose>
          <xsl:when test='$days &gt; 2'>
            <xsl:value-of select='$days'/> days<xsl:text/>
          </xsl:when>
          <xsl:when test='$days &gt; 0 and $hours &gt; 2'>
            <xsl:value-of select='$days'/> day<xsl:text/>
            <xsl:if test='$days &gt; 1'>s</xsl:if>, <xsl:text/>
            <xsl:value-of select='$hours-minus-days'/> hour<xsl:text/>
            <xsl:if test='$hours-minus-days &gt; 1'>s</xsl:if>
          </xsl:when>
        </xsl:choose>
      </xsl:when>

      <xsl:when test='$hours &gt; 0'>
        <xsl:choose>
          <xsl:when test='$hours &gt; 3'>
            <xsl:value-of select='$hours'/> hours<xsl:text/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='$hours'/> hour<xsl:text/>
            <xsl:if test='$hours &gt; 1'>s</xsl:if>, <xsl:text/>
            <xsl:value-of select='$minutes-minus-hours'/> minute<xsl:text/>
            <xsl:if test='$minutes-minus-hours &gt; 1'>s</xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test='$minutes &gt; 0'>
        <xsl:value-of select='$minutes'/> minute<xsl:text/>
        <xsl:if test='$minutes &gt; 1'>s</xsl:if>
      </xsl:when>

      <xsl:when test='$diff &gt; 0'>
        <xsl:value-of select='$diff'/> second<xsl:text/>
        <xsl:if test='$diff &gt; 1'>s</xsl:if>
      </xsl:when>

      <xsl:when test='$diff &lt; 0'>
        <xsl:text>in the future</xsl:text>
      </xsl:when>

      <xsl:otherwise>
        <xsl:text>just now</xsl:text>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>


  <xsl:template match='//time-difference-in-seconds/test'>
    <td><xsl:value-of select='text()'/></td><xsl:text>
  </xsl:text>
  <td>
      <xsl:call-template name='time-difference-in-seconds'>
        <xsl:with-param name='diff' select='text()'/>
      </xsl:call-template>
  </td>
  </xsl:template>

</xsl:stylesheet>