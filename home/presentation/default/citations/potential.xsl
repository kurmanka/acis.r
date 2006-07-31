<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes='exsl xml'
    version="1.0">
 
  <xsl:import href='general.xsl'/>

  <xsl:variable name='current-screen-id'>citations/potential</xsl:variable>

  <xsl:variable name='doc-sid'   select='$response-data/document/sid/text()'/>
  <xsl:variable name='preselect' select='$response-data/preselect-citations'/>

  <xsl:template name='citations-add-rows'>
    <xsl:param name='list'/>
    <xsl:param name='group' select='""'/>
    
    <xsl:for-each select='$list/list-item'>
      <xsl:variable name='i'   select='concat(position(),$group)'/>
      <xsl:variable name='cid' select='concat(srcdocsid/text(), "-", checksum/text())'/>
      <xsl:variable name='selected' select='$preselect/list-item[text()=$cid] or 
                                            (similar &gt; number(//citation-document-similarity-preselect-threshold))'/>
      <xsl:variable name='selected2'>
        <xsl:choose>
          <xsl:when test='$preselect'>
            <xsl:value-of select='$preselect/list-item[text()=$cid]'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='similar &gt; number(//citation-document-similarity-preselect-threshold)'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <tr>
        <td valign='top' align='center'>
          <input type='checkbox' name='add{$i}' id='add{$i}' value=''>
            <xsl:if test='$selected'>
              <xsl:attribute name='checked'/>
            </xsl:if>
          </input>
        </td>
        <td>
          <label for='add{$i}' ><xsl:value-of select='ostring'/></label>
          <xsl:text> </xsl:text>
          <a class='citing' href='{srcdocdetails}'>citing document</a>
          
          <br/> 
          <input type='hidden' name='cid{$i}' value='{cid}'/>
          <input type='submit' name='refuse{$i}'  class='light' 
                 title='press this if it is not your work that is cited'
                 value='not my work' 
                 />
        </td>
      </tr>
      
    </xsl:for-each>
  </xsl:template>
  

  <xsl:template name='subheader-row'>
    <xsl:param name='content'/>

    <tr><td width='4%'></td><td colspan_='2' style='padding-bottom: 6px;'><p
    style='border-bottom: 1px solid #ccc;margin:0;'><xsl:copy-of select='$content'/></p></td></tr>

  </xsl:template>


  <xsl:template name='potential'>

    <h1>Citations for your document: potential</h1>

    <p><small>A document from your <a ref='@research/identified'>research profile</a>:</small></p>
    
    <table style='margin-bottom:1.3em;'><tr>
      
      <td>Prev</td>
      <td style='padding:0 1em 0 1em'>
        <big>
        <!-- document -->
        <xsl:call-template name='present-resource'>
          <xsl:with-param name='resource' select='$response-data/document'/>
        </xsl:call-template>
        </big>
      </td>
      <td>Next</td>
      
    </tr></table>


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
        <tab><a ref='@citations/identified/{$doc-sid}'>identified</a></tab>
        <tab selected='1'>potential</tab>
      </xsl:with-param>
      <xsl:with-param name='content'>
        
        <form >
          <p><big>Which of these point to the above document? </big>
          <span class='instruction'
                > - Make sure the right ones have their checkboxes checked.</span></p>

          <table>

            <xsl:choose>
              <xsl:when test='$response-data/potential_new/list-item'>

                    <xsl:call-template name='subheader-row'>
                      <xsl:with-param name='content'><i>new citations</i></xsl:with-param>
                    </xsl:call-template>

              </xsl:when>
            </xsl:choose>                

            <xsl:call-template name='citations-add-rows'>
              <xsl:with-param name='list' select='$response-data/potential_new'/>
              <xsl:with-param name='group'></xsl:with-param>
            </xsl:call-template>

            <xsl:choose>
              <xsl:when test='$response-data/potential_old/list-item'>
                <xsl:choose>
                  <xsl:when test='$form-input/old'>
                    
                    <xsl:call-template name='subheader-row'>
                      <xsl:with-param name='content'><i>old citations</i></xsl:with-param>
                    </xsl:call-template>

                    <xsl:call-template name='citations-add-rows'>
                      <xsl:with-param name='list' select='$response-data/potential_old'/>
                      <xsl:with-param name='group'>o</xsl:with-param>
                    </xsl:call-template>

                  </xsl:when>
                  <xsl:otherwise>

                    <xsl:call-template name='subheader-row'>
                      <xsl:with-param name='content'><i>old citations hidden</i> -- <a ref='?old=yes'>Want to see them?</a></xsl:with-param>
                    </xsl:call-template>

                  </xsl:otherwise>
                </xsl:choose>

              </xsl:when>
              <xsl:otherwise>

                <xsl:choose>
                  <xsl:when test='$form-input/old'>

                    <xsl:call-template name='subheader-row'>
                      <xsl:with-param name='content'><i>old citations requested -- but there's none</i></xsl:with-param>
                    </xsl:call-template>
                    
                  </xsl:when>
                </xsl:choose>

              </xsl:otherwise>
            </xsl:choose>

          </table>


<table style='margin-top: 1em;'>
<tr>
<td width='50%'>
  <input type='submit' class='inputsubmit important'
   value='SUBMIT FORM / ADD THESE CITATIONS' />
</td>

<td width='50%' >

  <!-- XXX TODO: this should not be see always -->
  <input type='checkbox' name='moveon' id='moveon' CHECKED='1'/> 
  <label for='moveon'>Show next document with new citations</label>
</td>

</tr>
</table>


        </form>
        
      </xsl:with-param>
    </xsl:call-template>
   
  </xsl:template>

  <xsl:template match='/'>
    <xsl:call-template name='cit-page'>
      <xsl:with-param name='title'>potential citations</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='potential'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>