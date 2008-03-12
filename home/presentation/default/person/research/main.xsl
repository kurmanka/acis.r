<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='../../page-universal.xsl' />
  <xsl:import href='../../forms.xsl'/>


  <xsl:import href='listings.xsl'/>

  <xsl:import href='../../misc/time.xsl' />
  
  <xsl:variable name='current-screen-id'>research/main</xsl:variable>

  <xsl:variable name='default-role'>author</xsl:variable>



  <!--    v a r i a b l e s    -->

  <xsl:variable name='contributions' select='$response-data/contributions'/> 
  <xsl:variable name='suggestions'   select='$contributions/suggest'/>
  <xsl:variable name='current'       select='$contributions/accepted'/>
  <xsl:variable name='accepted'      select='$contributions/accepted'/>
  <xsl:variable name='refused'       select='$contributions/refused'/>
  <xsl:variable name='citations'     select='$contributions/citations'/>


  <xsl:variable name='current-count' 
                select='count( $current/list-item )'/>

  <xsl:variable name='suggestions-count' 
                select='count( $suggestions//list/list-item[id and title] )'/>

  <xsl:variable name='any-suggestions' 
                select='$suggestions-count'/>


  <xsl:variable name='config-object-types' select='$contributions/config/types'/> 


  <xsl:template name='contributions-breadcrumb'>
    <p class='breadCrumb'
    ><xsl:call-template name='connector'/>
    <xsl:text> </xsl:text>
    <a ref='@research' >Research profile</a>:
    </p>
  </xsl:template>


  <xsl:template name='name-variations-new-lined'>
    <xsl:for-each select='//autosearch/names-list-nice/list-item'
                  ><xsl:value-of select='text()'/><xsl:text>
</xsl:text>
    </xsl:for-each>
  </xsl:template>


  <xsl:template name='name-variations-display'>
    <p>List of names we searched
    (based on your full name and <a ref='@name?back=research#variations'>variations</a>):</p>
    <pre class='pad'><a ref='@name?back=research#variations'
    class='hidden' 
    title='edit it'>
    <xsl:call-template name='name-variations-new-lined'/>
    </a>
    </pre>
  </xsl:template>



  <xsl:template name='search-form'>

    <xsl:variable name='field'>
      <xsl:choose>
        <xsl:when test='false()'/>
        <xsl:otherwise>title</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

<!--
    <h2 id='manualSearch'>Manual search</h2>
-->

    <form screen='@research/search' name='searchform' id='searchform'>

<!--      <table style='float: left; margin-right: 0.5em; margin-bottom: 1em;'>
-->

      <table border='0'
             summary='form to search for documents'>
        
        <tr>
          <td valign='baseline' style='vertical-align: baseline;'
         >Search:</td>
          <td valign='baseline' style='vertical-align: baseline;'
              
              ><input type='text' class='edit' name='q' size='40'
              style='margin: 4px; width: 25ex;'
          />

          <br/>

            in:
            <label for='field-title'>
                <input type='radio' name='field' value='title' id='field-title'>
                  <xsl:if test='$field = "title"'>
                    <xsl:attribute name='checked'/>
                  </xsl:if>
              </input>        titles</label> 
              
            <xsl:text>&#160; </xsl:text>
            <label for='field-names'>
              <input type='radio' name='field' value='names' id='field-names'> 
                <xsl:if test='$field = "names"'>
                  <xsl:attribute name='checked'/>
                </xsl:if>
              </input>
            authors and editors</label>

          </td>

          <td style='vertical-align: baseline; padding-left: 4px;'>

        <input type='submit' name='go' value=' Find! ' class='significant'
               style='margin-top: 2px;'/>
        <xsl:text> </xsl:text>
        <input type='button' value='Clear' onclick='javascript:search_clear_and_focus()'/>

        <br/> 
<!--        <a ref='@research/search' >Advanced&#160;search</a>
-->
        <a ref='@research/search' >Advanced search</a>

          </td>
        </tr>
        
<!-- 
        <tr>
         <td style='text-align: right; vertical-align: top; padding-right: 4px;'>in:</td>
          <td>

            <p>in:</p>
            <p>
            <label for='field-title'>
              <input type='radio' name='field' value='title' id='field-title'>
                <xsl:if test='$field = "title"'>
                  <xsl:attribute name='checked'/>
                </xsl:if>
            </input>        titles</label> 
            <br />
              
            <label for='field-names'>
              <input type='radio' name='field' value='names' id='field-names'> 
                <xsl:if test='$field = "names"'>
                  <xsl:attribute name='checked'/>
                </xsl:if>
              </input>
            author and editor names</label>

          </td>

          <td>
          </td>

        </tr>
