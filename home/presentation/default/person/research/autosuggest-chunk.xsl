<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='main.xsl' />
  <xsl:import href='listings.xsl' />
  <xsl:import href='../../widgets.xsl' />


  <xsl:variable name='parents'>
    <par id='research/main'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>research/autosuggest</xsl:variable>
  
  <xsl:variable name='form-target'>@research/autosuggest</xsl:variable>
  

  <xsl:variable name='chunk-size' select='"12"'/>

  <xsl:variable name='more-to-follow' 
                select='$suggestions-count &gt; $chunk-size'/>
  <xsl:variable name='more-to-follow-count' 
                select='$suggestions-count - $chunk-size'/>


  <xsl:variable name='any-suggestions' 
                select='count( //suggest/list-item/list/list-item )'/>




  <!--   t h e   c o n t r i b u t i o n s    s c r e e n    -->


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
        <xsl:variable name='secdiff' select='$now - $search-start'/>
        <xsl:value-of select='round( $secdiff div 60 )' />
      </xsl:when>
      <xsl:otherwise><xsl:value-of select='false()'/></xsl:otherwise>
    </xsl:choose>

  </xsl:variable>






  <xsl:template name='suggestions-table'>

    <table class='suggestions resources'
           summary='Suggestions for the research profile.'
           >

      <tr class='here'>
        <th width='6%'  >Authored by me</th>
        <th class='desc'>Item description</th>
      </tr>

      <xsl:for-each select='$suggestions/list-item'>

        <xsl:variable name='already-shown' 
             select='count(
             preceding::list-item[parent::list and
             ancestor::suggest and ancestor::contributions] )'/>

	     <comment> already-shown= <xsl:value-of
	     select='$already-shown'/> </comment>

        <xsl:if test='$already-shown &lt; $chunk-size'>

          <xsl:variable name='this-list-chunk-limit' 
                        select='$chunk-size - $already-shown'/>
          
	  <comment> this-list-chunk-limit= <xsl:value-of
	  select='$this-list-chunk-limit'/>
	  <xsl:text> </xsl:text></comment>

          <tr class='explanation'>
            <td colspan='2' 
                style='padding: 3px;' >
              <xsl:call-template name='suggestions-sublist-explanation'>
                <xsl:with-param name='list' select='.'/>
              </xsl:call-template>
            </td>
          </tr>
          
          <xsl:text>
          </xsl:text>
          
          <xsl:for-each select='list/list-item'>
	    <comment>@pos=<xsl:value-of select='@pos'/></comment>
            <xsl:if test='number(@pos) &lt; $this-list-chunk-limit'>
              <xsl:call-template name='suggest-item-row'/>
	      <comment>/item</comment>   
            </xsl:if>
          </xsl:for-each>

          <xsl:text>

          </xsl:text>

        </xsl:if>

      </xsl:for-each>

    </table>
  </xsl:template>


  <xsl:template name='suggest-item-row'>

    <xsl:variable name="sid" select='generate-id(.)'/>
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

    <xsl:variable name='checked-class'>
      <xsl:if test='$checked = "true"'> select</xsl:if>
    </xsl:variable>

    
    <tr class='resource{$alternate}{$checked-class}'
        id='row_{$sid}'>
      
      <!-- checkbox -->
      <xsl:call-template name='item-checkbox'/>

      <!-- description -->
      <xsl:call-template name='item-description'/>

    </tr>
      
  </xsl:template>



  <xsl:template name='item-checkbox'>

    <xsl:variable name="sid" select='generate-id(.)'/>

    <xsl:variable name='checked' xml:space='default'>
      <xsl:choose>
        <xsl:when test='status'>
          <xsl:value-of select='status/text() = "1"'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='ancestor::list-item/status/text() = "1"'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <td class='checkbutton' width='6%' valign='top' >
      
      <input type='checkbox' name='add_{$sid}' id='add_{$sid}' 
             value='1'>
        <xsl:if test='$checked = "true"'>
          <xsl:attribute name='checked'/>
        </xsl:if>
      </input>
      
      <xsl:text>
      </xsl:text>
      
      <input type='hidden' name='id_{$sid}' value='{id}'/>
      
      <xsl:text>
      </xsl:text>

      <xsl:if test='role'>
        <input type='hidden' name='role_{$sid}' value='{role}'/>
        <xsl:if test='role/text() != $default-role'>
          <br/>
          (<xsl:value-of select='role'/>)
          
        </xsl:if>
      </xsl:if>

    </td>
      
  </xsl:template>



  <xsl:template name='item-description'>

    <xsl:variable name="sid" select='generate-id(.)'/>

    <td class='description'>
      <xsl:text>
      </xsl:text>
      
      <xsl:call-template name='present-resource'>
        <xsl:with-param name='resource' select='.'/>
        <xsl:with-param name='for' select='concat( "add_", $sid )' />
      </xsl:call-template>

      <xsl:text>
      </xsl:text>
      

    </td>

  </xsl:template>




  <xsl:variable name='screen-autosuggest-all'/>


  <xsl:template name='the-suggestions'>


    <xsl:call-template name='tabset'>
      <xsl:with-param name='id' select='"tabs"'/>
      <xsl:with-param name='tabs'>
        <xsl:choose>
          <xsl:when test='$screen-autosuggest-all'>
        <tab selected='1'> all&#160;at&#160;once </tab>
        <tab> <a ref='@research/autosuggest'> 12&#160;per&#160;page </a> </tab>
          </xsl:when>
          <xsl:otherwise>
        <tab> <a ref='@research/autosuggest-all'>all&#160;at&#160;once</a> </tab>
        <tab selected='1'> 12&#160;per&#160;page </tab>
          </xsl:otherwise>
        </xsl:choose>
        <tab> <a ref='@research/autosuggest-1by1'>one&#160;by&#160;one</a> </tab>
      </xsl:with-param>
      <xsl:with-param name='content'>



    <form screen='{$form-target}'
          xsl:use-attribute-sets='form' class='important' name='suggestions'>

            <xsl:text>
            </xsl:text>
            
