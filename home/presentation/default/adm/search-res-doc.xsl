<!--   This file is part of the ACIS presentation template-set.   -->
  
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">  

  <xsl:import href='../page.xsl'/>

  <xsl:variable name='result' select='$response-data/result'/>
  <xsl:variable name='docs' select='$result/data'/>
  

  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>documents search results</xsl:with-param>
      
      <xsl:with-param name='content'>

<h1>Documents search</h1>

<p><small>query:</small> &#160;
<xsl:value-of select='$result/query'/></p>

<xsl:if test='$result/problem'>

  <p><big>
  <xsl:for-each select='$result/problem/*'>
    <xsl:value-of select='text()'/>
  </xsl:for-each>
  </big></p>

</xsl:if>

<ol>
  <xsl:for-each select='$docs/list-item'>
  <li>

    <span title='type: {type}'>
      <xsl:choose>
        <xsl:when test='url-about/text()'>
          <a href='{url-about}'><xsl:value-of select='title'/></a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='title'/> 
        </xsl:otherwise>
      </xsl:choose>
      
      <xsl:if test='authors'>
        by <xsl:value-of select='authors'/> 
      </xsl:if>

      <xsl:if test='editors'>
        edited by <xsl:value-of select='editors'/> 
      </xsl:if>

      <xsl:if test='role and role != "author"'>
        role: <xsl:value-of select='role'/>
      </xsl:if>
      
      (id:&#160;<xsl:value-of select='id'/>)
    </span>
    </li>
  </xsl:for-each>
</ol>
       
      </xsl:with-param>

    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>