-->
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


    </form>

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
        <xsl:variable name='secdiff' select='$now - $search-start'/>
        <xsl:value-of select='round( $secdiff div 60 )' />
      </xsl:when>
      <xsl:otherwise><xsl:value-of select='false()'/></xsl:otherwise>
    </xsl:choose>

  </xsl:variable>





  <xsl:variable name='name-variations' xml:space='preserve'>
<ul class='names nameVariations' id='nameVariationsList'>
<xsl:for-each select='//autosearch/names-list-nice/list-item'
><li class='name'><xsl:value-of select='text()'/></li>
</xsl:for-each>
</ul>
  </xsl:variable>

  <xsl:variable name='name-variations-linked' xml:space='preserve'>
<ul style='margin-bottom: 0;' class='names nameVariations' id='nameVariationsList'>
<xsl:for-each select='//autosearch/names-list-nice/list-item'
><li class='name'><a class='hidden'
   ref='@name?back={$request-screen}#variations' 
   ><xsl:value-of select='text()'/></a></li>
</xsl:for-each>
</ul>
  </xsl:variable>


  <!--  (template)  NAME VARIATIONS LINK   -->

  <xsl:template name='edit-name-variations-link'>
    <a ref='@name?back={$request-screen}#variations' >Edit name
    variations.</a>
  </xsl:template>


  <xsl:template name='your-name-variations-are'>

    <p>Your name variations are:</p>

    <xsl:copy-of select='$name-variations-linked'/>
    
    <p style='margin-top: .4em;'
       ><xsl:call-template name='edit-name-variations-link'/></p>

  </xsl:template>  


  <xsl:template name='name-variations-list'>

    <p>Automatic search uses name variations list to find your
    works.</p>

    <xsl:call-template name='your-name-variations-are'/>

    <xsl:if test='$back-search-finished or $back-search-not-needed'>
        <xsl:text> </xsl:text>

        <p>
          <small
>If you change your
name variations and
return here, we will
automatically search
for your works again.</small>
        </p>
    </xsl:if>
    
<!--
    <span id='show_variations'> [<a
    class='int'
    href='javascript:show("the_variations");show("variations_intro");hide("show_variations");'
    >See name variations</a>] </span>

    <span id='variations_intro'> [<a class='int' href=
    'javascript:hide("the_variations");hide("variations_intro");show("show_variations");'
    >Hide name variations</a>] </span>

    <xsl:text>&#160; </xsl:text>

    </p>
        
    <div id='the_variations'>
     
      
      <xsl:copy-of select='$name-variations'/>
      
      <p><a ref='@name?back=contributions' >Edit
      name variations.</a>
      </p>

    </div>

<script-onload> hide("the_variations");hide("variations_intro"); </script-onload>

-->

</xsl:template>



  <xsl:template name='start-search-form'>

    <form xsl:use-attribute-sets='form' class='narrow'>

      <p>You can initiate automatic search yourself: 

      <input type='submit' name='start-auto-search' class='important'
      value='Search now!'/></p>
    </form>

  </xsl:template>



  <xsl:variable name='start-search-form'>
    <form xsl:use-attribute-sets='form' class='narrow'>
<!--
      <p>Last time we searched for your works less than two
      weeks ago.  If you want, you can do search now.</p>
