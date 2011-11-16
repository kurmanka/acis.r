 <xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">
   <!-- evcino -->
   <xsl:import href='../../page-universal.xsl' />
   <xsl:import href='../../forms.xsl'/>
   <xsl:import href='listings.xsl'/>
   <xsl:import href='../../misc/time.xsl' />
   <xsl:variable name='current-screen-id'>
     <xsl:text>research/main</xsl:text>
   </xsl:variable>
   <xsl:variable name='default-role'>
     <xsl:text>author</xsl:text>
   </xsl:variable>
   <!--    v a r i a b l e s    -->
   <xsl:variable name='contributions' 
                 select='$response-data/contributions'/> 
   <xsl:variable name='suggestions'
                 select='$contributions/suggest'/>
   <xsl:variable name='current'
                 select='$contributions/accepted'/>
   <xsl:variable name='accepted'
                 select='$contributions/accepted'/>
   <xsl:variable name='refused'
                 select='$contributions/refused'/>
   <xsl:variable name='citations'
                 select='$contributions/citations'/>
   <xsl:variable name='current-count' 
                 select='count( $current/list-item )'/>
   <xsl:variable name='suggestions-count' 
                 select='count( $suggestions//list/list-item[id and title] )'/>
   <xsl:variable name='any-suggestions' 
                 select='$suggestions-count'/>
   <xsl:variable name='config-object-types'
                 select='$contributions/config/types'/> 
   <xsl:template name='contributions-breadcrumb'>
     <p class='breadCrumb'>
      <xsl:call-template name='connector'/>
      <xsl:text> </xsl:text>
      <a ref='@research'>
        <xsl:text>Research profile</xsl:text>
        </a>:
     </p>
   </xsl:template>
   <xsl:template name='name-variations-new-lined'>
     <xsl:for-each select='//autosearch/names-list-nice/list-item'>
       <code>
         <xsl:value-of select='text()'/>
       </code>
       <br/>
     </xsl:for-each>
   </xsl:template>
   <xsl:template name='name-variations-display'>
     <p>
       <xsl:text>The names we search are based on your full name and </xsl:text>
       <a ref='@name?back=research#variations'>
         <xsl:text>your name variations</xsl:text>
       </a>
       <xsl:text>:</xsl:text>
     </p>
     <p class='pad'>
       <a ref='@name?back=research#variations'
          class='hidden' 
          title='edit it'>
         <xsl:call-template name='name-variations-new-lined'/>
       </a>
     </p>
   </xsl:template>
   <xsl:template name='search-form'>
     <xsl:variable name='field'>
       <xsl:choose>
         <xsl:when test='false()'/>
         <xsl:otherwise>title</xsl:otherwise>
       </xsl:choose>
     </xsl:variable>
     <!-- <h2 id='manualSearch'>Manual search</h2> -->
     <!-- there used to be a name='searchform' attribute on the next element -->
     <acis:form screen='@research/search'
                id='searchform'>
       <!--  <table style='float: left; margin-right: 0.5em; margin-bottom: 1em;'>-->
       <table border='0'
              summary='form to search for documents'>       
         <tr>
           <td valign='baseline' style='vertical-align: baseline;'>
             <xsl:text>Search:</xsl:text>
           </td>
           <td valign='baseline'
               style='vertical-align: baseline;'>
             <input type='text' 
                    class='edit'
                    name='q' 
                    size='40'
                    style='margin: 4px; width: 25ex;'/>
             <br/>
             <xsl:text>in:</xsl:text>
             <label for='field-title'>
               <input type='radio' name='field' value='title' id='field-title'>
                 <xsl:if test='$field = "title"'>
                   <xsl:attribute name='checked'/>
                 </xsl:if>
               </input>
               <xsl:text>titles</xsl:text>
             </label>             
             <xsl:text>  </xsl:text>
             <label for='field-names'>
               <input type='radio'
                      name='field'
                      value='names'
                      id='field-names'> 
                 <xsl:if test='$field = "names"'>
                   <xsl:attribute name='checked'/>
                 </xsl:if>
               </input>
               <xsl:text>authors and editors</xsl:text>
             </label>
           </td>
           <td style='vertical-align: baseline; padding-left: 4px;'>
             <input type='submit' 
                    name='go' 
                    value=' Find! '
                    class='significant'
                    style='margin-top: 2px;'/>
             <xsl:text> </xsl:text>
             <input type='button'
                    value='Clear'
                    onclick='javascript:search_clear_and_focus()'/>
             <br/> 
             <!-- <a ref='@research/search' >Advanced search</a>-->
             <a ref='@research/search' >
               <xsl:text>Advanced search</xsl:text>
             </a>
           </td>
         </tr>
        <!-- --> 
        <!-- <tr> -->
        <!--   <td style='text-align: right; vertical-align: top; padding-right: 4px;'>in:</td> -->
        <!--   <td>             -->
        <!--     <p>in:</p> -->
        <!--     <p> -->
        <!--       <label for='field-title'> -->
        <!--         <input type='radio' name='field' value='title' id='field-title'> -->
        <!--           <xsl:if test='$field = "title"'> -->
        <!--             <xsl:attribute name='checked'/> -->
        <!--           </xsl:if> -->
        <!--       </input>        titles</label>  -->
        <!--       <br /> -->
        <!--        -->
        <!--       <label for='field-names'> -->
        <!--         <input type='radio' name='field' value='names' id='field-names'>  -->
        <!--           <xsl:if test='$field = "names"'> -->
        <!--             <xsl:attribute name='checked'/> -->
        <!--           </xsl:if> -->
        <!--         </input> -->
        <!--       author and editor names</label> -->
        <!--     </p> -->
        <!--   </td> -->
        <!--    -->
        <!--   <td> -->
        <!--   </td> -->
        <!--    -->
        <!-- </tr> -->
        <!--        -->
       </table>
       <script>
         function search_focus() {
           var inp = document.searchform["q"]; 
           inp.focus();
         }
        function search_clear_and_focus() {
          var inp = document.searchform["q"]; 
          inp.value = "";
          inp.focus();
        }
      </script>
    </acis:form>
  </xsl:template>
  <!--   t h e   r e s e a r c h   s c r e e n    -->
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
                  select='$contributions/last-back-search-started-time-epoch/text()'/>
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
  <xsl:variable name='name-variations'
                xml:space='preserve'>
    <ul class='names nameVariations'
        id='nameVariationsList'>
      <xsl:for-each select='//autosearch/names-list-nice/list-item'>
        <li class='name'>
          <xsl:value-of select='text()'/>
        </li>
      </xsl:for-each>
    </ul>
  </xsl:variable>
  <xsl:variable name='name-variations-linked'
                xml:space='preserve'>
    <ul style='margin-bottom: 0;' 
        class='names nameVariations'
        id='nameVariationsList'>
      <xsl:for-each select='//autosearch/names-list-nice/list-item'>
        <li class='name'>
          <a ref='@name?back={$request-screen}#variations'  class='hidden'>
        <xsl:value-of select='text()'/></a></li>
      </xsl:for-each>
    </ul>
  </xsl:variable>
  <!--  (template)  NAME VARIATIONS LINK   -->
  <xsl:template name='edit-name-variations-link'>
    <a ref='@name?back={$request-screen}#variations' >
      <xsl:text>Edit name variations.</xsl:text>
    </a>
  </xsl:template>
  <xsl:template name='your-name-variations-are'>
    <p>
      <xsl:text>Your name variations are:</xsl:text>
    </p>
    <xsl:copy-of select='$name-variations-linked'/>    
    <p style='margin-top: .4em;'>
      <xsl:call-template name='edit-name-variations-link'/>
    </p>
  </xsl:template>  
  <xsl:template name='name-variations-list'>
    <p>
      <xsl:text>Automatic search uses name variations list to find your works.</xsl:text>
    </p>
    <xsl:call-template name='your-name-variations-are'/>
    <xsl:if test='$back-search-finished or $back-search-not-needed'>
        <xsl:text> </xsl:text>
        <p>
          <small>
            <xsl:text>If you change your name variations and return here, we will automatically search for your works again.</xsl:text>
          </small>
        </p>
    </xsl:if>
    <!-- -->
    <!-- <span id='show_variations'> -->
    <!--   <xsl:text>[</xsl:text> -->
    <!--   <a class='int' -->
    <!--      href='javascript:show("the_variations");show("variations_intro");hide("show_variations");'> -->
    <!--     <xsl:text>See name variations</xsl:text> -->
    <!--   </a> -->
    <!--   <xsl:text>]</xsl:text> -->
    <!-- </span> -->
    <!-- <span id='variations_intro'>  -->
    <!--   <xsl:text>[</xsl:text> -->
    <!-- <a href='javascript:hide("the_variations");hide("variations_intro");show("show_variations");' -->
    <!--    class='int'> -->
    <!--   <xsl:text>Hide name variations</xsl:text> -->
    <!-- </a> -->
    <!-- <xsl:text>] </xsl:text> -->
    <!-- </span>     -->
    <!-- <xsl:text>  </xsl:text> -->
    <!-- <div id='the_variations'> -->
    <!--   <xsl:copy-of select='$name-variations'/>       -->
    <!--   <p> -->
    <!--     <a ref='@name?back=contributions' >Edit name variations.</a> -->
    <!--   </p> -->
    <!-- </div> -->
    <!-- <acis:script-onload> hide("the_variations");hide("variations_intro"); </acis:script-onload> -->
  </xsl:template>
  <xsl:template name='start-search-form'>
    <acis:form xsl:use-attribute-sets='form'
               class='narrow'>
      <p>
        <xsl:text>You can initiate automatic search yourself: </xsl:text>
        <input type='submit'
               name='start-auto-search'
               class='important'
               value='Search now!'/>
      </p>
    </acis:form>    
  </xsl:template>
  <xsl:variable name='start-search-form'>
    <acis:form xsl:use-attribute-sets='form' class='narrow'>
      <!-- <p>Last time we searched for your works less than two -->
      <!-- weeks ago.  If you want, you can do search now.</p> -->
      <p>
        <xsl:text>You can initiate automatic search yourself: </xsl:text>
      <input type='submit' 
             name='start-auto-search'
             class='important'
             value='Search now!'/>
      </p>
    </acis:form>
  </xsl:variable>
  <!--  now the phrasing  -->
  <xsl:variable name='search-status'>
    <xsl:choose>
      <xsl:when test='$back-search-started'>
        <xsl:text>We have just started automatic search for your works.</xsl:text>
        <xsl:text> While the system searches, you shall be able to see what's found and</xsl:text>
        <xsl:text> make decisions about it. The page will reload soon and you might see</xsl:text>
        <xsl:text> the first results.</xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-running'>
        <xsl:text>Automatic search for your works is going on. </xsl:text>
        <xsl:if test='number( $started-that-ago ) &gt; 1'>
          <xsl:text>(Started </xsl:text>
          <xsl:value-of select='$started-that-ago'/>
          <xsl:text>minutes ago.)</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:when test='$back-search-finished'>
        <xsl:text> We just ran automatic search for your works.</xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-start-failed'>
        <xsl:text> We tried to start automatic search for your works, but it failed.  Please, try again later.</xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-not-needed'>
        <xsl:text> Last time we ran automatic search for your works </xsl:text>
        <xsl:call-template name='time-difference-in-seconds'>
          <xsl:with-param name='diff' 
                          select='number(  //data/current-time-epoch/text() )
                          - number( //data/last-autosearch-time/text() )'/>
        </xsl:call-template>
        <xsl:text> ago.</xsl:text>
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
      <xsl:when test='$any-suggestions'>
        <xsl:choose>
          <xsl:when test='$back-search-not-needed'>
            <xsl:text> Since then we still have </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text> Right now we have </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <a ref='@research/autosuggest'>
        <xsl:choose>
          <xsl:when test='$suggestions-count > 1'>
            <xsl:value-of select='$suggestions-count'/> 
            <xsl:text> suggestions</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>one suggestion</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        </a>
        <xsl:text> for you.</xsl:text>
        <!-- <xsl:text> (</xsl:text><acis:a ref='@research/autosuggest-1by1' >One by one.</acis:a><xsl:text>)</xsl:text>  -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test='$back-search-running'>
            <xsl:text> We didn’t find anything </xsl:text>
            <xsl:value-of select='$new-if-new'/>
            <xsl:text> yet.  </xsl:text>
            <a ref='@research/autosuggest' >
              <xsl:text> Check the results</xsl:text>
              </a>
              <xsl:text> in 20 seconds or so.</xsl:text>
          </xsl:when>
          <xsl:when test='$back-search-finished'>
            <xsl:text> We didn’t find anything</xsl:text>
            <xsl:value-of select='$new-if-new'/>.
          </xsl:when>
          <!-- <xsl:otherwise> -->
          <!-- <xsl:text>We don’t have anything </xsl:text> -->
          <!-- <xsl:value-of select='$new-if-new'/>  -->
          <!-- <xsl:text> to suggest.</xsl:text> -->
          <!-- </xsl:otherwise> -->
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name='processed-choices'>
    <xsl:choose>
      <xsl:when test='$contributions/actions/accepted/text()'>
        <xsl:text>The items you chose were added.</xsl:text>
      </xsl:when>
      <xsl:when test='$contributions/actions/re-accepted/text() or 
                      $contributions/actions/removed/text() or 
                      $contributions/actions/refused/text()'>
        <xsl:text>Your decisions were processed.</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>
  <xsl:template name='run-automatic-search-form'>
    <acis:form screen='@research/autosuggest' 
               xsl:use-attribute-sets='form' 
               class='narrow'>
      <xsl:call-template name='name-variations-display'/>
      <xsl:choose>
        <xsl:when test='$back-search-running or $back-search-started'>            
          <p title='search is already running'>
            <input type='submit'
                   disabled='y' 
                   name='start-auto-search' 
                   class='important'
                   value='RUN AUTOMATIC SEARCH'/>
          </p>            
        </xsl:when>    
        <xsl:when test='$auto-search-disabled'>            
          <p>
            <input type='submit' 
                   name='start-auto-search'
                   class='important'
                   disabled='yes'
                   value='RUN AUTOMATIC SEARCH'/>
          </p>              
          <p style='red'>
            <xsl:text>Our system is experiencing high loads right now. We had to disable this feature is disabled now.  Please try again later.</xsl:text>
          </p>      
        </xsl:when>
        <!-- there was an additional "and $back-search-finished" condition in the next test -->
        <xsl:when test='not( $back-search-running ) and not( $back-search-started )'> 
          <p>
            <input type='submit'
                   name='start-auto-search'
                   class='important'
                   value='RUN AUTOMATIC SEARCH'/>
          </p>            
        </xsl:when>
        <xsl:otherwise>            
          <!-- <div>is back search running? -->
          <!-- <xsl:value-of select="$back-search-running"/> -->
          <!-- </div> -->
          <!-- <div>is back search started? -->
          <!-- <xsl:value-of select="$back-search-started"/> -->
          <!-- </div> -->
          <!-- <div>is back search finished? -->
          <!-- <xsl:value-of select="$back-search-finished"/> -->
          <!-- </div> -->
          <p title='search is already running'>
            <input type='submit' 
                   disabled='disabled' 
                   name='start-auto-search'
                   class='important'
                   value='RUN AUTOMATIC SEARCH'/>
          </p>
        </xsl:otherwise>
      </xsl:choose>
    </acis:form>
  </xsl:template>
  <xsl:template name='research-main'>
    <h1>
      <xsl:text>Research profile</xsl:text>
    </h1>
    <xsl:call-template name='show-status'/>
    <p>
      <xsl:text>Find your works in our documents database and add them to your profile.</xsl:text>
    </p>
    <table class='bigmenu'>
      <tr>
        <td class='no'
            width='20%'
            valign='top'
            align='right'>          
          <p>
            <a ref='@research/accepted'>
              <xsl:text>1</xsl:text>
            </a>
          </p>
        </td>
        <td valign='top'>
          <h2>
            <a ref='@research/accepted'
               class='item'>ACCEPTED WORKS</a></h2>
            <p>
              <xsl:text>You have </xsl:text>
              <a ref='@research/accepted'>
                <xsl:choose>
                  <xsl:when test='$current-count &gt; 1'>
                    <xsl:value-of select='$current-count'/>
                    <xsl:text> works</xsl:text>
                  </xsl:when>
                  <xsl:when test='$current-count = 1'>
                    <xsl:text> one work</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>no accepted works</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:text> in your profile</xsl:text>
              </a>
              <xsl:text> at the moment.</xsl:text>
            </p>            
        </td>
      </tr>
      <tr>
        <td class='no'
            valign='top'
            align='right'>
          <p>
            <a ref='@research/autosuggest'>
              <xsl:text>2</xsl:text>
            </a>
          </p>
        </td>
        <td> 
          <h2>
            <a ref='@research/autosuggest'
               class='item'>
              <xsl:text>AUTOMATIC SEARCH SUGGESTIONS</xsl:text>
            </a>
          </h2>      
          <p>
            <xsl:copy-of select='$search-status'/>
            <xsl:text> </xsl:text>
            <xsl:copy-of select='$search-result'/>
          </p>      
          <xsl:call-template name='run-automatic-search-form'/>
        </td>
      </tr>
      <tr>
        <td class='no'
            valign='top'
            align='right'>
          <p>
            <a ref='@research/search'>
              <xsl:text>3</xsl:text>
            </a>
          </p>
        </td>
        <td>
          <h2>
            <a ref='@research/search'
               class='item'>
              <xsl:text>MANUAL SEARCH</xsl:text>
            </a>
          </h2>
        </td>
      </tr>
      <tr class='continued'>
        <td colspan='2'>
          <xsl:call-template name='search-form' />
        </td>
      </tr>
      <xsl:if test='$session-type = "user"'>    
        <tr>
          <td class='no'
              valign='top'
              align='right'>
            <p>
              <a ref='@research/refused'>
                <xsl:text>4</xsl:text>
              </a>
            </p>
          </td>
          <td>
            <h2>
              <a ref='@research/refused'
                 class='item'>
                <xsl:text>REFUSED RESEARCH ITEMS</xsl:text>
              </a>
            </h2>
            <p>
              <xsl:text>These works are automatically excluded from
              the search results, because you refused them, and
              thus claim </xsl:text><u>not</u>
              <xsl:text> to be their author.</xsl:text>
            </p>
          </td>
        </tr>
        <tr>
          <td class='no' 
              valign='top' 
              align='right'>
            <p>
              <a ref='@research/autoupdate'>
                <xsl:text>5</xsl:text>
              </a>
            </p>
          </td>
          <td>
            <h2>
              <a ref='@research/autoupdate'
                 class='item'>
                <xsl:text>AUTOMATIC UPDATE PREFERENCES</xsl:text>
              </a>
            </h2>
            <p>
              <xsl:text>Your preferences on the matter of automatically updating your profile.</xsl:text>
            </p>
          </td>
        </tr>
        <!--[if-config(document-document-links-profile)]-->
          <tr> 
           <td class='no' valign='top' align='right'>
             <p><a ref='@research/doclinks'>6</a></p>
           </td>
           <td>
             <h2><a ref='@research/doclinks' class='item'
             >DOCUMENT TO DOCUMENT LINKS</a></h2>
             <p>Connect your research works.</p>
           </td>
         </tr>
        <!--[end-if]-->
        <!--[if-config(full-text-urls-recognition)]-->
        <tr>
           <td class='no' valign='top' align='right'>
             <p><a ref='@research/fturls'>7</a></p>
           </td>
           <td>
             <h2><a ref='@research/fturls' class='item'
             >DOCUMENTS' FULL-TEXT LINKS</a></h2>
             <p>Check the files.</p>
           </td>
         </tr>
        <!--[end-if]-->
      </xsl:if>
    </table>
    <acis:phrase ref='research-main-epilog'/>
  </xsl:template>
  <!-- RESEARCH NAVIGATION -->
  <xsl:template name='research-navigation'>
    <xsl:call-template name='link-filter'>
      <xsl:with-param name='content'>
        <xsl:text>
        </xsl:text>        
        <p class='menu submenu'>
          <span class='head here'>            
            <xsl:text> </xsl:text>
            <xsl:choose>
              <xsl:when test='$current-screen-id = "research/main"'>               
                <b>
                  <xsl:text>Research:</xsl:text>
                </b>
              </xsl:when>
              <xsl:otherwise>
                <a ref='@research'>
                  <xsl:text>Research:</xsl:text>
                </a>                
              </xsl:otherwise>
            </xsl:choose>           
            <xsl:text> </xsl:text>
          </span>         
          <span class='body'>
            <acis:hl screen='research/accepted'>
              <xsl:text> </xsl:text>
              <a ref='@research/accepted'>
                <xsl:text>accepted items</xsl:text>
              </a>
              <xsl:text> </xsl:text>
            </acis:hl>
            <acis:hl screen='research/autosuggest'>
              <xsl:text> </xsl:text>
              <a ref='@research/autosuggest'>
                <xsl:text>auto suggestions</xsl:text>
              </a>
              <xsl:text> </xsl:text>
            </acis:hl>           
            <acis:hl screen='research/search'>
              <xsl:text> </xsl:text>
              <a ref='@research/search'>
                <xsl:text>manual search</xsl:text>
              </a>
              <xsl:text> </xsl:text>
            </acis:hl>            
            <xsl:if test='$session-type = "user"'>              
              <acis:hl screen='research/refused'>
                <xsl:text> </xsl:text>
                <a ref='@research/refused-chunk'>
                  <xsl:text>refused items</xsl:text>
                </a>
                <xsl:text> </xsl:text>
              </acis:hl>              
              <acis:hl screen='research/autoupdate'>
                <xsl:text> </xsl:text>
                <a ref='@research/autoupdate'>
                  <xsl:text>auto update</xsl:text>
                </a>
                <xsl:text> </xsl:text>
              </acis:hl>              
              <!--[if-config(document-document-links-profile)]-->
              <acis:hl screen='research/doclinks'>
                <xsl:text> </xsl:text> 
                  <a ref='@research/doclinks'>document links</a>
                <xsl:text> </xsl:text>
              </acis:hl>
              <!--[end-if]--> 
              <!--[if-config(full-text-urls-recognition)]-->
              <acis:hl screen='research/fturls'>
                <xsl:text> </xsl:text>
                <a ref='@research/fturls'>full-text links</a>
                <xsl:text> </xsl:text>
              </acis:hl>
              <!--[end-if]-->
            </xsl:if>            
          </span>
        </p>    
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  <xsl:template name='additional-page-navigation'>
    <xsl:call-template name='research-navigation'/>
  </xsl:template>
  <xsl:template name='research-page'>
    <xsl:param name='title'/>
    <xsl:param name='content'/>
    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>
        <xsl:if test='string-length($title)'>
          <xsl:text>research: </xsl:text>
          <xsl:value-of select='$title'/>
        </xsl:if>
        <xsl:if test='not(string-length( $title ))'>
          <xsl:text>research profile</xsl:text>
        </xsl:if>
      </xsl:with-param>
      <xsl:with-param name='content'
                      select='$content'/>
    </xsl:call-template>
  </xsl:template>
  <xsl:variable name='to-go-options'>
    <xsl:if test='$request-screen != "research"'>
      <acis:op>
        <a ref='@research'>
          <xsl:text>main research page</xsl:text>
        </a>
      </acis:op>
    </xsl:if>
    <acis:root/>
  </xsl:variable>
  <xsl:variable name='next-registration-step'>
    <a ref='@new-user/complete'>
      <xsl:text>next registration step: confirmation email</xsl:text>
    </a>
  </xsl:variable>
  <!--   n o w   t h e   p a g e   t e m p l a t e    -->  
  <xsl:template match='/data'>
    <xsl:call-template name='research-page'>
      <xsl:with-param name='content'>
        <xsl:call-template name='research-main'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>

