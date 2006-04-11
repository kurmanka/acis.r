<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='main.xsl' />
  <xsl:import href='../../widgets.xsl' />
  

  <xsl:variable name='parents'>
    <par id='research/main'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>research/refused</xsl:variable>


  <xsl:variable name='refused-count' 
                select='count( $refused/list-item )'/>

  <xsl:variable name='chunk-size' select='"12"'/>

  <xsl:variable name='paging'   select='$refused-count &gt; 15'/>
  <xsl:variable name='page'     select='$request-subscreen'/>
  <xsl:variable name='page-all' select='$page="all"'/>

  <xsl:variable name='page-num'>
    <xsl:choose>
      <xsl:when test='$paging and not($page)'>1</xsl:when>
      <xsl:when test='$paging and (($page -1) * $chunk-size ) &lt; $refused-count '
         ><xsl:value-of select='$page'/></xsl:when>
      <xsl:when test='$paging'
         ><xsl:value-of select='ceiling($refused-count div $chunk-size)'/></xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name='page-start' select='($page-num - 1) * $chunk-size +1' />
  <xsl:variable name='page-end'   select='$page-start + $chunk-size -1'/>
  <xsl:variable name='page-last'>
    <xsl:choose>
      <xsl:when test='$page-end &gt; $refused-count'><xsl:value-of select='$refused-count'/></xsl:when>
      <xsl:otherwise><xsl:value-of select='$page-end'/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
    

  <xsl:template name='table-resources-for-review'>
    <xsl:param name='list'/>

    <xsl:for-each select='$list/list-item[id and title]' xml:space='preserve'>
      <xsl:variable name="nid" select='generate-id(.)'/>
      <xsl:variable name="id" select='id'/>

      <xsl:variable name='alternate'><xsl:if test='position() mod 2'> alternate</xsl:if></xsl:variable>
      <tr class='resource{$alternate}' id='row_{$nid}'>
      <td valign='top'><xsl:value-of select='position()'/>.</td>

      <td>
        
          <xsl:call-template name='present-resource' xml:space='default'>
            <xsl:with-param name='resource' select='.'/>
          </xsl:call-template>

          <input type='submit' name='unrefuse_{$nid}' value='remove' 
                 class='RemoveButton' 
                 docid='{$id}'/>
          <input type='hidden' name='id_{$nid}'       value='{$id}'/>

      </td>
      </tr>

    </xsl:for-each>
  </xsl:template>




  <xsl:template name='table-resources-page-for-review'>
    <xsl:param name='list'/>

    <xsl:for-each select='$list/list-item[id and title]'
                  xml:space='preserve'>
    
      <xsl:if test='position()&gt;=$page-start and position()&lt;=$page-last' >
        <xsl:variable name="nid" select='generate-id(.)'/>
        <xsl:variable name="id" select='id'/>

        <xsl:variable name='alternate'><xsl:if test='position() mod 2'> alternate</xsl:if></xsl:variable>
        <tr class='resource{$alternate}' id='row_{$nid}'>
        <td valign='top'><xsl:value-of select='position()'/>.</td>

        <td>
        
          <xsl:call-template name='present-resource' xml:space='default'>
            <xsl:with-param name='resource' select='.'/>
          </xsl:call-template>

          <input type='submit' name='unrefuse_{$nid}' value='remove' 
                 class='RemoveButton' 
                 docid='{$id}'/>
          <input type='hidden' name='id_{$nid}'       value='{$id}'/>

        </td>
        </tr>
      </xsl:if>

    </xsl:for-each>
  </xsl:template>



  <xsl:template name='refused-list-all'>

        <form screen='@research/refused/all' 
              xsl:use-attribute-sets='form'>

          <xsl:choose>
          <xsl:when test='$refused-count &gt; 1'>
            <p>Here are the <xsl:value-of select='$refused-count'/>
            items, that you have refused some time in the past:</p>
          </xsl:when>
          <xsl:when test='$refused-count = 1'>
            <p>Here is the item, that you have refused some
            time in the past:</p>
          </xsl:when>
          </xsl:choose>
          
          <table class='resources'>
            <xsl:call-template name='table-resources-for-review'>
              <xsl:with-param name='list' select='$refused'/>
            </xsl:call-template>
          </table>
          
        </form>

  </xsl:template>



 
  <xsl:template name='prev-page-link'>
    <xsl:choose>
      <xsl:when test='$page-num = 1'>
         <span class='disabled'>Back</span>
      </xsl:when>
      <xsl:otherwise>
         <a ref='@research/refused/{$page-num -1}'>Back</a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template name='next-page-link'>
    <xsl:choose>
      <xsl:when test='$page-last = $refused-count'>
         <span class='disabled'>Forth</span>
      </xsl:when>
      <xsl:otherwise>
         <a ref='@research/refused/{$page-num +1}'>Forth</a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


 <xsl:template name='refused-list-chunk'>

     <xsl:variable name='sub'>
       <xsl:if test='$page'>/<xsl:value-of select="$page"/></xsl:if>
     </xsl:variable>

     <form screen='@research/refused{$sub}' xsl:use-attribute-sets='form' id='refused' >

          <p>Here are the items <xsl:value-of select='$page-start' />-<xsl:value-of
          select='$page-last'/> (of <xsl:value-of select='$refused-count' /> total) you 
          have refused some time in the past:</p>

          <table class='resources'>
            <xsl:call-template name='table-resources-page-for-review'>
              <xsl:with-param name='list' select='$refused'/>
            </xsl:call-template>
          </table>
          
          <p><small>Navigate: </small>
          <xsl:call-template name='prev-page-link'/>
           ... 
          <xsl:call-template name='next-page-link'/>
          </p>

          <p>Total number of refused items: <xsl:value-of select='$refused-count'/>.</p>

        </form>

  </xsl:template>

                      


  <xsl:template name='research-refused'>


    <h1>Refused research items</h1>

    <xsl:comment> subscreen <xsl:value-of select='$request-subscreen'/> </xsl:comment>

    <xsl:call-template name='show-status'/>

    <xsl:choose>
      <xsl:when test='$paging and $page-all'>
      
         <xsl:call-template name='tabset'>
            <xsl:with-param name='id' select='"tabs"'/>
            <xsl:with-param name='tabs'>
               <tab selected='1'> all&#160;at&#160;once </tab>
               <tab> <a ref='@research/refused'> 12&#160;per&#160;page </a> </tab>
            </xsl:with-param>
            <xsl:with-param name='content'>
 
              <xsl:call-template name='refused-list-all'/>

            </xsl:with-param>
         </xsl:call-template>

      </xsl:when>

      <xsl:when test='$paging and not($page-all)'>

         <xsl:call-template name='tabset'>
            <xsl:with-param name='id' select='"tabs"'/>
            <xsl:with-param name='tabs'>
              <tab> <a ref='@research/refused/all'>all&#160;at&#160;once</a> </tab>
              <tab selected='1'> 12&#160;per&#160;page </tab>
            </xsl:with-param>
            <xsl:with-param name='content'>
 
               <xsl:call-template name='refused-list-chunk'/>

            </xsl:with-param>
         </xsl:call-template>

      </xsl:when>

      <xsl:when test='$refused/list-item'>

        <xsl:call-template name='refused-list-all'/>

      </xsl:when>
    
      <xsl:otherwise> 

        <p>At this moment, there are no refused research
        items in your profile.</p>

      </xsl:otherwise>
  
    </xsl:choose>

    <script-onload>

function remove_button_click() {
  var docid=this.getAttribute('docid');
  this.setAttribute("disabled", 1);
  var button = this;
  if ( docid ) {
    $.post( "/research/refused/xml", { unrefuse: docid },
      function () { 
        var parent = button.parentNode;
        $(parent.parentNode).addClass("disabled"); 
        $(button).remove();
        $(parent).append( " &amp;nbsp;  &lt;b>(removed)&lt;/b>" );
      }
    );
  }
  return false;
}
 
    $("form#refused").submit( function (){ alert( "the form is submited" ); return false; } );
    $("input.RemoveButton").click( remove_button_click );

    </script-onload>



  </xsl:template>





  <xsl:variable name='page-id'>researchRefused</xsl:variable>
  <xsl:variable name='additional-head-stuff'>
        <script type="text/javascript" src='{$base-url}/script/jquery.js'></script>
<!--
        <script type="text/javascript" src='{$base-url}/script/ajax.js'></script>
        <script type="text/javascript" src='{$base-url}/script/xmlrequest.js'></script>
-->
  </xsl:variable>
  

  <!--   n o w   t h e   p a g e   t e m p l a t e    -->

    
  <xsl:template match='/data'>

    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>refused items</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='research-refused'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

    

</xsl:stylesheet>