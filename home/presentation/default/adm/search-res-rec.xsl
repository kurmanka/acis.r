<!--   This file is part of the ACIS presentation template-set.   -->
  
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">  
  
  <xsl:import href='../page.xsl'/>
  
  <xsl:variable name='result' select='$response-data/result'/>
  <xsl:variable name='items' select='$result/data/list-item'/>
  

  <xsl:template match='/data'>
    <xsl:call-template name='page'>
      
      <xsl:with-param name='title'>records search results</xsl:with-param>
      
      <xsl:with-param name='content'>
        
        <h1>Records search</h1>
        
        <p>
          <small>query:</small> &#160;
          <xsl:value-of select='$result/query'/>
          <br/><small>key:</small> &#160;
          <xsl:value-of select='$result/key'/>
        </p>
        
        <xsl:if test='$result/problem'>
          
          <p>
            <big>
              <xsl:for-each select='$result/problem/*'>
                <xsl:value-of select='text()'/>
              </xsl:for-each>
          </big>
          </p>
          
        </xsl:if>
        
        <ol>
          <xsl:for-each select='$items'>
            <li>
              
              <span title='{namefull}' class='name'>
                <xsl:value-of select='namelast'/>
              </span>
              
              <span title='{userdata_file}'>
                [<xsl:value-of select='owner'/>]
              </span>
              
              <a href='{profile_url}'>profile</a>, shortid: <xsl:value-of select='shortid'/>
              
            </li>
          </xsl:for-each>
        </ol>
        
      </xsl:with-param>
      
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>