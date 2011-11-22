<xsl:stylesheet 
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:exsl='http://exslt.org/common'
    xmlns:acis='http://acis.openlib.org'
    xmlns:html='http://www.w3.org/1999/xhtml'
    exclude-result-prefixes='exsl xml html acis'
    version='1.0'>
  <xsl:import href='main.xsl'/>
  <xsl:import href='../../widgets.xsl'/>
  <xsl:import href='research_common.xsl'/>
  <xsl:import href='listings.xsl'/>
  <xsl:variable name='parents'>
    <acis:par id='research/main'/>
  </xsl:variable>
  <xsl:variable name='the-screen'>refused</xsl:variable>
  <xsl:variable name='current-screen-id'>
    <xsl:text>research/refused</xsl:text>
  </xsl:variable>
  <xsl:variable name='incoming-chunk-number' 
                select='/data/chunk/hash-item[@key=$current-screen-id]'/>
  <xsl:variable name='items-count' 
                select='count( $refused/list-item )'/>
  <xsl:variable name='max-chunk'
                select='($items-count - ($items-count mod $chunk-size)) div $chunk-size'/>
  <!-- auxilliary variable, not to be used anywhere but the next definition -->
  <xsl:variable name='chunk-times'
                select='($incoming-chunk-number - ($incoming-chunk-number mod ($max-chunk+1))) div ($max-chunk + 1)'/>
  <!-- rolls between the zero and max-chunk -->
  <xsl:variable name='chunk-number'
                select='$incoming-chunk-number - ($max-chunk + 1) * $chunk-times'/>
  <!-- fixme: not used but referenced in research_common.xsl.xml -->
  <xsl:variable name='more-to-follow' 
                select='"99"'/>
  <!-- fixme: not used but referenced in research_common.xsl.xml -->
  <xsl:variable name='more-to-follow-count' 
                select='"99"'/>
  <!-- fixme: not used but referenced in research_common.xsl.xml -->
  <xsl:variable name='this-chunk-size' 
                select='"100"'/>
  <!-- the number of items at the end of a chunk -->
  <xsl:variable name='theoretical-last-number'
                select='$chunk-size * ($chunk-number + 1)'/>
  <xsl:variable name='last-number'>
    <xsl:choose>
      <xsl:when test='$incoming-chunk-number'>
        <!-- chunked case: find minimum -->
        <xsl:choose>
          <xsl:when test='$theoretical-last-number &lt; $items-count'>
            <xsl:value-of select='$theoretical-last-number'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='$items-count'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- full case -->
      <xsl:otherwise>
        <xsl:value-of select='$items-count'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name='first-number'>
    <xsl:choose>
      <!-- chunked case -->
      <xsl:when test='$incoming-chunk-number &gt; 0'>
        <xsl:value-of select='($chunk-number) * $chunk-size + 1'/>
      </xsl:when>
      <!-- full case -->
      <xsl:otherwise>
        <xsl:value-of select='"1"'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:template name='table-resources-for-review-range'>
    <xsl:param name='first'/>
    <xsl:param name='last'/>
    <xsl:for-each select='$refused/list-item[id]'>
      <xsl:variable name='pos'>
        <xsl:value-of select='@pos'/>
      </xsl:variable>
      <!-- pos starts counting at 0 -->
      <xsl:variable name='firstpos'>
        <xsl:value-of select='$first - 1'/>
      </xsl:variable>
      <xsl:variable name='lastpos'>
        <xsl:value-of select='$last - 1'/>
      </xsl:variable>
      <xsl:if test='$pos &gt;= $firstpos'>
        <xsl:if test='$pos &lt;= $lastpos'>
          <xsl:variable name='wid' 
                        select='generate-id(.)'/>
          <xsl:variable name='id'
                        select='id'/>
          <xsl:variable name='alternate'>
            <xsl:if test='position() mod 2'>
              <xsl:text> alternate</xsl:text>
            </xsl:if>
          </xsl:variable>
          <tr class='resource{$alternate}'
              id='row_{$wid}'
              valign='baseline'>        
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
              </xsl:call-template>
            </td>
            <xsl:call-template name='refuse-choice'/>
          </tr>      
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  <xsl:variable name='the-navigating-tabs'>
    <xsl:choose>
      <!-- chunked case -->
      <xsl:when test='$incoming-chunk-number'>
        <!-- the "all" tab, not selected -->
        <acis:tab>
          <a>
            <xsl:attribute name='ref'>
              <xsl:text>@research/</xsl:text>
              <xsl:value-of select='$the-screen'/>
            </xsl:attribute>
            <xsl:text> all at once </xsl:text>
          </a> 
        </acis:tab>
        <!-- the previous tab -->
        <xsl:variable name='previous-start'>
          <xsl:if test='$chunk-number &gt; 0'>
            <xsl:value-of select='$first-number - $chunk-size'/>
          </xsl:if>
          <xsl:if test='$chunk-number = 0'>
            <xsl:value-of select='$max-chunk * $chunk-size'/>
          </xsl:if>
        </xsl:variable>
        <xsl:variable name='previous-end'>
          <xsl:choose>
            <xsl:when test='$chunk-number &gt; 0'>
              <xsl:value-of select='$first-number - 1'/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select='$items-count'/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test='$incoming-chunk-number &gt; 0'>
          <acis:tab>
            <a>
              <xsl:attribute name='ref'>
                <xsl:text>@research/</xsl:text>
                <xsl:value-of select='$the-screen'/>
                <xsl:text>-chunk-backward</xsl:text>
              </xsl:attribute>
              <xsl:value-of select='$previous-start'/>
              <xsl:text> to </xsl:text>
              <xsl:value-of select='$previous-end'/>
            </a> 
          </acis:tab>
        </xsl:if>
        <!-- current tab -->
        <acis:tab>
          <xsl:attribute name='selected'>1</xsl:attribute>
          <xsl:value-of select='$chunk-size'/>
          <xsl:text> per page </xsl:text>
        </acis:tab>
        <!-- the next tab -->
        <xsl:if test='$chunk-size &lt; $items-count'>
          <xsl:variable name='next-end'>
            <xsl:if test='$chunk-number &lt; $max-chunk'> 
              <xsl:choose>
                <xsl:when test='$last-number + $chunk-size &lt; $items-count'>
                  <xsl:value-of select='$last-number + $chunk-size'/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select='$items-count'/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
            <!-- chunk overlap case -->
            <xsl:if test='$chunk-number = $max-chunk'> 
              <xsl:value-of select='$chunk-size'/>
            </xsl:if>
          </xsl:variable>
          <xsl:variable name='next-start'>
            <xsl:if test='$chunk-number &lt; $max-chunk'>
              <xsl:value-of select='$last-number + 1'/>
            </xsl:if>
            <!-- chunk overlap case --> 
            <xsl:if test='$chunk-number = $max-chunk'> 
              <xsl:value-of select='"1"'/>
            </xsl:if>
          </xsl:variable>
          <!-- paul levine bug of exactly 200 papers -->
          <xsl:if test="$next-end &gt; $next-start">            
            <acis:tab>
              <a>
                <xsl:attribute name='ref'>
                  <xsl:text>@research/</xsl:text>
                  <xsl:value-of select='$the-screen'/>
                  <xsl:text>-chunk-forward</xsl:text>
                </xsl:attribute>
                <xsl:value-of select='$next-start'/>
                <xsl:text> to </xsl:text>
                <xsl:value-of select='$next-end'/>
              </a> 
            </acis:tab>
          </xsl:if>          
        </xsl:if>
      </xsl:when>
      <!-- full case -->
      <xsl:otherwise>
        <acis:tab>
          <xsl:attribute name='selected'>1</xsl:attribute>
          <xsl:text> all at once </xsl:text>
        </acis:tab>
        <acis:tab>
          <a>
            <xsl:attribute name='ref'>
              <xsl:text>@research/</xsl:text>
              <xsl:value-of select='$the-screen'/>
              <xsl:text>-chunk</xsl:text>
            </xsl:attribute>
            <xsl:value-of select='$chunk-size'/>
            <xsl:text> per page </xsl:text>
          </a>           
        </acis:tab>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:template name='refused-list-all'>
    <xsl:call-template name='tabset'>
      <xsl:with-param name='id'
                      select='"tabs"'/>
      <xsl:with-param name='tabs'>
        <xsl:copy-of select='$the-navigating-tabs'/>
      </xsl:with-param>
      <xsl:with-param name='content'>
        <acis:form class='refused'
                   id='theform'
                   xsl:use-attribute-sets='form'>
          <xsl:attribute name='screen'>
            <xsl:choose>
              <xsl:when test='$incoming-chunk-number'>
                <xsl:text>@research/refused-chunk</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>@research/refused</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <table width='100%'>
            <tr>
              <td>
                <xsl:text>Here </xsl:text>        
                <xsl:if test='$items-count &gt; 1'>
                  <xsl:text>are </xsl:text>
                  <xsl:if test='$incoming-chunk-number'>
                    <xsl:if test='$first-number'>
                      <xsl:text> items number </xsl:text>
                      <xsl:value-of select='$first-number'/>
                      <xsl:text> to </xsl:text>
                      <xsl:value-of select='$last-number'/>
                      <xsl:text> of</xsl:text>
                    </xsl:if>
                    <xsl:text> the </xsl:text>
                  </xsl:if>
                  <xsl:if test='not($incoming-chunk-number)'>
                    <xsl:text> all </xsl:text>
                  </xsl:if>
                  <xsl:value-of select='$items-count'/>                  
                  <xsl:text> items that you have </xsl:text>
                  <span class='refuse'>
                    <xsl:text>refused</xsl:text>
                  </span>
                  <xsl:text> so far, and thus claim not to have authored.</xsl:text>
                </xsl:if>
                <xsl:if test='$items-count = 1'>
                  <xsl:text>is the single item that you have </xsl:text>
                  <span class='refuse'>
                    <xsl:text>refused</xsl:text>
                  </span>
                  <xsl:text> so far, and thus claim not to have authored.</xsl:text>
                </xsl:if>
                <xsl:text> If you change your mind, you can </xsl:text>
                <span class='accept'>
                  <xsl:text>accept</xsl:text>
                </span>
                <xsl:text> any item into your </xsl:text>
                <a ref='@research/accepted' >
                  <xsl:text>research profile</xsl:text>
                </a>
                <xsl:text>.</xsl:text>
              </td>
              <!-- <td> -->
              <!-- <xsl:text>max-chunk: </xsl:text> -->
              <!-- <xsl:value-of select='$max-chunk'/> -->
              <!-- <xsl:text>chunk-times: </xsl:text> -->
              <!-- <xsl:value-of select='$chunk-times'/> -->
              <!-- <xsl:text>in-chunk: </xsl:text> -->
              <!-- <xsl:value-of select='$incoming-chunk-number'/> -->
              <!-- <xsl:text>chunk: </xsl:text> -->
              <!-- <xsl:value-of select='$chunk-number'/> -->
              <!-- </td> -->
              <td>
                <xsl:copy-of select='$save-and-continue-input'/>
              </td>
            </tr>
          </table>
          <!-- resources list -->
          <table class='suggestions resources'
                 summary='The items you have refused.'
                 width='100%'>
            <tr class='here'>
              <xsl:copy-of select='$item-description-header'/>
              <xsl:copy-of select='$by-you-header'/>
            </tr>
            <xsl:call-template name='table-resources-for-review-range'>
              <xsl:with-param name='list'
                              select='$refused'/>
              <xsl:with-param name='first'
                              select='$first-number'/>
              <xsl:with-param name='last'
                              select='$last-number'/>
            </xsl:call-template>
          </table>
          <!-- table bottom navigation -->
          <table width='100%'>
            <tr>
              <!-- "chunk" and "exit" inputs are different -->
              <!-- depite the fact that only one is shown -->
              <xsl:choose>                
                <xsl:when test='$incoming-chunk-number'>
                  <td align='right'>                
                    <xsl:copy-of select='$save-and-next-chunk-input'/>
                  </td>
                </xsl:when>
                <xsl:otherwise>
                  <td align='right'>
                    <xsl:copy-of select='$save-and-exit-input'/>
                  </td>
                </xsl:otherwise>
              </xsl:choose>
              <td align='right'>
                <xsl:copy-of select='$save-and-continue-input'/>
              </td>
            </tr>
          </table>     
        </acis:form>    
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  <xsl:template name='research-refused'>
    <h1 id='display'>
      <xsl:text>Refused research items</xsl:text>
    </h1>
    <xsl:comment>
      <xsl:text>subscreen </xsl:text>
      <xsl:value-of select='$request-subscreen'/>
    </xsl:comment>
    <xsl:call-template name='show-status'/>
    <xsl:choose>
      <xsl:when test='$refused/list-item'>
        <xsl:call-template name='refused-list-all'/>
      </xsl:when>
      <xsl:otherwise> 
        <p>
          <xsl:text> At this moment, there are no refused items in your profile.</xsl:text>
        </p>
      </xsl:otherwise>     
    </xsl:choose>
  </xsl:template>
  <xsl:variable name='page-id'>
    <xsl:text>researchRefused</xsl:text>
  </xsl:variable>
  <xsl:variable name='additional-head-stuff'>
    <!-- there used to a script element here, taken away 2010-06-13 -->
    <!-- <script type='text/javascript'  -->
    <!-- src='{$base-url}/script/refused.js'> -->
    <!-- </script> -->
    <script type='text/javascript' 
            src='{$base-url}/script/research.js'></script>
  </xsl:variable>
  <!--   n o w   t h e   p a g e   t e m p l a t e    -->
  <xsl:template match='/data'>
    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>
        <xsl:text>refused items</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='research-refused'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>