<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">

  <xsl:import href='main.xsl' />
  <xsl:import href='listings.xsl' />
  <xsl:import href='research_common.xsl' />
  <xsl:import href='../../widgets.xsl' />

  <xsl:variable name='parents'>
    <acis:par id='research/main'/>
  </xsl:variable>
  <xsl:variable name='the-screen'>autosuggest</xsl:variable>
  <xsl:variable name='items-count' 
                select='$suggestions-count'/>
  <xsl:variable name='current-screen-id'>research/autosuggest-all</xsl:variable>
  <xsl:variable name='form-target'>@research/autosuggest-all</xsl:variable>
  <xsl:variable name='this-chunk-size'
                select='$items-count'/>
  <xsl:variable name='more-to-follow' 
                select='$items-count &gt; $this-chunk-size'/>
  <xsl:variable name='more-to-follow-count' 
                select='$items-count - $this-chunk-size'/>
  <xsl:variable name='any-suggestions' 
                select='count( //suggest/list-item/list/list-item )'/>
  <xsl:variable name='back-search-running'
                select='//running'/>
  <xsl:variable name='back-search-started'
                select='//auto-search-started'/>
  <xsl:variable name='back-search-finished'
                select='//auto-search-finished'/>
  <xsl:variable name='back-search-not-needed'
                select='//auto-search-not-needed'/>
  <xsl:variable name='back-search-start-failed'
                select='//auto-search-start-failed'/>

  <xsl:variable name='started-that-ago'>
    <xsl:variable name='search-start'
                  select='//last-autosearch-time/text()'/>
    <xsl:variable name='now'
                  select='//current-time-epoch/text()'/>
    <xsl:choose>
      <xsl:when test='$back-search-running and $now and $search-start'>
        <xsl:variable name='secdiff'
                      select='$now - $search-start'/>
        <xsl:value-of select='round( $secdiff div 60 )' />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='false()'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:template name='the-suggestions'>
    <xsl:call-template name='tabset'>
      <xsl:with-param name='id' select='"tabs"'/>
      <xsl:with-param name='tabs'>
        <xsl:copy-of select='$the-suggestion-tabs'/>
      </xsl:with-param>
      <xsl:with-param name='content'>        
        <acis:form screen='{$form-target}'
                   xsl:use-attribute-sets='form' 
                   class='important'
                   id='suggestions'
                   name='suggestions'>
	  <div>
	    <input type='hidden' 
                   name='mode'   
                   value='add'/>
            <input type='hidden' 
                   name='source' 
                   value='suggestions'/>
          </div>          
          <xsl:copy-of select='$suggestions-table-introduction'/>
	  <xsl:call-template name='suggestions-table'/>	  
	  <!-- the bottom of the table -->
	  <xsl:if test='count( $suggestions/list-item/list/list-item[id] )'>
	    <table width="100%" class='suggestions resources'>
              <tr>
                <td align="right">
                  <button type='submit'
                         name='save_and_exit' 
                         class='important'
                         title='Save all the choices you made above and stop working on suggestions.'
                         >Process selections</button>
                </td>
<!--[if-config(learn-via-daemon)]-->
                <td id='refuse_all_button' align='right'>
                  <input type='button' 
                         onclick='refuse_all_undecided()' 
                         value='Refuse all undecided suggestions'
                         title='Refuse all documents that are undecided at this time.'/>	      
                </td>
<!--[end-if]-->
              </tr>
            </table>
          </xsl:if>          
          <xsl:if test='not(count( $suggestions/list-item/list/list-item[id] ))'>
            <xsl:if test='$back-search-running'>
              <p>
                <a ref='@research/autosuggest' >
                  <xsl:text>Reload this page to check for more suggestions</xsl:text>
                </a>
              </p>
            </xsl:if>
          </xsl:if>
        </acis:form>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match='/data'>
    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>autosearch suggestions</xsl:with-param>
      <xsl:with-param name='content'>
        <acis:script-onload>
          <xsl:text>pitman_prepare(</xsl:text>
          <xsl:value-of select='$below-me-propose-refuse'/>
          <xsl:text>,</xsl:text>
          <xsl:value-of select='$above-me-propose-accept'/>
          <xsl:text>);</xsl:text>
        </acis:script-onload>
        <xsl:call-template name='the-contributions'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