<div>
      <input type='hidden' name='mode'   value='add'/>
      <input type='hidden' name='source' value='suggestions'/>
</div>

            <xsl:text>
            </xsl:text>
            
            <p>

              We have <xsl:value-of select='$suggestions-count'/>
              <xsl:text> item</xsl:text>
              <xsl:choose>
                <xsl:when test='$suggestions-count != 1'>s</xsl:when>
              </xsl:choose>
              
              <xsl:choose>
                <xsl:when test='$more-to-follow'>
                  <xsl:text> total and </xsl:text>
                  <xsl:value-of select='$chunk-size'/> 
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

                  <xsl:text> to follow.</xsl:text>

                </xsl:when>
                <xsl:when test='$suggestions-count &gt; 1'>

                  <xsl:text> and they are below.</xsl:text>

                </xsl:when>
                <xsl:when test='$suggestions-count = 1'>

                  <xsl:text> and it is below.</xsl:text>

                </xsl:when>
                <xsl:otherwise>

                  <xsl:text>.</xsl:text>

                </xsl:otherwise>
              </xsl:choose>

              <xsl:text>  </xsl:text>
              <input type='submit' value='Continue/Add checked items'/>

            </p>
            
            <xsl:text>
            </xsl:text>

      
            <xsl:call-template name='suggestions-table'/>

            
      <xsl:if test='count( $suggestions/list-item/list/list-item[id] )'>
        <p>
          <label for='refuse-ignored'>
            <input type='checkbox' name='refuse-ignored'
                   id='refuse-ignored' value='1'
             ><xsl:if test='$form-values/refuse-ignored/text()'
             ><xsl:attribute name='checked'
             /></xsl:if
             ></input>

            <i> &#x201C;I have no connection to the works <b>not selected</b> above.
            Add these works to the <a ref='@research/refused' >refused list</a> and
            do not suggest them to me in the
            future.&#x201D;</i>
          </label>
        </p>
        
        <p>
          <input type='submit' name='save' 
                 value='Add checked items to my profile and continue' 
                 title='Save the choices you made above, if any'
                 class='important'
                 />
          
        </p>
      </xsl:if>
      
      <xsl:if test='not(count( $suggestions/list-item/list/list-item[id] ))'>
        <xsl:if test='$back-search-running'>
          <p>
            <a ref='@research/autosuggest' >Reload this page to
            check for more suggestions</a>
          </p>
        </xsl:if>
      </xsl:if>
      
    </form>


