<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">
  <xsl:import href='affiliations-common.xsl' />
  <xsl:variable name='parents'>
    <acis:par id='affiliations'/>
  </xsl:variable>
  <!-- ToK 2008-04-06: was affiliations/search -->
  <xsl:variable name='current-screen-id'>affiliations/search</xsl:variable>  
  <!--    v a r i a b l e s    -->
  <xsl:variable name='affiliations' select='$response-data/affiliations'/>
  <xsl:variable name='search'       select='$response-data/institution-search'/> 
  <xsl:variable name='found-items'  select='$search/results'/> 
  <xsl:variable name='search-what'  select='$form-values/search-what/text()'/>   
  <xsl:template name='search-form'>    
    <p id='search-instructions'>
      <acis:phrase ref='institution-search-instructions'/>
    </p>
    <script type='text/javascript' 
            src='affiliations.js'></script>
    <!-- there was name='searchform' -->
    <acis:form screen='@affiliations/search' 
               xsl:use-attribute-sets='form' 
               class='narrow'
               name='searchform'>
      <xsl:text> </xsl:text>
      <div id='please-wait' style='position: absolute; display: none; z-index: 1;'>
        <p style='width: auto; padding: 10px; position: static;'  class='Hint'>
          <big style='text-align: center;'>
            <xsl:text>PLEASE, WAIT...</xsl:text>
          </big>
        </p>
        <!-- xdisplay: table; xmargin-left: auto; xmargin-right: auto; -->
      </div>      
      <xsl:text> </xsl:text>      
      <table id='controls'>
        <tr>
          <td>
            <xsl:call-template name='fieldset'>
              <xsl:with-param name='content'>                
                <acis:input name='search-what' 
                            id="what" 
                            value='{$search-what}' 
                            size='35'>
                  <acis:check nonempty=''/>
                  <acis:name>
                    <xsl:text>a search expression</xsl:text>
                  </acis:name>
                </acis:input>
                <xsl:text> </xsl:text>
              </xsl:with-param>
            </xsl:call-template>            
            <input type='submit' 
                   name='search' 
                   value=' Find! ' />
            <xsl:text> </xsl:text>
            <input type='button' 
                   value='Clear' 
                   onclick='javascript:search_clear_and_focus();'/>            
            <br/>            
            <xsl:call-template name='fieldset'>
              <xsl:with-param name='content'>
                <!-- support search by name only -->
                <input type='hidden' 
                       name='search-by' 
                       value='name'/>
                <!-- <label for='search-by-name' onclick='javascript:search_focus();'> -->
                <!-- <acis:input type='radio' name='search-by' id='search-by-name' value='name' checked=''/> -->
                <!-- <span onclick='javascript:search_focus();'>institution name</span> -->
                <!-- </label> -->
                <!-- <xsl:text>&#160; </xsl:text>                 -->
                <!-- <acis:input type='radio' name='search-by' id='search-by-location' value='location' -->
                <!-- onclick='javascript:search_focus();'/> -->
                <!-- <xsl:text> </xsl:text> -->
                <!-- <label for='search-by-location' title='city or town name' -->
                <!-- onclick='javascript:search_focus();'>city or town</label> -->
              </xsl:with-param>
            </xsl:call-template>
          </td>
          <td style='vertical-align: top; padding-top: .6em;'>
            <span id='show-instructions-trigger' 
                  style='display: none;'>
              <small>
                <xsl:text>[</xsl:text>
                <a href='javascript:show_instructions();search_focus();' 
                   class='int'>
                  <xsl:text>Show search instructions</xsl:text>
                </a>
                <xsl:text>]</xsl:text>
            </small></span>
          </td>
        </tr>
      </table>
      <xsl:text> </xsl:text>
      <!--          <xsl:choose xml:space='default'> -->
      <!--          <xsl:when test='$search/results'> -->
      <!--          <acis:script-onload>hide_instructions();</acis:script-onload> -->
      <!--          </xsl:when> -->
      <!--          </xsl:choose> -->           
      <acis:onsubmit>
        var controls = getRef( "controls" );
        var trigger  = getRef( "show-instructions-trigger" );
        var message  = getRef( "please-wait" );        
        controls.style.visibility='hidden';
        trigger.style.visibility='hidden';
        message.style.display = 'block'; 
        getRef( "what" ).blur();
      </acis:onsubmit>      
    </acis:form> 
  </xsl:template>
  <!--  main affiliations search screen template -->
  <xsl:template name='the-affiliations-search'>    
    <h1>
      <xsl:text>Institution search results</xsl:text>
    </h1>    
    <xsl:call-template name='show-status'>
      <xsl:with-param name='fields-spec-uri' 
                      select='"fields-institution.xml"'/>
    </xsl:call-template>   
    <xsl:call-template name='search-form'/>
    <xsl:text> </xsl:text>
    <xsl:if test='$search' 
            xml:space='default'>      
      <xsl:text> </xsl:text>                 
      <!--Now we are about to display the search results.   -->
      <!--First, if there were more than several exact matches and if not the -->
      <!--"loose-match" mode, the fulltext results are optional.  They shall -->
      <!--be hidden and shown only if user requests them. -->
      <!--Loose matches shall be shown if there are no exact matches and little -->
      <!--fulltext matches or if the mode is "loose-match". -->
      <!--3 options: -->
      <!--exact-count > 5  => hide fulltext matches, don't render loose matches  -->
      <!--exact-count == 0 => show fulltext matches -->
      <!--ft-count < 10    => show fulltext and loose matches -->    
      <div id='search-results'>
        <xsl:variable name='mode'
                      select='$search/mode/text()'/>
        <xsl:variable name='loose-mode' 
                      select='$mode = "loose-match"'/>
        <xsl:variable name='exact' 
                      select='$found-items/exact'/>
        <xsl:variable name='ft'    
                      select='$found-items/fulltext'/>
        <xsl:variable name='loose' 
                      select='$found-items/loose'/>
        <xsl:variable name='exact-count'
                      select='count($exact/list-item)'/>
        <xsl:variable name='ft-count'
                      select='count($ft/list-item)'/>
        <xsl:variable name='loose-count'
                      select='count($loose/list-item)'/>
        <xsl:variable name='show-loose'  
                      select='$loose-count and ( $loose-mode or ( $exact-count = 0 and $ft-count &lt; 10 ) )'/>
        <xsl:variable name='loose-mode-form'>
          <!-- fixme: Would be great to replace this form with a simple link a[@href] here. -->
          <acis:form>
            <div>
              <input type='hidden'
                     name='search-what'
                     value='{$search-what}'/>
              <input type='hidden'
                     name='search-by'
                     value='{$form-input/search-by/text()}'/>
              <input type='hidden'
                     name='loose-match'
                     value='1'/>            
              <xsl:text>Some partial match results where omitted.</xsl:text>
              <input type='submit' 
                     name='search' 
                     value='Show omitted results'/>
            </div>
          </acis:form>
        </xsl:variable>     
        <xsl:if test='$exact-count'>
          <p>
            <xsl:text>Here is what we found:</xsl:text>
          </p>
          <div class='institutions exact-search-results'>
            <xsl:call-template name='show-institutions'>
              <xsl:with-param name='list'
                              select='$exact'/>
              <xsl:with-param name='mode'
                              select='"add"'/>
              <xsl:with-param name='full'
                              select='"false"'/>
            </xsl:call-template>
          </div>        
        </xsl:if>
        <!--  Fulltext matches -->      
        <xsl:if test='$ft-count'>
          <xsl:variable name='show' 
                        select='$loose-mode or $exact-count &lt;= 5'/>
          <div id='ft-matches'>
            <xsl:if test='not($show)'>
              <acis:script-onload>hide("ft-matches");show("ft-matches-trigger");</acis:script-onload>
            </xsl:if>          
            <p>
              <small>
                <xsl:text>Near matches:</xsl:text>
              </small>
            </p>          
            <xsl:call-template name='show-institutions'>
              <xsl:with-param name='list'
                              select='$ft'/>
              <xsl:with-param name='mode'
                              select='"add"'/>
              <xsl:with-param name='full'
                              select='"false"'/>
            </xsl:call-template>
          </div>        
          <xsl:if test='not($show)'>
            <p style='display: none'
               id='ft-matches-trigger'>
              <xsl:text>We also found some near matches, which are hidden.</xsl:text>
              <a href='javascript:show("ft-matches");hide("ft-matches-trigger");'
                 class='int'>
                <xsl:text>Would you like to see these (</xsl:text>
                <xsl:value-of select='$ft-count'/>
                <xsl:text>item</xsl:text>
              <xsl:if test='$ft-count&gt;1'>s</xsl:if>)</a>
            </p>
          </xsl:if>        
        </xsl:if>
        <xsl:if test='$loose-count and not( $show-loose )'>       
          <xsl:copy-of select='$loose-mode-form'/>
          <!-- <p>There are also some loose matches which you could check in loose mode.</p> -->          
        </xsl:if>
        <!--  Loose matches -->
        <xsl:if test='$show-loose'>
          <p>
            <small>Partial matches:</small>
          </p>        
          <xsl:call-template name='show-institutions'>
            <xsl:with-param name='list'
                            select='$loose'/>
            <xsl:with-param name='mode'
                            select='"add"'/>
            <xsl:with-param name='full'
                            select='"false"'/>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test='not( $exact-count ) and not( $ft-count) and not( $loose-count )'>
          <p>
            <strong>
            <xsl:text>Sorry, we found nothing at all.</xsl:text>
            </strong>
            <br/>
            <xsl:text> Did you spell it right?</xsl:text>
          </p>
        </xsl:if>      
        <xsl:text> </xsl:text>      
      </div>    
      <xsl:text> </xsl:text>    
    </xsl:if>  
    <xsl:call-template name='submit-invitation'/>
  </xsl:template>
  <!--   n o w   t h e   p a g e   t e m p l a t e    -->  
  <xsl:template match='/data'>
    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>affiliations: search</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='the-affiliations-search'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
