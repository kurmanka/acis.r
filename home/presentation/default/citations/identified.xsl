<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes='exsl xml'
    version="1.0">
 
  <xsl:import href='general.xsl'/>
  <xsl:import href='potential.xsl'/>

  <xsl:variable name='current-screen-id'>citations/identified</xsl:variable>

  <xsl:variable name='doc-sid'   select='$response-data/document/sid/text()'/>

  <xsl:template name='citations-del-rows'>
    <xsl:param name='list'/>
    <xsl:param name='group' select='""'/>
    
    <xsl:for-each select='$list/list-item'>
      <xsl:variable name='i'   select='concat(position(),$group)'/>
      <xsl:variable name='cid' select='concat(srcdocsid/text(), "-", checksum/text())'/>
      <tr>
        <td valign='top' align='center'>
          <input type='checkbox' name='del{$i}' id='del{$i}' value=''/>
        </td>
        <td>
          <label for='del{$i}' ><xsl:value-of select='ostring'/></label>
          <xsl:text> </xsl:text>
          <a class='citing' href='{srcdocdetails}'>citing document</a>
          
          <input type='hidden' name='cid{$i}' value='{$cid}'/>
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
a.citing { font-size: smaller; }
input.light { 
  font-weight: normal;
  font-size: smaller;
}
    </style>
    
    <xsl:call-template name='tabset'>
      <xsl:with-param name='id'>tabs</xsl:with-param>
      <xsl:with-param name='tabs'>
        <tab selected='1'>identified</tab>
        <tab><a ref='@citations/potential/{$doc-sid}'>potential</a></tab>
      </xsl:with-param>
      <xsl:with-param name='content'>
        
        <xsl:choose>
          <xsl:when test='$response-data/identified/list-item'>
            
        <form>

          <p>These citations are identified as pointing to this document:</p>

          <table>

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
   value='DELETE THESE CITATIONS' />
  <input type='hidden' name='dsid' value='{$doc-sid}'/>
</p>
        </form>

          </xsl:when>
          <xsl:otherwise>

            <form>
              <p>No citations identified as pointing to this document.</p>
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