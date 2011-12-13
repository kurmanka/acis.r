<xsl:stylesheet 
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:exsl='http://exslt.org/common'
    xmlns:acis='http://acis.openlib.org'
    xmlns:html='http://www.w3.org/1999/xhtml'    
    exclude-result-prefixes='exsl xsl html acis'
    version='1.0'>

  <xsl:import href='person-listings.xsl'/>

  <!--   u t i l i t y   t e m p l a t e s  -->
  <!-- generate description of a document (or another resource) -->  
  <xsl:template name='present-resource'>
    <xsl:param name='resource'/>
    <xsl:param name='for'/>
    <xsl:param name='label-onclick'/>
    <xsl:for-each select='$resource'>
      <xsl:if test='$for'>
        <label for='{$for}'>
          <xsl:if test='$label-onclick'>
            <xsl:attribute name='onclick'>
              <xsl:value-of select='$label-onclick'/>
            </xsl:attribute>
          </xsl:if>
        </label>
      </xsl:if>
      <xsl:choose>
        <xsl:when test='url-about/text()'>
          <a style='color: #000000' href='{url-about}' class='out' title='External link; id: {id}'>
            <span class='title'>              
              <xsl:value-of select='title'/>
            </span>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <span class='title'>
            <xsl:value-of select='title'/>
          </span>
        </xsl:otherwise>
      </xsl:choose>
      <!-- <small> -->
      <!-- <xsl:text> (</xsl:text> -->
      <!-- <xsl:value-of select='type'/> -->
      <!-- <xsl:text>, </xsl:text> -->
      <!-- XXX: I18N -->
      <!-- <xsl:choose> -->
      <!--   <xsl:when test='url-about/text()'> -->
      <!--     <a href='{url-about}' class='out' title='External link; id: {id}'>details</a> -->
      <!--   </xsl:when> -->
      <!--   <xsl:otherwise> -->
      <!--     <xsl:text/> id: <xsl:value-of select='id'/> -->
      <!--   </xsl:otherwise> -->
      <!-- </xsl:choose> -->
      <!-- relevance -->
      <!-- <xsl:if test='relevance'> -->
      <!--   <span class='relevance'> -->
      <!--     <xsl:value-of select='relevance'/> -->
      <!--   </span> -->
      <!-- </xsl:if> -->
      <!-- <xsl:text>)</xsl:text> -->
      <!-- </small>              -->
      <!-- display citation, from AMF:status data in the location -->
      <xsl:choose>
        <xsl:when test='url-about/text()'>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test='location/text()'>
            <br/>
            <small>
              <xsl:value-of select='location/text()'/>
            </small> 
            </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test='authors'>
        <br />
        <span>
          <xsl:text>by </xsl:text>
        </span>
        <xsl:variable name='number-of-authors'
                      select='string-length(authors) - string-length(translate(authors,"&amp;", ""))'/>        
        <!-- extra span that is clickable to show all authors -->
        <xsl:if test='$number-of-authors &gt; 9'>
          <span style='text-decoration: underline; color: green' 
                onclick='show_sibling_span_and_hide(this)'>
            <xsl:value-of select='$number-of-authors'/>
            <xsl:text> authors</xsl:text>              
          </span>
        </xsl:if>
        <span>
          <xsl:if test='$number-of-authors &gt; 9'>
            <xsl:attribute name='style'>
              <xsl:text>display: none</xsl:text>
            </xsl:attribute>
          </xsl:if>          
          <!-- defined in person-listings.xsl -->
          <xsl:call-template name='all-person-names'>
            <xsl:with-param name='name-string'>
              <xsl:value-of select='authors'/>
            </xsl:with-param>
            <xsl:with-param name='separator'>              
              <xsl:text> &amp; </xsl:text>
            </xsl:with-param>
          </xsl:call-template>
        </span> 
      </xsl:if>
      <xsl:if test='editors'>
        <br />
        <span class='name'>
          <xsl:text>edited by </xsl:text>
        <xsl:value-of select='editors'/></span> 
      </xsl:if>
    </xsl:for-each>   
  </xsl:template>

  <xsl:template name='list-resources'>
    <xsl:param name='list'/>
    <!-- there was an xml:space= preserve on the next element -->
    <xsl:for-each select='$list/list-item'>
      <li class='resource'>
        <xsl:call-template name='present-resource'>
          <xsl:with-param name='resource' 
                          select='.'/>
        </xsl:call-template>
      </li>
    </xsl:for-each>
  </xsl:template>
  <xsl:template name='list-first-resources'>
    <xsl:param name='how-many'/>
    <xsl:param name='list'/>
    <xsl:param name='start'
               select='number( "1" )'/>
    <li class='resource'>
      <xsl:call-template name='present-resource'>
        <xsl:with-param name='resource'
                        select='$list/list-item[position() = $start]'/>
      </xsl:call-template>
    </li>    
    <xsl:if test='$how-many > 1'>
      <xsl:if test='count( $list/list-item ) > $start+1'>
        <xsl:call-template name='list-first-resources'>
          <xsl:with-param name='list'     select='$list'/>
          <xsl:with-param name='start'    select='$start + 1'/>
          <xsl:with-param name='how-many' select='$how-many - 1'/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!--   L I S T   R E S O U R C E S   W I T H   L I M I T   -->
  <xsl:template name='list-resources-with-limit'>
    <xsl:param name='list'/>
    <xsl:variable name='count' select='count( $list/list-item[id and title] )'/>
    <xsl:variable name='treshold' select='"5"'/>
    <xsl:variable name='show' select='"3"'/>
    <xsl:choose>
      <xsl:when test='$count &gt; $treshold'>
        <ul class='suggestions resources'>
          <xsl:call-template name='list-first-resources'>
            <xsl:with-param name='list'     select='$list'/>
            <xsl:with-param name='how-many' select='$show'/>
          </xsl:call-template>          
          <li>
            <a ref='@research/accepted'>
              <xsl:text>... </xsl:text>
          <xsl:value-of select='$count - $show'/> more items</a></li>          
        </ul>
        <p>
          <a ref='@research/accepted'>
            <xsl:text>View or edit the list</xsl:text>
          </a>
          <xsl:text>.</xsl:text>
        </p>        
      </xsl:when>
      <xsl:otherwise>
        <ul class='suggestions resources'>
          <xsl:call-template name='list-resources'>
            <xsl:with-param name='list' select='$list'/>
          </xsl:call-template>
        </ul>        
        <p>
          <a ref='@research/accepted'>
            <xsl:text>Edit this list.</xsl:text>
          </a>
        </p>        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- what do do with author names. this needs to be -->
  <!-- defined for person-listings to work -->
  <xsl:template name='what-to-do-with-person-name'>
    <xsl:param name='person-name'/>
    <span class='person-name'>
      <em>
        <xsl:value-of select='$person-name'/>
      </em>
    </span>
  </xsl:template>

  <!--   L I S T   R E S O U R C E S   W I T H   L I M I T   H I D E   -->
  <xsl:template name='list-resources-with-limit-hide'>
    <xsl:param name='list'/>
    <xsl:param name='id'  />
    <xsl:variable name='count' select='count( $list/list-item[id and title] )'/>
    <xsl:variable name='treshold' select='"5"'/>
    <xsl:variable name='show' select='"3"'/>
    <xsl:choose>
      <xsl:when test='$count = 0'>
        <p>
          <xsl:text>None accepted yet.</xsl:text>
        </p>
      </xsl:when>      
      <xsl:when test='$count &gt; 1'>
        <p id='{$id}Brief'>
          <xsl:text>Already accepted: </xsl:text>
          <xsl:value-of select="$count"/>
          <xsl:text>items. [</xsl:text>
          <a href='javascript:hide("{$id}Brief");show("{$id}Full");'
           class='int'>
            <xsl:text>See them now</xsl:text>
            </a>
            <xsl:text>]&#160; </xsl:text>
        <a ref='@research/accepted'>
          <xsl:text>Detailed view and editing.</xsl:text>
        </a>
        </p>
      </xsl:when>
      <xsl:when test='$count = 1'>
        <p id='{$id}Brief'>
          <xsl:text>Already accepted: one item. [</xsl:text>
          <a href='javascript:hide("{$id}Brief");show("{$id}Full");'
             class='int'>
            <xsl:text>See it now</xsl:text>
          </a>
          <xsl:text>] </xsl:text>
          <xsl:text>&#160; </xsl:text>
          <a ref='@research/accepted'>
            <xsl:text>Detailed view and editing.</xsl:text>
          </a>
        </p>
      </xsl:when>
    </xsl:choose>    
    <xsl:choose>
      <xsl:when test='$count &gt; 0'>
        <div id='{$id}Full'
             style='display: none;'>
          <ul class='suggestions resources'>
            <xsl:call-template name='list-resources'>
              <xsl:with-param name='list'
                              select='$list'/>
            </xsl:call-template>
          </ul>
        <p>
          <xsl:text>[</xsl:text>
          <a href='javascript:hide("{$id}Full");show("{$id}Brief");' 
             class='int'>
            <xsl:text>Hide the list</xsl:text>
          </a>
            <xsl:text>]&#160; </xsl:text>
            <a ref='@research/accepted'>
              <xsl:text>Detailed view or editing.</xsl:text>
            </a>  
        </p>
        </div>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name='suggestions-sublist'>
    <xsl:param name='sublist'/>
    <xsl:param name='from'
               select='"0"'/>
    <xsl:param name='to'
               select='"1024"'/> 
    <!-- XXX max items per list -->
    <xsl:param name='status' 
               select='$sublist/status'/>    
    <xsl:choose xml:space='default'>
      <xsl:when test='$sublist/list/list-item'>
        <table class='suggestions resources'
               summary='Some suggestions for the research profile.'>
          <xsl:call-template name='table-resources-for-addition' 
                             xml:space='default'>
            <xsl:with-param name='list'
                            select='$sublist/list'/>
            <xsl:with-param name='role' 
                            select='$sublist/role'/>
            <xsl:with-param name='status'
                            select='$status'/>
            <xsl:with-param name='from'
                            select='$from'/>
            <xsl:with-param name='to'
                            select='$to'/>
          </xsl:call-template>
        </table>
      </xsl:when>
      <xsl:otherwise>
        <ul>
          <li>
            <xsl:text>[empty list]</xsl:text>
          </li>
        </ul>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>


