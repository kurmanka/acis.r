<xsl:stylesheet     
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">

  <xsl:import href='main.xsl' />
  <xsl:import href='listings.xsl' />
  <xsl:import href='old-table.xsl' />
  
  <xsl:variable name='parents'>
    <acis:par id='research/main'/>
  </xsl:variable>

  <!-- ToK: 2008-04-06: was research/search -->
  <xsl:variable name='current-screen-id'>research/search</xsl:variable>



  <!--    v a r i a b l e s    -->

  <xsl:variable name='search'       select='$contributions/search'/>


  <xsl:variable name='items-per-page'>30</xsl:variable>



  <xsl:variable name='the-page'>
    <xsl:choose>
      <xsl:when test='$form-input/page'>
        <xsl:choose>
          <xsl:when test='$form-input/forward'>
            <xsl:value-of select='$form-input/page +1'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='$form-input/page'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name='item-start'>
    <xsl:value-of select='number( $items-per-page ) * ( $the-page - 1 )'/>
  </xsl:variable>
  <xsl:variable name='item-end'>
    <xsl:value-of select='number( $item-start ) + number( $items-per-page ) -1'/>
  </xsl:variable>



  <xsl:template name='the-resources-search-form'>


    <xsl:variable name='field'>
      <xsl:choose>
        <xsl:when test='$search/field/text() = "title"' >title</xsl:when>
        <xsl:when test='$search/field/text() = "names"'>names</xsl:when>
        <xsl:when test='$search/field/text() = "id"'   >id</xsl:when>
        <xsl:otherwise>title</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

     <!-- changed name= to id=, then back to name=-->
    <acis:form screen='@research/search' name='searchform'>

      <table >
        <tr style='vertical-align: middle'>
          <td><label for='q' >Search for:</label></td>
          <td>
            <input type='text' name='q' id='q' size='50'
                   style='margin: 4px 4px 4px 0px;'
                   value='{$search/key}'>
                  <acis:check nonempty=''/>
                  <acis:name>a search expression</acis:name>
            </input>
          </td>
          <td>            
            <input type='submit' name='go' value=' FIND! ' class='significant'/>
            <xsl:text> </xsl:text>
            <input type='button' value='Clear' onclick='javascript:search_clear_and_focus()'/>
            
          </td>
        </tr>

        <tr>
          <td></td>
          <td style='border-bottom: 1px dotted #aaa; padding-bottom: 4px;'>
            <label for='phrase'>
              <input type='checkbox' name='phrase' id='phrase'>
                <xsl:if test='$search/phrasematch = "yes"'>
                  <xsl:attribute name='checked'/>
                </xsl:if>
                </input
                >&#160;<span title='as opposed to word search'>exact 
                substring search<br/>
                <small>(search for a part of a word or an exact
                phrase; very slow)</small>
                </span>
            </label>
          </td>
        </tr>
        
        <tr>
          <td style='text-align: right; vertical-align: top;'>in:</td>
          <td>
            <label for='field-title'>
              <input type='radio' name='field' value='title' id='field-title'>
                <xsl:if test='$field = "title"'>
                  <xsl:attribute name='checked'/>
                </xsl:if>
            </input> titles</label> 
            <br />

            <label for='field-names'>
              <input type='radio' name='field' value='names' id='field-names'>
                <xsl:if test='$field = "names"'>
                  <xsl:attribute name='checked'/>
                </xsl:if>
            </input> author and editor names</label> 
            <br />

            <label for='field-id'>
              <input type='radio' name='field' value='id' id='field-id'>
                <xsl:if test='$field = "id"'>
                  <xsl:attribute name='checked'/>
                </xsl:if>
            </input><xsl:text> </xsl:text>
            <acis:phrase ref='metadata-identifiers'/>
            </label>
          </td>

          <td></td>

        </tr>
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

<!--
      <div>
        <input type='submit' name='go' value=' Find! '/>
        <xsl:text> </xsl:text>
        <input type='button' value='Clear' onclick='javascript:search_clear_and_focus()'/>
      </div>
     
      <p class='spacer'>&#160;</p>
