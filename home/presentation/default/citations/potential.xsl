<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes='exsl xml'
    version="1.0">
 
  <xsl:import href='general.xsl'/>

  <xsl:variable name='doc-sid'   select='$response-data/document/sid/text()'/>
  <xsl:variable name='preselect' select='$response-data/preselect-citations'/>
  <xsl:variable name='prev'      select='$response-data/previous/text()'/>
  <xsl:variable name='next'      select='$response-data/next/text()'/>
  <xsl:variable name='anything-interesting' 
                                 select='$response-data/anything-interesting'/>
  <xsl:variable name='most-interesting-doc' 
                                 select='$response-data/most-interesting-doc'/>

  <xsl:variable name='new'       select='$response-data/potential_new'/>
  <xsl:variable name='old'       select='$response-data/potential_old'/>

  <xsl:variable name='current-screen-id'>
    <xsl:choose>
      <xsl:when test='$most-interesting-doc'>citations/autosug</xsl:when>
      <xsl:otherwise>citations/potential</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>


  <xsl:template name='citations-add-rows'>
    <xsl:param name='list'/>
    <xsl:param name='group' select='""'/>
    
    <xsl:for-each select='$list/list-item'>
      <xsl:variable name='i'   select='concat(position(),$group)'/>
      <xsl:variable name='cid' select='concat(srcdocsid/text(), "-", checksum/text())'/>
      <xsl:variable name='selected' select='$preselect/list-item[text()=$cid] or 
                                            (similar &gt; number(//citation-document-similarity-preselect-threshold))'/>
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
          <input type='hidden' name='cid{$i}' value='{$cid}'/>
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


  <xsl:template name='document-with-navigation'>

    <style>
td.docnav { color: #999; }
    </style>

    <p><small>A document from your <a ref='@research/identified'>research profile</a>:</small></p>
    
    <table style='margin-bottom:1.3em;'><tr>
      
      <td class='docnav'><xsl:choose>
        <xsl:when test='$prev'><a ref='@citations/potential/{$prev}'>Prev</a></xsl:when>
        <xsl:otherwise>Prev</xsl:otherwise>
      </xsl:choose></td>
      <td style='padding:0 1.5em 0 1.5em'>
        <big>
        <!-- document -->
        <xsl:call-template name='present-resource'>
          <xsl:with-param name='resource' select='$response-data/document'/>
        </xsl:call-template>
        </big>
      </td>
      <td class='docnav'><xsl:choose>
        <xsl:when test='$next'><a ref='@citations/potential/{$next}'>Next</a></xsl:when>
        <xsl:otherwise>Next</xsl:otherwise>
      </xsl:choose></td>
      
    </tr></table>

  </xsl:template>


  <xsl:template name='potential'>

    <h1>Citations for your document: potential</h1>

    <xsl:call-template name='show-status'/>
    <xsl:call-template name='document-with-navigation'/>

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
       
        <form>

        <xsl:choose>
          <xsl:when test='$new/list-item or ($old/list-item and $form-input/old)'>

          <p><big>Which of these point to the above document? </big>
          <span class='instruction'
                > - Make sure the right ones have their checkboxes checked.</span></p>

          <table>

            <xsl:choose>
              <xsl:when test='$new/list-item'>

                    <xsl:call-template name='subheader-row'>
                      <xsl:with-param name='content'><i>new citations</i></xsl:with-param>
                    </xsl:call-template>

              </xsl:when>
            </xsl:choose>                

            <xsl:call-template name='citations-add-rows'>
              <xsl:with-param name='list' select='$new'/>
              <xsl:with-param name='group'></xsl:with-param>
            </xsl:call-template>

            <xsl:choose>
              <xsl:when test='$old/list-item'>
                <xsl:choose>
                  <xsl:when test='$form-input/old'>
                    
                    <xsl:call-template name='subheader-row'>
                      <xsl:with-param name='content'><i>old citations</i></xsl:with-param>
                    </xsl:call-template>

                    <xsl:call-template name='citations-add-rows'>
                      <xsl:with-param name='list' select='$old'/>
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
  <input type='hidden' name='dsid' value='{$doc-sid}'/>
</td>

<td width='50%' >

  <xsl:if test='($most-interesting-doc and $next) or (not($most-interesting-doc) and $anything-interesting)'>
    <input type='checkbox' name='moveon' id='moveon' CHECKED=''/> 
    <label for='moveon'>Show next document with new citations</label>
  </xsl:if>
</td>

</tr>
</table>

          </xsl:when>
          <xsl:otherwise>

            <p>No citations to offer. 
            
            <xsl:if test='$form-input/old'>Not even a single old one.  </xsl:if>

            <xsl:if test='$old/list-item'>The <a
            href='?old=y'>old ones</a> you have already
            seen.  </xsl:if>

            <xsl:if test='$anything-interesting'>But there
            are some new citations <a
            ref='@citations/autosug'>for other
            documents</a>.</xsl:if></p>
            
          </xsl:otherwise>
        </xsl:choose>

        </form>
        
      </xsl:with-param>
    </xsl:call-template>
   
  </xsl:template>


  <xsl:template name='no-potential'>

    <h1>No document, no citations</h1>

    <p>No potential citations.</p>

  </xsl:template>

  <xsl:template match='/'>
    <xsl:call-template name='cit-page'>
      <xsl:with-param name='title'>potential citations</xsl:with-param>
      <xsl:with-param name='content'>

        <xsl:choose>
          <xsl:when test='$doc-sid'>
            <xsl:call-template name='potential'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name='no-potential'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>