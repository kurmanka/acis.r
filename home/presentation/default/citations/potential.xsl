<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
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
    <xsl:param name='not-my-work-hint'/>
    
    <xsl:for-each select='$list/list-item'>
      <xsl:variable name='i'   select='concat(position(),$group)'/>
      <xsl:variable name='cnid' select='cnid/text()'/>
      <xsl:variable name='selected' select='$preselect/list-item[text()=$cnid] or 
                                            (similar &gt; number(//citation-document-similarity-preselect-threshold))'/>
      <tr>
        <td valign='top' align='left' class='citcheckbox'>
          <input type='checkbox' name='add{$i}' id='add{$i}' value=''>
            <xsl:if test='$selected'>
              <xsl:attribute name='checked'/>
            </xsl:if>
          </input>
        </td>
        <td class='citation'>
          
          <xsl:choose>
            <xsl:when test='//citation-presentation-reverse'>
              <xsl:call-template name='citation-as-in-by'>
                <xsl:with-param name='label' select='concat("add", $i)'/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name='citation'>
                <xsl:with-param name='label' select='concat("add", $i)'/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

          <input type='hidden' name='cid{$i}' value='{$cnid}'/>
          <input type='submit' name='refuse{$i}'  class='light' 
                 title='press this if it is not your work that is cited'
                 value='not my work' />

          <xsl:if test='position()=1 and $not-my-work-hint'> 
            <small style='color:red'>
              &#8592; press this <i>if it is not your work</i> that is cited, 
              and this citation will not be offered again.
            </small>
          </xsl:if>
        </td>
      </tr>
      
    </xsl:for-each>
  </xsl:template>
  

  <xsl:template name='subheader-row'>
    <xsl:param name='content'/>

    <tr>
      <td></td>
      <td class='subheader'>
        <p>
          <xsl:copy-of select='$content'/>
        </p>
      </td>
    </tr>
    
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
        <acis:tab><a ref='@citations/identified/{$doc-sid}'>identified</a></acis:tab>
        <acis:tab selected='1'>potential</acis:tab>
      </xsl:with-param>
      <xsl:with-param name='content'>
        
        <acis:form>
          
        <xsl:choose>
          <xsl:when test='$new/list-item or ($old/list-item and $form-input/old)'>
            
            <p><big>Which of these point to the above document? </big>
            <span class='instruction'
                  > &#8212; Make sure the right ones have their checkboxes checked.</span></p>
            
            <table class='citations'>
              
              <xsl:choose>
                <xsl:when test='$new/list-item'>
                  
                  <xsl:call-template name='subheader-row'>
                    <xsl:with-param name='content'><i>new citation<xsl:if test='count($new/list-item)&gt;1'>s</xsl:if></i></xsl:with-param>
                    </xsl:call-template>
                    
                </xsl:when>
              </xsl:choose>                
              
              <xsl:call-template name='citations-add-rows'>
                <xsl:with-param name='list' select='$new'/>
                <xsl:with-param name='group'></xsl:with-param>
                <xsl:with-param name='not-my-work-hint'>yes</xsl:with-param>
              </xsl:call-template>
              
              <xsl:choose>
                <xsl:when test='$old/list-item'>
                  <xsl:choose>
                    <xsl:when test='$form-input/old'>
                      
                      <xsl:call-template name='subheader-row'>
                        <xsl:with-param name='content'>
                          <i>old citation<xsl:if test='count($old/list-item)&gt;1'>s</xsl:if></i>
                        </xsl:with-param>
                      </xsl:call-template>
                      
                      <xsl:call-template name='citations-add-rows'>
                        <xsl:with-param name='list' select='$old'/>
                        <xsl:with-param name='group'>o</xsl:with-param>
                      </xsl:call-template>
                      
                    </xsl:when>
                    <xsl:otherwise>
                      
                      <xsl:call-template name='subheader-row'>
                        <xsl:with-param name='content'>
                          <i>old citations 
                          hidden <small>(<xsl:value-of select='count($old/list-item)'/>)</small></i> 
                          &#8212; <a ref='@citations/potential/{$doc-sid}?old=yes'>Want to see them?</a>
                        </xsl:with-param>
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
            
            <p>We have no citations to suggest for this document at this time.
            
            <xsl:if test='$form-input/old'>Not even a single old one.  </xsl:if>
            
            <xsl:if test='$old/list-item'>The <a ref='@citations/potential/{$doc-sid}?old=y' >old
            ones</a> you have already seen.  </xsl:if>

            <xsl:if test='$anything-interesting'>But there
            are some new citations <a ref='@citations/autosug'>for other
            documents</a>.</xsl:if></p>
            
          </xsl:otherwise>
        </xsl:choose>

        </acis:form>
        
      </xsl:with-param>
    </xsl:call-template>
   
  </xsl:template>


  <xsl:template name='no-potential'>
    
    <h1>No citations</h1>

    <p>
      We are sorry to tell you that we have no new potential
      citations data for the documents in your 
    <a ref='@research/identified' >research profile</a>.
    </p>
    
  </xsl:template>
  

  <xsl:template name='no-potential-poor'>
    
    <h1>No documents, no citations</h1>
    
    <p>
      We are sorry to tell you that we have no potential
      citations data for the documents in your research
      profile, because <a ref='@research/identified' >your
      research profile</a> is empty.
    </p>
    
  </xsl:template>
  
  <xsl:template match='/'>
    <xsl:call-template name='cit-page'>
      <xsl:with-param name='title'>potential citations</xsl:with-param>
      <xsl:with-param name='content'>

        <xsl:choose>
          <xsl:when test='$doc-sid'>
            <xsl:call-template name='potential'/>
          </xsl:when>
          <xsl:when test='not($doc-sid) and //empty-research-profile'>
            <xsl:call-template name='no-potential-poor'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name='no-potential'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>