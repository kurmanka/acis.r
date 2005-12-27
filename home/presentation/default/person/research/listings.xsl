<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">


  <!--   u t i l i t y   t e m p l a t e s  -->

  <!-- generate description of a document (or another resource) -->

  <xsl:template name='present-resource'>
    <xsl:param name='resource'/>
    <xsl:param name='for'/>
    <xsl:param name='label-onclick'/>

    <xsl:for-each select='$resource'>

      <xsl:choose>
        <xsl:when test='$for'>
          <label for='{$for}'>
            <xsl:if test='$label-onclick'>
              <xsl:attribute name='onclick'
              ><xsl:value-of select='$label-onclick'
              /></xsl:attribute>
            </xsl:if>
            <span class='title'><xsl:value-of select='title'/></span>
          </label>
        </xsl:when>
        <xsl:otherwise>
          <span class='title'><xsl:value-of select='title'/></span>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:text>
      </xsl:text>

      <small>(<xsl:value-of select='type'/>, <!-- XXX: I18N -->
      <xsl:choose>
        <xsl:when test='url-about/text()'>
          <a href='{url-about}' class='out' title='External link; id: {id}'
             >details</a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text/> id: <xsl:value-of select='id'/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>)</xsl:text>
      </small> 

      <xsl:text>
      </xsl:text>


      <xsl:if test='authors'>
        <br />
        <span class='name'>by <xsl:value-of select='authors'/></span> 
      </xsl:if>
      <xsl:if test='editors'>
        <br />
        <span class='name'>edited by <xsl:value-of select='editors'/></span> 
      </xsl:if>

    </xsl:for-each>
    
  </xsl:template>



  <xsl:template name='list-resources'>
    <xsl:param name='list'/>
    
    <xsl:for-each select='$list/list-item' xml:space='preserve'>
      <li class='resource'>
        <xsl:call-template name='present-resource'><xsl:with-param name='resource' select='.'/></xsl:call-template>
      </li>

    </xsl:for-each>
  </xsl:template>





  <xsl:template name='list-first-resources'>
    <xsl:param name='how-many'/>
    <xsl:param name='list'/>
    <xsl:param name='start' select='number( "1" )'/>

    <li class='resource'>
      <xsl:call-template name='present-resource'
        ><xsl:with-param name='resource' select='$list/list-item[position() = $start]'
        /></xsl:call-template>
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

          <li><a ref='@research/identified'
          >... <xsl:value-of select='$count - $show'/> more items</a></li>

        </ul>
        
        <p><a ref='@research/identified'>View or edit the list</a>.</p>

      </xsl:when>
      <xsl:otherwise>

        <ul class='suggestions resources'>
          <xsl:call-template name='list-resources'>
            <xsl:with-param name='list' select='$list'/>
          </xsl:call-template>
        </ul>

        <p><a ref='@research/identified'
        >Edit this list.</a></p>

      </xsl:otherwise>
    </xsl:choose>
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
        <p>None identified yet.</p>
      </xsl:when>

      <xsl:when test='$count &gt; 1'>
        <p id='{$id}Brief'
           >Already identified: <xsl:value-of select="$count"/> items.
        [<a href='javascript:hide("{$id}Brief");show("{$id}Full");'
           class='int'
        >See them now</a>]  
        <xsl:text>&#160; </xsl:text>
        <a ref='@research/identified'
        >Detailed view and editing.</a>
        </p>
      </xsl:when>

      <xsl:when test='$count = 1'>
        <p id='{$id}Brief'>Already identified: one item.
        [<a href='javascript:hide("{$id}Brief");show("{$id}Full");'
           class='int'
        >See it now</a>] 
        <xsl:text>&#160; </xsl:text>
        <a ref='@research/identified'>Detailed view and editing.</a>
        </p>
      </xsl:when>
    </xsl:choose>

    <xsl:choose>
      <xsl:when test='$count &gt; 0'>

        <div id='{$id}Full' style='display: none;'>
          <ul class='suggestions resources'>
            <xsl:call-template name='list-resources'>
              <xsl:with-param name='list'     select='$list'/>
            </xsl:call-template>
          </ul>

        <p>
          [<a class='int'
          href='javascript:hide("{$id}Full");show("{$id}Brief");'
          >Hide the list</a>]
        <xsl:text>&#160; </xsl:text>
        <a ref='@research/identified'>Detailed view or editing.</a>  
          </p>

        </div>


      </xsl:when>
    </xsl:choose>


  </xsl:template>





  <xsl:template name='suggestions-sublist'>
    <xsl:param name='sublist'/>
    <xsl:param name='from' select='"0"'/>
    <xsl:param name='to'   select='"1024"'/> <!-- XXX max items per list -->
    <xsl:param name='status' select='$sublist/status'/>

    <xsl:choose xml:space='default'>
      <xsl:when test='$sublist/list/list-item'>

        <table class='suggestions resources'
               summary='Some suggestions for the research profile.'
               >
          <xsl:call-template name='table-resources-for-addition' xml:space='default'>
            <xsl:with-param name='list'   select='$sublist/list'/>
            <xsl:with-param name='role'   select='$sublist/role'/>
            <xsl:with-param name='status' select='$status'/>
            <xsl:with-param name='from'   select='$from'/>
            <xsl:with-param name='to'     select='$to'/>
          </xsl:call-template>
        </table>

      </xsl:when>
      <xsl:otherwise>

        <ul><li>[empty list]</li></ul>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>





</xsl:stylesheet>