-->

    </acis:form>

  </xsl:template>






  <xsl:template name='the-search-results-form'>

    <xsl:variable name='result-number'>
      <xsl:value-of select='count( $search/list/list-item )'/>
    </xsl:variable>
    
    <!-- results paging -->

    <xsl:variable name='paging'>
      <xsl:choose>
        <xsl:when 
         test='$result-number and ( $result-number &gt; $items-per-page )'
        >yes</xsl:when>
        <xsl:otherwise>no</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name='next-page-exists'>
      <xsl:choose>
        <xsl:when test='$result-number &gt; $item-end'>yes</xsl:when>
        <xsl:otherwise>no</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name='last-shown-item-number'>
      <xsl:choose>
        <xsl:when test='$result-number &lt; $item-end'>
          <xsl:value-of select='$result-number -1'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='$item-end'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name='paging-sanity'>
      <xsl:choose>
        <xsl:when test='$result-number &gt; $item-start'>yes</xsl:when>
        <xsl:when test='$result-number = 0 and $item-start = 0'>yes</xsl:when>
        <xsl:otherwise>
          <xsl:message>Paging sanity problem:
 results: <xsl:value-of select='$result-number'/>
 item-start: <xsl:value-of select='$item-start'/>
          </xsl:message
        >no</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- /paging -->


    <acis:form xsl:use-attribute-sets='form'><!-- XXX -->
      <input type='hidden' name='mode'   value='add'/>
      <input type='hidden' name='source' value='search'/>
      <input type='hidden' name='page'   value='{$the-page}'/>

      <xsl:for-each select='$search'>
        
        <xsl:variable name='search-for'>
          <xsl:if test='phrasematch = "yes"'>phrase 
          '<xsl:value-of select='key/text()'/>'</xsl:if>
          <xsl:if test='phrasematch = "no"'
                  >word<xsl:if test='contains( key, " " )'>s</xsl:if>
          '<xsl:value-of select='key/text()'/>'</xsl:if>
        </xsl:variable>

        <xsl:variable name='search-what'>
          <xsl:choose>
            <xsl:when test='objects = "documents"   '>documents</xsl:when>
            <xsl:when test='objects = "resources"   '>documents and collections</xsl:when>
            <xsl:when test='objects = "collections" '>collections</xsl:when>
            <xsl:otherwise>unknown objects</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name='search-field'>
          <xsl:if test='field="title"'>titles</xsl:if>
          <xsl:if test='field="authors"'>authors</xsl:if>
          <xsl:if test='field="editors"'>editors</xsl:if>
          <xsl:if test='field="id"'>
            <acis:phrase ref='metadata-identifiers'/>
          </xsl:if>
          <xsl:if test='field="name"'>names</xsl:if>
        </xsl:variable>
        
        <xsl:variable name='result-phrasing'>
          <xsl:choose>
            <xsl:when test='$result-number &gt; 500'>more than 500 items</xsl:when>
            <xsl:when test='$result-number = 1'>just 1 item</xsl:when>
            <xsl:when test='$result-number = 0'>no items</xsl:when>
            <xsl:otherwise><xsl:value-of select='$result-number'/> items</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <p>We searched for <xsl:value-of select='$search-for'/>
        in <xsl:copy-of select='$search-field'/> 
        of <xsl:value-of select='$search-what'/>.  

        <strong>Found: <xsl:value-of select='$result-phrasing'/>.</strong>

        <xsl:text> </xsl:text>

        <small>May be we found more than that, but we
        <i>excluded</i> all the items you <i>already have</i> in your
        profile.</small></p>
              
        <xsl:if test='$paging = "yes"'><p>These are results 
        <xsl:value-of select='$item-start +1'/>-<xsl:value-of select='$last-shown-item-number +1'/>:</p>
        </xsl:if>

        <xsl:if test='list/list-item'>

          <xsl:call-template name='suggestions-sublist'>
            <xsl:with-param name='sublist' select='.'/>
            <xsl:with-param name='from' select='$item-start'/>
            <xsl:with-param name='to'   select='$item-end'/>
          </xsl:call-template>
        </xsl:if>

      </xsl:for-each>

      <xsl:if test='$paging = "yes"'>
        <p>
          <xsl:if test='$the-page &gt; 1'>
            <a ref='?page={$the-page -1}'>&#x2190; Previous page</a>
          </xsl:if>

          <xsl:if test='( $the-page &gt; 1 ) and ( $next-page-exists = "yes" )'>
            ...
          </xsl:if>

          <xsl:if test='( $next-page-exists = "yes" )'>
            <a ref='?page={$the-page +1}'>Next page &#x2192;</a>
          </xsl:if>
        </p>
      </xsl:if>

      <p>
        <xsl:choose>
          <xsl:when test=' $next-page-exists = "yes"'>
            <div class='buttonwrap'>
              <input type='submit' value='SAVE AND SHOW NEXT PAGE'
                     name='forward'
                     class='important'
            /></div>
          </xsl:when>
          <xsl:when test='$result-number &gt; 0'>
            <div class='buttonwrap'>
              <input type='submit' 
                     name='continue' class='important'
                     value='SAVE CHOICES' 
            /></div>
          </xsl:when>
        </xsl:choose>
      </p>
      
    </acis:form>

  </xsl:template>




  <xsl:template name='the-contributions-search'>

    <h1>Search for documents and other resources</h1>

    <xsl:call-template name='show-status'/>

    <xsl:call-template name='the-resources-search-form'/>

    <xsl:if test='$search/list'>
      <xsl:call-template name='the-search-results-form'/>
    </xsl:if>


  </xsl:template>




  <!--   n o w   t h e   p a g e   t e m p l a t e    -->

  
  <xsl:template match='/data'>

    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>search</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='the-contributions-search'/>
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template>

    

</xsl:stylesheet>