</xsl:with-param></xsl:call-template>

  </xsl:template>










  <!--  now the phrasing  -->
  
  <xsl:variable name='search-status'>
    <xsl:choose>
      <xsl:when test='$back-search-started'>
        <xsl:text>We have just started the automatic search for your works.
        While system does search, you shall be able to see what's found and
        make decisions about it.  The page will reload soon and you might see
        the first results.</xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-running'>
        <xsl:text>The automatic search for your works is going on. </xsl:text>
        <xsl:if test='number( $started-that-ago ) &gt; 1'
                >(Started <xsl:value-of
                select='$started-that-ago'/> minutes ago.)
        </xsl:if>
      </xsl:when>
      <xsl:when test='$back-search-finished'>
        <xsl:text>The automatic search for your works has finished.</xsl:text>
      </xsl:when>
      <xsl:when test='$back-search-start-failed'>
        <xsl:text>We tried to start the automatic search for your works, but it
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
      <xsl:when test='$back-search-not-needed and $any-suggestions'>
        <xsl:text>Here is what we have for you since then.</xsl:text>
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
            <xsl:value-of select='$new-if-new'/> yet. 
            <a ref='@research/autosuggest' >Reload the page</a> in 20 seconds or
            so.<xsl:text/>
          </xsl:when>
          <xsl:when test='$back-search-finished'>
            We didn't find 
            anything<xsl:value-of select='$new-if-new'/>.
          </xsl:when>

          <xsl:otherwise>

            <xsl:text>There's nothing we can suggest now.</xsl:text>

          </xsl:otherwise>

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



  <xsl:template name='page-introduction'>
    <xsl:choose>
      <xsl:when test='$suggestions-count'>

        <p>Our automatic search found the following works that may be
        authored by you. Check the ones you have authored and click on
        the submit button at the top or bottom of the page to add
        these works to your profile.</p>

      </xsl:when>
      <xsl:when test='$back-search-running'>

        <p>We don't have any suggestions for you yet.  Search
        is going on.</p>

      </xsl:when>
      <xsl:otherwise>
        
        <p>We don't have any (more) suggestions for you.</p>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>




  <xsl:template name='suggestions-sublist-explanation'>
    <xsl:param name='list'/>

    <xsl:for-each select='$list'>
      <xsl:choose xml:space='default'>
        <xsl:when test='reason = "exact-name-variation-match"'>
          
        <xsl:text/>Found by exact matching <a
        ref='@name?back={$request-screen}' >your name and its
        variations</a> among the document author and editor
        names:<xsl:text/>

      </xsl:when>

        <xsl:when test='reason = "name-variation-part-match"
                  or reason = "exact-name-variation-part-matc"'>
          
        <xsl:text/>Found by a partial match of <a
        ref='@name?back={$request-screen}' 
        >your name and its variations</a>
        among the document creators' names:<xsl:text/>

      </xsl:when>
      <xsl:when test='reason = "exact-person-id-match"'>
          
        <xsl:text/>Found because the document's metadata pointed to
        your personal record through its short-id (<code
        class='id'><xsl:value-of select='$record-sid'/></code>):<xsl:text/>

      </xsl:when>

      <xsl:when test='reason = "exact-email-match"'>
          
        <xsl:text>Found by email address:</xsl:text>

      </xsl:when>

      <xsl:when test='
                reason = "approximate-name-variation-match" 
                or reason = "approximate-1" 
                or reason = "approximate-2" 
      '>

        <xsl:text>Found by approximate matching your name and its
        variations to document authors names.  Should have caught most
        misspelled occurrences:</xsl:text>

      </xsl:when>
      <xsl:when test='reason = "surname-part-match"'>
        
        <xsl:text>The documents in whose description we found your
        surname:</xsl:text>

      </xsl:when>
      <xsl:otherwise>
      
        <xsl:text>Some more research items for your review:</xsl:text>

      </xsl:otherwise>
    </xsl:choose>
    </xsl:for-each>
  </xsl:template>    







  <xsl:variable name='name-variations' xml:space='preserve'>
<ul class='names nameVariations' id='nameVariationsList'>
<xsl:for-each select='//autosearch/names-list/list-item'
><li class='name'><xsl:value-of select='text()'/></li>
</xsl:for-each>
</ul>
  </xsl:variable>

  <xsl:variable name='name-variations-linked' xml:space='preserve'>
<ul style='margin-bottom: 0;' class='names nameVariations' id='nameVariationsList'>
<xsl:for-each select='//autosearch/names-list/list-item'
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

    <p>The automatic search uses name variations list to find your
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
    
</xsl:template>








  <xsl:template name='the-contributions'>

    <h1>Automatic search</h1>

<xsl:text>
</xsl:text>

    <xsl:call-template name='show-status'/>

    <xsl:call-template name='page-introduction'/>

<!--
    <p>old:
      <xsl:copy-of select='$search-status'/>
      <xsl:text> </xsl:text>
      <xsl:copy-of select='$search-result'/>
    </p>
-->

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

      <h2><a href='javascript:hide("not-satisfied-invite");show("not-satisfied-open");'
      class='int'
      >Not satisfied with search results?</a></h2>
      
    </div>
    
    <div id='not-satisfied-open' style='display: none;' class='open'>
      
      <h2>Not satisfied with search results?</h2>
      
      <phrase ref='not-satisfied-with-automatic-search'/>

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



  <!--   n o w   t h e   p a g e   t e m p l a t e    -->

  
  <xsl:template match='/data'>

    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>autosearch suggestions</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='the-contributions'/>
      </xsl:with-param>

    </xsl:call-template>

  </xsl:template>



   
</xsl:stylesheet>