-->
      <p>You can initiate automatic search yourself: 

      <input type='submit' name='start-auto-search' class='important'
      value='Search now!'/></p>
    </form>
  </xsl:variable>




  <!--  now the phrasing  -->
  
  <xsl:variable name='search-status'>
    <xsl:choose>
      <xsl:when test='$back-search-started'>
        <xsl:text>We have just started automatic search for your works.
        While system does search, you shall be able to see what's found and
        make decisions about it.  The page will reload soon and you might see
        the first results.</xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-running'>
        <xsl:text>Automatic search for your works is going on. </xsl:text>
        <xsl:if test='number( $started-that-ago ) &gt; 1'
                >(Started <xsl:value-of
                select='$started-that-ago'/> minutes ago.)
        </xsl:if>
      </xsl:when>
      <xsl:when test='$back-search-finished'>
        <xsl:text>We just ran automatic search for your works.</xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-start-failed'>
        <xsl:text>We tried to start automatic search for your works, but it
        failed.  Please, try again later.</xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-not-needed'>

        <xsl:text>Last time we ran automatic search for your works </xsl:text>
        <xsl:call-template name='time-difference-in-seconds'>
          <xsl:with-param name='diff' 
                          select='number(  //data/current-time-epoch/text() )
                          - number( //data/last-autosearch-time/text() )'/>
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
      <xsl:when test='$any-suggestions'>

        <xsl:choose>
          <xsl:when test='$back-search-not-needed'>
            <xsl:text>Since then we still have </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>Right now we have </xsl:text>
          </xsl:otherwise>
        </xsl:choose>

        <a ref='@research/autosuggest'>
        <xsl:choose>
          <xsl:when test='$suggestions-count > 1'>
            <xsl:value-of select='$suggestions-count'/> 
            <xsl:text>&#160;suggestions</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>one&#160;suggestion</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        </a>

        <xsl:text> for you.</xsl:text>

        <xsl:text> (</xsl:text>
        <a ref='@research/autosuggest-1by1' >One by one.</a>
        <xsl:text>)</xsl:text>



      </xsl:when>
      <xsl:otherwise>

        <xsl:choose>
          <xsl:when test='$back-search-running'>
            <xsl:text>We didn't find anything </xsl:text>
            <xsl:value-of select='$new-if-new'/> yet.  <a
            ref='@research/autosuggest' >Check the results</a> in 20
            seconds or so.<xsl:text/>
          </xsl:when>
          <xsl:when test='$back-search-finished'>
            We didn't find 
            anything<xsl:value-of select='$new-if-new'/>.
          </xsl:when>

<!--
          <xsl:otherwise>
            <xsl:text>We don't have anything </xsl:text>
            <xsl:value-of select='$new-if-new'/> 
            <xsl:text> to suggest.</xsl:text>
          </xsl:otherwise>
-->
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>


  <xsl:variable name='processed-choices'>
    <xsl:choose>
      <xsl:when test='$contributions/actions/accepted/text()'>
        The items you chose were added.
      </xsl:when>
      <xsl:when test='$contributions/actions/re-accepted/text() or 
                $contributions/actions/removed/text() or 
                $contributions/actions/refused/text()'>
        Your decisions were processed.
      </xsl:when>
    </xsl:choose>
  </xsl:variable>
        



  <xsl:template name='run-automatic-search-form'>

      <form screen='@research/autosuggest'
            xsl:use-attribute-sets='form' class='narrow'>
        
        <xsl:call-template name='name-variations-display'/>
        
        <xsl:choose>
          <xsl:when test='$back-search-running 
                    or $back-search-started'>
            
            <p title='search is already running'
               ><input type='submit' disabled='y' 
               name='start-auto-search' class='important'
            value='RUN AUTOMATIC SEARCH'/></p>
            
          </xsl:when>    
          <xsl:when test='$auto-search-disabled'>

            <p><input type='submit' name='start-auto-search'
            class='important'
            disabled='yes'
            value='RUN AUTOMATIC SEARCH'/></p>
            
            <p style='red'>System is experiencing high loads now, so this
            feature is disabled now.  Please try again later.</p>
      
          </xsl:when>
          <xsl:when test='not( $back-search-running ) 
                    and not( $back-search-started ) 
                    and not( $back-search-finished ) '>
            
            <p><input type='submit' name='start-auto-search' class='important'
            value='RUN AUTOMATIC SEARCH'/></p>
            
          </xsl:when>
          <xsl:otherwise><!-- ?? -->
      
          <!--
            <p title='search is already running'
               ><input type='submit' disabled='y' 
               name='start-auto-search' class='important'
            value='RUN AUTOMATIC SEARCH'/></p>
          -->
          </xsl:otherwise>
        </xsl:choose>

      </form>
    
  </xsl:template>


  <xsl:template name='research-main'>

    <h1>Research profile</h1>

    <xsl:call-template name='show-status'/>


    <p>Find your works in our documents database and add them to your
    list.</p>

    
<table class='bigmenu'>
  <tr>
    <td class='no' width='20%' valign='top' align='right'>

      <p><a ref='@research/identified'>1</a></p>

    </td>
    <td valign='top'>
      <h2><a ref='@research/identified'
      class='item'
      >IDENTIFIED WORKS</a></h2>
      
      <p>
            <xsl:text>You have </xsl:text>
            <a ref='@research/identified'>
              <xsl:choose>
                <xsl:when test='$current-count &gt; 1'>
                  <xsl:value-of select='$current-count'/>
                  <xsl:text> works</xsl:text>
                </xsl:when>
                <xsl:when test='$current-count = 1'>
                  <xsl:text> one work</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>no identified works</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text> in your profile</xsl:text>
            </a>
            <xsl:text> at the moment.</xsl:text>
      </p>

    </td>
  </tr>
  <tr>
    <td class='no' valign='top' align='right'>
      <p><a ref='@research/autosuggest'>2</a></p>
    </td>

    <td> 
      <h2><a ref='@research/autosuggest'
      class='item'
      >AUTOMATIC SEARCH SUGGESTIONS</a></h2>
      
      <p>
        <xsl:copy-of select='$search-status'/>
        <xsl:text> </xsl:text>
        <xsl:copy-of select='$search-result'/>
      </p>
      
      <xsl:call-template name='run-automatic-search-form'/>

    </td>

  </tr>

  <tr>
    <td class='no' valign='top' align='right'>
      <p><a ref='@research/search'>3</a></p>
    </td>
    <td>
      <h2><a ref='@research/search'
      class='item'
      >MANUAL SEARCH</a></h2>
    </td>
  </tr>

  <tr class='continued'>
    <td colspan='2'>
      <xsl:call-template name='search-form' />
    </td>
  </tr>

<xsl:if test='$session-type = "user"'>

  <tr>
    <td class='no' valign='top' align='right'>
      <p><a ref='@research/refused'>4</a></p>
    </td>
    <td>
      <h2><a ref='@research/refused'
      class='item'
      >REFUSED RESEARCH ITEMS</a></h2>

      <p>These works are automatically excluded from the
      search results, because you refused them, thus claim <em>not</em> to be their author.</p>

    </td>
  </tr>


  <tr>
    <td class='no' valign='top' align='right'>
      <p><a ref='@research/autoupdate'>5</a></p>
    </td>
    <td>
      <h2><a ref='@research/autoupdate'
      class='item'
      >AUTOMATIC UPDATE PREFERENCES</a></h2>

      <p>Your preferences on the matter of automatically updating
      your profile.</p>

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


<phrase ref='research-main-epilog'/>

  </xsl:template>



  <!-- RESEARCH NAVIGATION -->

  <xsl:template name='research-navigation'>

    <xsl:call-template name='link-filter'>
      <xsl:with-param name='content'>
        
        <xsl:text>
        </xsl:text>
    
        <p class='menu submenu'>

<span class='head here'>

  <xsl:text>&#160;</xsl:text>

<xsl:choose>
  <xsl:when test='$current-screen-id = "research/main"'>

      <b>Research:</b>

  </xsl:when>
  <xsl:otherwise>

    <a ref='@research'>Research:</a>

  </xsl:otherwise>
</xsl:choose>

      <xsl:text>&#160;</xsl:text>
</span>

<span class='body'>

    <hl screen='research/identified'>
         <xsl:text>&#160;</xsl:text>
         <a ref='@research/identified' 
         >identified</a>
         <xsl:text>&#160;</xsl:text>
    </hl>

    <hl screen='research/autosuggest'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@research/autosuggest' 
      >auto&#160;suggestions</a>
      <xsl:text>&#160;</xsl:text>
    </hl>


    <hl screen='research/search'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@research/search' 
      >manual search</a>
      <xsl:text>&#160;</xsl:text>
    </hl>
       
<xsl:if test='$session-type = "user"'>

    <hl screen='research/refused'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@research/refused'>refused items</a>
      <xsl:text>&#160;</xsl:text>
    </hl>

    <hl screen='research/autoupdate'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@research/autoupdate'>auto update</a>
      <xsl:text>&#160;</xsl:text>
    </hl>

    <!--[if-config(document-document-links-profile)]-->
    <hl screen='research/doclinks'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@research/doclinks'>document links</a>
      <xsl:text>&#160;</xsl:text>
    </hl>
    <!--[end-if]-->

    <!--[if-config(full-text-urls-recognition)]-->
    <hl screen='research/fturls'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@research/fturls'>full-text links</a>
      <xsl:text>&#160;</xsl:text>
    </hl>
    <!--[end-if]-->

</xsl:if>

</span>
    </p>

<xsl:text> 
</xsl:text>
    </xsl:with-param></xsl:call-template>

    
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

      <xsl:with-param name='content' select='$content'/>

    </xsl:call-template>

  </xsl:template>



  <xsl:variable name='to-go-options'>
    <xsl:if test='$request-screen != "research"'>
      <op><a ref='@research' >main research page</a></op>
    </xsl:if>
    <root/>
  </xsl:variable>


  <xsl:variable name='next-registration-step'>
    <a ref='@new-user/complete'>next registration step: confirmation email</a>
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

