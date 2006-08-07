<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes='exsl xml'
    version="1.0">
 
  <xsl:import href='general.xsl'/>
  <xsl:import href='identified.xsl'/>

  <xsl:variable name='current-screen-id'>citations/refused</xsl:variable>

  <xsl:template name='refused'>

    <h1>Refused citations</h1>

    <style>
span.instruction { color: #888; }
a.citing { font-size: smaller; }
input.light { 
  font-weight: normal;
  font-size: smaller;
}
    </style>
    
       
    <xsl:choose>
      <xsl:when test='$response-data/refused/list-item'>
        
        <form>
          
          <p>These following citations are refused.  For
          them you clicked the [not my work] button.</p>

          <table>
            <xsl:call-template name='citations-del-rows'>
              <xsl:with-param name='list' select='$response-data/refused'/>
              <xsl:with-param name='group'></xsl:with-param>
            </xsl:call-template>
          </table>

<p style='margin-top: 1em;'>
  <input type='submit' class='inputsubmit important'
   value='DELETE THESE CITATIONS' />
</p>
        </form>

      </xsl:when>
      <xsl:otherwise>
        
        <form>
              <p>No citations are currently refused.  But
              you may refuse some by clicking [not my work]
              button when you are suggested some wrong
              items.</p>
        </form>
            
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match='/'>
    <xsl:call-template name='cit-page'>
      <xsl:with-param name='title'>refused citations</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='refused'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>