<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='../page-universal.xsl' />

  <xsl:import href='affiliations.xsl' />

  <xsl:variable name='current-screen-id'>affiliations-ir-guide</xsl:variable>


  <xsl:variable name='to-go-options'>
    <op><a ref='@affiliations'>back to affiliations</a></op>
    <root/>
  </xsl:variable>


  <!--    v a r i a b l e s    -->

  <xsl:variable name='affiliations' select='$response-data/affiliations'/>
  <xsl:variable name='search'       select='$response-data/institution-search'/> 
  <xsl:variable name='found-items'  select='$search/results'/> 
  <xsl:variable name='search-what'  select='$form-values/search-what/text()'/> 




  <!--  main affiliations screen template -->

  <xsl:template name='the-affiliations'>


    <h1>Affiliations</h1>

    <xsl:call-template name='show-status'/>


    <h2>Now your affiliations:</h2>
    
    <xsl:choose>
      <xsl:when test='count($affiliations/list-item)'>
        
        <ul>
          
          <xsl:for-each select='$affiliations/list-item'>
            
            <li>
              <span class='title'><xsl:value-of select='name'/></span>
              
              <xsl:if test='name-english/text()'>
                <br/>English: <span class='title'
                ><xsl:value-of select='name-english/text()'/></span
                >
              </xsl:if>
              
        </li>
          </xsl:for-each>
          
        </ul>
        
      </xsl:when>
      <xsl:otherwise>
        
        <p>None.</p>

      </xsl:otherwise>
    </xsl:choose>

        
  </xsl:template>



    
</xsl:stylesheet>