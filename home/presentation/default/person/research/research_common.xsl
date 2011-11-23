<?xml version='1.0' encoding='utf-8'?>
<xsl:stylesheet
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:exsl='http://exslt.org/common'
    xmlns:acis='http://acis.openlib.org'
    xmlns:html='http://www.w3.org/1999/xhtml'
    
    exclude-result-prefixes='exsl xml html acis'
    version='1.0'>
  <!-- part of cardiff -->
  <xsl:variable name='chunk-size' select='$config/chunk-size/text()'/>
  <!-- pitman project -->
  <xsl:variable name='above-me-propose-accept'
                select='$config/above-me-propose-accept/text()'/>
  <xsl:variable name='below-me-propose-refuse'
                select='$config/below-me-propose-refuse/text()'/>
  <!-- table header for the description of the item -->
  <xsl:variable name='item-description-header'>
    <th class='desc'>
      <xsl:text>Item description</xsl:text>
    </th>
  </xsl:variable>
  <!-- table header saying "by you"-->
  <xsl:variable name='by-you-header'>
    <th style='width: 2em'>yours?</th>
  </xsl:variable>
  <!-- input elements for submission -->
  <xsl:variable name='save-and-continue-input'>
    <input type='submit' 
           name='save_and_continue' 
           value='Process selections' 
           title='Process all the choices you have made and return to this screen.'/>         
  </xsl:variable>
  <xsl:variable name='save-and-next-chunk-input'>
    <input type='submit' 
           name='save_and_continue_next_chunk' 
           value='Process selections and move to next screen' 
           title='Process all the choices you have made, and move to the next screen.'/>         
  </xsl:variable>
  <xsl:variable name='save-and-exit-input'>
    <input type='submit' 
           name='save_and_exit' 
           value='Process selections and move to research' 
           title='Process all the choices you have made and go the main research screen.'/>         
  </xsl:variable>
  <xsl:template name='suggestions-sublist-explanation'>
    <xsl:param name='list'/>
    <xsl:for-each select='$list'>
      <xsl:choose xml:space='default'>
        <xsl:when test='reason = "exact-name-variation-match"'>
          <xsl:text>We found, by exact matching </xsl:text>
          <a ref='@name?back={$request-screen}' >
            <xsl:text>your name and its variations</xsl:text>
          </a> 
          <xsl:text> among the document author and editor names:</xsl:text>
        </xsl:when>
        <xsl:when test='reason = "name-variation-part-match" or reason = "exact-name-variation-part-match"'>
          <xsl:text>We found, by a partial match of </xsl:text>
          <a ref='@name?back={$request-screen}'>
            <xsl:text>your name and its variations</xsl:text>
          </a>
          <xsl:text> among the document creators’ names:</xsl:text>
        </xsl:when>
        <xsl:when test='reason = "exact-person-id-match"'>          
          <xsl:text>Found because the document’s metadata pointed to your personal record through its short-id (</xsl:text>
          <code class='id'>
            <xsl:value-of select='$record-sid'/>
          </code>
          <xsl:text>):</xsl:text>
        </xsl:when>
        <xsl:when test='reason = "exact-email-match"'>          
          <xsl:text>Found by email address:</xsl:text>
        </xsl:when>
        <xsl:when test='reason = "approximate-name-variation-match" or reason = "approximate-1" or reason = "approximate-2" '>
          <xsl:text>Found by approximate matching your name and its variations to document authors names.  Should have caught most misspelled occurrences:</xsl:text>
        </xsl:when>
        <xsl:when test='reason = "surname-part-match"'>
          <xsl:text>The documents in whose description we found your surname:</xsl:text>
        </xsl:when>
        <xsl:when test='reason = "fuzzy-name-variation-match"'>
          <xsl:text>Found by approximate matching your name and its variations to document authors names.  Should have caught most misspelled occurrences:</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Some more research items for your review:</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  <xsl:variable name='search-status'>
    <xsl:choose>
      <xsl:when test='$back-search-started'>
        <xsl:text> We have just started the automatic search for your works.</xsl:text>
        <xsl:text> While we are searching, you can see what’s found and</xsl:text>
        <xsl:text> make decisions about it. The page will reload soon and you might see</xsl:text>
        <xsl:text> the first results.</xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-running'>
        <xsl:text>The automatic search for your works is going on. </xsl:text>
        <xsl:if test='number( $started-that-ago ) &gt; 1'>
          <xsl:text>(Started </xsl:text>
          <xsl:value-of select='$started-that-ago'/>
          <xsl:text>minutes ago.)</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:when test='$back-search-finished'>
        <xsl:text>The automatic search for your works has finished. </xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-start-failed'>
        <xsl:text>We tried to start the automatic search for your works, but it failed.  Please, try again later. </xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-not-needed'>        
        <xsl:text>Last time we ran automatic search for your works </xsl:text>
        <xsl:call-template name='time-difference-in-seconds'>
          <xsl:with-param name='diff' 
                          select='number( //data/current-time-epoch/text() ) - number( //data/last-autosearch-time/text() )'/>
          </xsl:call-template> ago.<xsl:text/>          
      </xsl:when>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name='new-if-new'>
    <xsl:choose>
      <xsl:when test='count( $accepted/list-item )'>
        <xsl:text> new</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name='search-result'>
    <xsl:choose>
      <xsl:when test='$back-search-not-needed and $any-suggestions'>
        <xsl:text>Here is what we have for you since then. </xsl:text>
      </xsl:when>
      <xsl:when test='$any-suggestions'>
        <xsl:text>Here is what </xsl:text>
        <xsl:value-of select='$new-if-new'/>
        <xsl:text> we found.</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test='$back-search-running'>
            <xsl:text>We didn't find anything </xsl:text>
            <xsl:value-of select='$new-if-new'/>
            <xsl:text> yet. </xsl:text>
            <a ref='@research/autosuggest' >
              <xsl:text> Reload the page</xsl:text>
            </a>
            <xsl:text> in 20 seconds or so.</xsl:text>
            <xsl:text/>
          </xsl:when>
          <xsl:when test='$back-search-finished'>
            <xsl:text> We didn’t find anything</xsl:text>
            <xsl:if test='$new-if-new'>
              <xsl:text> </xsl:text>
              <xsl:value-of select='$new-if-new'/>
            </xsl:if>
            <xsl:text>.</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>There is nothing we can suggest now.</xsl:text>
          </xsl:otherwise>
          <!--      <xsl:otherwise> -->
          <!--        <xsl:text>We don't have anything </xsl:text> -->
          <!--        <xsl:value-of select='$new-if-new'/>  -->
          <!--        <xsl:text> to suggest.</xsl:text> -->
          <!--      </xsl:otherwise> -->
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:template name='page-introduction'>
    <xsl:choose>
      <xsl:when test='$items-count'>
        <p>
          <xsl:text>Our automated search has found items that you may have written.</xsl:text>
        </p>
      </xsl:when>
      <xsl:when test='$any-suggestions  and $form-input/save_and_continue'>
        <p>
          <xsl:text>We invite you to continue to work on our suggestions.</xsl:text>
        </p>
      </xsl:when>
      <xsl:when test='$back-search-running'>
        <p>
          <xsl:text>We don’t have any suggestions for you yet. The search is going on.</xsl:text>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <p>
          <xsl:text>We don’t have any (more) suggestions for you.</xsl:text>
        </p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name='the-contributions'>
    <h1>
      <xsl:text>Automatic search</xsl:text>
    </h1>
    <xsl:text>
    </xsl:text>    
    <xsl:call-template name='show-status'/>
    <xsl:call-template name='page-introduction'/>
    <!-- <p>old: -->
    <!-- <xsl:copy-of select='$search-status'/> -->
    <!-- <xsl:text> </xsl:text> -->
    <!-- <xsl:copy-of select='$search-result'/> -->
    <!-- </p> -->
    <xsl:text>
    </xsl:text>
    <xsl:choose>
      <xsl:when test='$any-suggestions'>
        <xsl:call-template name='the-suggestions'/>
      </xsl:when>
      <xsl:otherwise>        
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>
    </xsl:text>
    <xsl:call-template name='epilog'/>
  </xsl:template>
  <xsl:template name='epilog'>
    <xsl:if test='not( $back-search-running )'>      
      <div class='block'>
        <div id='not-satisfied-invite'>          
          <h2>
            <a href='javascript:hide("not-satisfied-invite");show("not-satisfied-open");'
               class='int'>
              <xsl:text>Not satisfied with search results?</xsl:text>
            </a>
          </h2>
        </div>        
        <div id='not-satisfied-open' style='display: none;' class='open'>          
          <h2>
            <xsl:text>Not satisfied with search results?</xsl:text>
          </h2>          
          <acis:phrase ref='not-satisfied-with-automatic-search'/>
        </div>        
      </div>      
      <xsl:text>
      </xsl:text>      
    </xsl:if>    
    <xsl:choose>
      <xsl:when test='$any-suggestions and not( $back-search-running )'>        
        <xsl:call-template name='name-variations-display-with-heading'/>
      </xsl:when>
      <xsl:otherwise>        
        <xsl:call-template name='run-automatic-search-form'/>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:template>
  <xsl:template name='name-variations-display-with-heading'>
    <h2 id='variations'>Name variations</h2>
    <xsl:call-template name='name-variations-display'/>
  </xsl:template>

  <xsl:template name='suggest-choice'>
    <xsl:param name='checked'/>
    <!-- set the web id wid in the form -->
    <xsl:variable name='wid' select='generate-id(.)'/>

    <!-- this code determines whether the box should be checked -->
    <!-- but it does not seem to work correctly for me, so, we use the
         checked param instead (Ivan, 2011-11) -->
    <xsl:variable name='checked-by-status' xml:space='default'>
      <xsl:choose>
        <xsl:when test='status'>
          <xsl:value-of select='status/text() = "1"'/>
        </xsl:when>
        <xsl:otherwise> 
          <xsl:value-of select='ancestor::list-item/status/text() = "1"'/> 
        </xsl:otherwise>
      </xsl:choose> 
    </xsl:variable> 

    <!-- checking is always false here. That's why I commented out the previous element -->
    <!-- That's Thomas. -->
    <!-- 
         <xsl:variable name='checked-true' select='true()'/>
    -->
    <!-- the accept input -->
    <td class='checkbutton smallwidth yes' 
        valign='top' 
        onclick='td_click_switch(this)'>
      <!-- there decision in the item -->
      <input type='radio' 
             id='accept_{$wid}' 
             name='ar_{$wid}'
             value='accept'
             onclick='rbutton_click(this)'>
        <!-- but still use old code to check for checking -->  
        <xsl:if test='$checked = "true"'>
          <xsl:attribute 
              name='checked'>checked</xsl:attribute>
        </xsl:if>
      </input>
      <!-- document short_id -->
      <input type='hidden' 
             name='handle_{$wid}' 
             value='{id}'/>
      <!-- role with the document -->
      <xsl:if test='role'>
        <input type='hidden' 
               name='role_{$wid}' 
               value='{role}'/>
        <xsl:if test='role/text() != $default-role'>
          <br/>
          <xsl:text>(</xsl:text>
          <xsl:value-of select='role'/>
          <xsl:text>)</xsl:text>
        </xsl:if>
      </xsl:if>
    </td>
    <!-- the refuse input. It is shorter so we don't get -->
    <!-- the same input twice, stacked onto an array in acis -->
    <td class='checkbutton smallwidth no'
        valign='top' 
        onclick='td_click_switch(this)'>
      <input type='radio' 
             id='refuse_{$wid}' 
             name='ar_{$wid}'
             value='refuse'
             onclick='rbutton_click(this)'>
        <!-- but still use old code to check for checking -->  
        <xsl:if test='$checked != "true"'>
          <xsl:attribute name='checked'>checked</xsl:attribute>
        </xsl:if>
        <!-- <xsl:attribute name='value'><xsl:value-of select="'1'"/> </xsl:attribute> -->
      </input>
      <xsl:text>
      </xsl:text>
    </td>
  </xsl:template>
  <xsl:variable name='suggestions-introduction-phrase'>
    <xsl:text> We have </xsl:text>
    <xsl:value-of select='$items-count'/>
    <xsl:text> suggestion</xsl:text>
    <xsl:choose>
      <xsl:when test='$items-count != 1'>
        <xsl:text>s</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test='$more-to-follow'>
        <xsl:text> total and </xsl:text>
        <xsl:value-of select='$this-chunk-size'/> 
        <xsl:text> items are on this page. </xsl:text>                
        <xsl:value-of select='$more-to-follow-count'/>                
        <xsl:choose>
          <xsl:when test='$more-to-follow-count &gt; 1'>
            <xsl:text> are</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text> is</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> to follow. </xsl:text>
      </xsl:when>
      <xsl:when test='$items-count &gt; 1'>
        <xsl:text> and they are below. </xsl:text>
      </xsl:when>
      <xsl:when test='$items-count = 1'>
        <xsl:text> and it is below. </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>. </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <span>
      <xsl:text>For each suggestion you have a choice. You can </xsl:text>
    </span>
    <span class="accept">
      <xsl:text>accept</xsl:text>
    </span> 
    <span>
      <xsl:text> it, meaning that it is a work of yours. Or you can </xsl:text>
    </span>
    <span class="refuse">
      <xsl:text>refuse</xsl:text>
    </span>
    <span>
      <xsl:text> it, meaning you have nothing to do with it.</xsl:text>
    </span>
  </xsl:variable>
  <xsl:variable name='process-and-continue-button'>
    <button type='submit'
            name='save_and_continue'
            class='sofar important'
            title='Process all the choices you have made, learn from them to bring the document you will most likely accept to the top, stay in this screen.'>
      <span>
        <xsl:text>Process selections</xsl:text>
      </span>
      <span class='hidden'>
        <xsl:text> so far</xsl:text>
      </span>
    </button>
  </xsl:variable>
  <xsl:variable name="suggestions-table-introduction">
    <table>
      <tr>
        <td>
          <xsl:copy-of select='$suggestions-introduction-phrase'/>
        </td>
        <td style='valign: bottom'>
          <xsl:copy-of select='$process-and-continue-button'/>
        </td>
      </tr>
    </table>
  </xsl:variable>
  <xsl:template name='refuse-choice'>
    <!-- set the web id wid in the form -->
    <xsl:variable name="wid" 
                  select='generate-id(.)'/>
    <td class='checkbutton smallwidth refuse' valign='top' onclick='c_colors(this,"refuse")'>
      <!-- there decision in the item -->
      <input type='checkbox' 
             id='accept_{$wid}' 
             name='accept_{$wid}' 
             value='accept'
             onclick='c_colors(this,"refuse")'>
        <xsl:attribute name='name'>
          <xsl:text>ar_</xsl:text>
          <xsl:value-of select='$wid'/>
        </xsl:attribute>
      </input>
      <!-- document short_id -->
      <input type='hidden' 
             name='handle_{$wid}' 
             value='{id}'/>
      <!-- role with the document -->
      <xsl:if test='role'>
        <input type='hidden' 
               name='role_{$wid}' 
               value='{role}'/>
        <xsl:if test='role/text() != $default-role'>
          <br/>
          <xsl:text>(</xsl:text>
          <xsl:value-of select='role'/>
          <xsl:text>)</xsl:text>
        </xsl:if>
      </xsl:if>
    </td>
  </xsl:template>
  <xsl:template name='suggestions-table'>
    <table class='suggestions resources'
           summary='Suggestions for the research profile.'
           style='width: 100%'>
      <tr class='here'>
        <th class='desc' 
            rowspan="2">Item description</th>
        <th class='smallwitdth' 
            colspan="2">by you?</th>
      </tr>
      <tr class='choice here'>
        <th class='desc'>yes</th>
        <th class='desc'>no</th>
      </tr>
      <xsl:for-each select='$suggestions/list-item'>
        <xsl:variable name='already-shown'
                      select='count(preceding::list-item[parent::list and ancestor::suggest and ancestor::contributions] )'/>
        <acis:comment> already-shown= <xsl:value-of select='$already-shown'/></acis:comment>
        <xsl:if test='$already-shown &lt; $this-chunk-size'>
          <xsl:variable name='this-list-chunk-limit' 
                        select='$this-chunk-size - $already-shown'/>
          <acis:comment> this-list-chunk-limit= <xsl:value-of select='$this-list-chunk-limit'/> <xsl:text> </xsl:text></acis:comment>
          <tr class='explanation'>
            <td colspan='2' 
                style='padding: 3px;' >
              <xsl:call-template name='suggestions-sublist-explanation'>
                <xsl:with-param name='list' select='.'/>
              </xsl:call-template>
            </td>
          </tr>
          <xsl:for-each select='list/list-item'>
            <acis:comment>@pos=<xsl:value-of select='@pos'/></acis:comment>
            <xsl:if test='number(@pos) &lt; $this-list-chunk-limit'>
              <xsl:call-template name='suggest-item-row'/>
              <acis:comment>/item</acis:comment>   
            </xsl:if>
          </xsl:for-each>
          <xsl:text>
          </xsl:text>
        </xsl:if>
      </xsl:for-each>
    </table>
  </xsl:template>

  <xsl:template name='suggest-item-row'>
    <xsl:variable name="wid" select='generate-id(.)'/>
    <xsl:variable name="id"  select='id'/>
    <xsl:variable name='role' xml:space='default'>
      <xsl:choose>
        <xsl:when test='role/text()'>
          <xsl:value-of select='role/text()'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='parent::list/role'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name='alternate'>
      <xsl:if test='position() mod 2'> alternate</xsl:if>
    </xsl:variable>
    <xsl:variable name='checked'>
      <xsl:choose>
        <xsl:when test='status'>
          <xsl:value-of select='status/text() = "1"'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='ancestor::list-item/status/text() = "1"'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- accept/refuse class -->
    <xsl:variable name='ar-class'>
      <xsl:choose>
        <xsl:when test='$checked = "true"'> accept</xsl:when>
        <xsl:otherwise> refuse</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <tr class='resource{$alternate}{$ar-class}'
        id='row_{$wid}'>      
      <xsl:call-template name='item-description'/>
      <xsl:call-template name='suggest-choice'>
        <xsl:with-param name='checked' select='$checked'/>
      </xsl:call-template>
    </tr>
  </xsl:template>
  <!-- builds the tab set at the top of the page -->
  <xsl:variable name='the-suggestion-tabs'>
    <!-- <acis:tab>  -->
    <!--   <a ref='@research/autosuggest-all'>all&#160;at&#160;once</a> -->
    <!-- </acis:tab> -->
    <!-- <acis:tab> -->
    <!--   <a ref='@research/autosuggest'> -->
    <!--     100&#160;per&#160;page -->
    <!--   </a>  -->
    <!-- </acis:tab> -->
    <acis:tab>
      <xsl:if test='$this-chunk-size = $items-count'>
        <xsl:attribute name='selected'>1</xsl:attribute>
      </xsl:if>
      <a ref='@research/autosuggest-all'>
        <xsl:text>all at once</xsl:text>
      </a>  
    </acis:tab>
    <acis:tab>
      <xsl:if test='$this-chunk-size != $items-count'> 
        <xsl:attribute name='selected'>1</xsl:attribute>
      </xsl:if>
      <a ref='@research/autosuggest-chunk'>
        <xsl:value-of select="$chunk-size"/>
        <xsl:text> per page</xsl:text>
      </a> 
    </acis:tab>
  </xsl:variable>
  <!-- 
       <xsl:variable name='the-tabs'>
       <acis:tab>
       <xsl:if test='$this-chunk-size = $items-count'> 
       <xsl:attribute name='selected'>1</xsl:attribute>
       </xsl:if>
       <a>
       <xsl:attribute name='ref'>
       <xsl:text>@research/</xsl:text>
       <xsl:value-of select='$the-screen'/>
       </xsl:attribute>
       <xsl:text> all at once </xsl:text>
       </a> 
       </acis:tab>
       <acis:tab>
       <xsl:if test='$this-chunk-size != $items-count'> 
       <xsl:attribute name='selected'>1</xsl:attribute>
       </xsl:if>
       <xsl:if test="not($first)">
       <xsl:if test="not($last)">
       <a>
       <xsl:attribute name='ref'>
       <xsl:text>@research/</xsl:text>
       <xsl:value-of select='$the-screen'/>
       <xsl:text>-chunk</xsl:text>
       </xsl:attribute>
       </a>           
       <xsl:value-of select="$chunk-size"/>
       <xsl:text> per page </xsl:text>
       </xsl:if>
       </xsl:if>
       </acis:tab>
       </xsl:variable>
  -->
  <xsl:variable name='the-restricted-tabs'>
    <acis:tab>
      <xsl:attribute name='selected'>1</xsl:attribute>
      <a>
        <xsl:attribute name='ref'>
          <xsl:text>@research/</xsl:text>
          <xsl:value-of select='$the-screen'/>
        </xsl:attribute>
        <xsl:text> all at once </xsl:text>
      </a> 
    </acis:tab>
  </xsl:variable>
  <xsl:variable name='additional-head-stuff'>
    <script type='text/javascript' 
            src='{$base-url}/script/research.js'></script>
  </xsl:variable>
  <xsl:template name='item-description'>
    <xsl:variable name="wid" 
                  select='generate-id(.)'/>
    <td class='description'>
      <xsl:if test='relevance'>
        <xsl:attribute name='title'>
          <xsl:text>computed probability that this is yours: </xsl:text>
          <xsl:value-of select='relevance'/> 
        </xsl:attribute>
      </xsl:if>
      <xsl:call-template name='present-resource'>
        <xsl:with-param name='resource'
                        select='.'/>
        <xsl:with-param name='for'
                        select='concat( "doc_", $wid )' />
      </xsl:call-template>
    </td>
  </xsl:template>
</xsl:stylesheet>

