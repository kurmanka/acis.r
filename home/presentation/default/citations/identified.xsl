<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">
 
  <xsl:import href='general.xsl'/>
  <xsl:import href='potential.xsl'/>

  <!-- ToK 2008-04-06: was citations/identified -->
  <xsl:variable name='current-screen-id'>citations/identified</xsl:variable>
  
  <xsl:variable name='doc-sid'   select='$response-data/document/sid/text()'/>
  
  <xsl:template name='citations-del-rows'>
    <xsl:param name='list'/>
    <xsl:param name='group' select='""'/>
    
    <xsl:for-each select='$list/list-item'>
      <xsl:variable name='i'   select='concat(position(),$group)'/>
      <tr class='citation'>
        <td valign='top' align='left' class='citcheckbox'>
          <input type='checkbox' name='del{$i}' id='del{$i}' value=''/>
        </td>
        <td class='citation'>
          <xsl:call-template name='citation'>
            <xsl:with-param name='label' select='concat( "del", $i )'/>
          </xsl:call-template>
          
          <input type='hidden' name='cid{$i}' value='{cnid/text()}'/>
        </td>
      </tr>
      
    </xsl:for-each>
  </xsl:template>
  

  
  
  <xsl:template name='identified'>
    
    <h1>Citations for your document: identified</h1>
    
    <xsl:call-template name='show-status'/>
    
    <xsl:call-template name='document-with-navigation'/> <!-- see potential.xsl -->
    
    <style>
      span.instruction { color: #888; }
      a.citing {  }
      input.light { 
      font-weight: normal;
      font-size: smaller;
      }
    </style>
    
    <xsl:call-template name='tabset'>
      <xsl:with-param name='id'>tabs</xsl:with-param>
      <xsl:with-param name='tabs'>
        <acis:tab selected='1'>identified</acis:tab>
        <acis:tab><a ref='@citations/potential/{$doc-sid}'>potential</a></acis:tab>
      </xsl:with-param>
      <xsl:with-param name='content'>
        
        <xsl:choose>
          <xsl:when test='$response-data/identified/list-item'>
            
        <acis:form>

          <xsl:if test='count($response-data/identified/list-item) &gt; 1'>
            <p>These citations are identified as pointing to this document:</p>
          </xsl:if>
          <xsl:if test='count($response-data/identified/list-item) = 1'>
            <p>This citation is identified as pointing to this document:</p>
          </xsl:if>
          
          <table class='citations'>

            <xsl:choose>
              <xsl:when test='$response-data/identified/list-item'>
              </xsl:when>
            </xsl:choose>                
            
            <xsl:call-template name='citations-del-rows'>
              <xsl:with-param name='list' select='$response-data/identified'/>
              <xsl:with-param name='group'></xsl:with-param>
            </xsl:call-template>
          </table>
          
          <p style='margin-top: 1em;'>
            <input type='submit' class='inputsubmit important'
                   value='REMOVE THESE CITATIONS' />
            <input type='hidden' name='dsid' value='{$doc-sid}'/>
          </p>
        </acis:form>
        
          </xsl:when>
          <xsl:otherwise>
            
            <form>
              <p>No citations are identified as pointing to this document.</p>
            </form>
            
          </xsl:otherwise>
        </xsl:choose>
        
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template>
  
  <xsl:template match='/'>
    <xsl:call-template name='cit-page'>
      <xsl:with-param name='title'>identified citations</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='identified'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>