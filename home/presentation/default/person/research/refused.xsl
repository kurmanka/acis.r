<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='main.xsl' />
  

  <xsl:variable name='parents'>
    <par id='research/main'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>research/refused</xsl:variable>


  <xsl:variable name='refused-count' 
                select='count( $refused/list-item )'/>

  <xsl:template name='table-resources-for-review'>
    <xsl:param name='list'/>

    <xsl:for-each select='$list/list-item[id and title]' xml:space='preserve'>
      <xsl:variable name="nid" select='generate-id(.)'/>
      <xsl:variable name="id" select='id'/>

      <xsl:variable name='alternate'><xsl:if test='position() mod 2'> alternate</xsl:if></xsl:variable>
      <tr class='resource{$alternate}' id='row_{$nid}'>

        <td width='2%' class='but'>
          <input type='submit' name='unrefuse_{$nid}' value='remove' 
                               class='RemoveButton'   docid='{id}' 
           ><xsl:if test='position() = 1'><xsl:attribute name='id'
            >unrefuse_button1</xsl:attribute></xsl:if></input>

          <input type='hidden' name='id_{$nid}' value='{id}'/>
        </td>

        <td class='numb'   width='2%'>
          <xsl:choose><xsl:when test='position() = last()'>
            <span id='ncLast'><xsl:value-of select='position()'/>.</span>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='position()'/>.<xsl:text/>
          </xsl:otherwise>
          </xsl:choose>
        </td>

        <td class='title'   width='50%'><a href='{url-about}' title='{title}'><xsl:value-of select='title' /></a></td>
        <td class='authors' width='40%' title='{authors}'><xsl:value-of select='authors'/></td>

      </tr>

    </xsl:for-each>
  </xsl:template>

  <xsl:template name='refused-list-all'>

        <form class='refused' 
              id='theform'
              screen='@research/refused/all' xsl:use-attribute-sets='form'>

          <xsl:choose>
          <xsl:when test='$refused-count &gt; 1'>
            <p>Here are the <xsl:value-of select='$refused-count'/>
            items that you have refused so far:</p>
          </xsl:when>
          <xsl:when test='$refused-count = 1'>
            <p>Here is the single item that you have refused so far:</p>
          </xsl:when>
          </xsl:choose>
          
          <table id='refusedTable' class='briefResources fixedRowTable' cols='4'>
            <tr><th></th><th></th><th>title of the work</th><th>the authors</th></tr>
            <xsl:call-template name='table-resources-for-review'>
              <xsl:with-param name='list' select='$refused'/>
            </xsl:call-template>
          </table>
          
        </form>

<script-onload>
setWidths();
// var table  = $( '#refusedTable' );
// table &amp;&amp; table.addClass( 'fixedRowTable' );
window.onresize = setWidths;
</script-onload>

<script>
function setWidths() {

  var form   = get( 'theform' );
  var table  = get( 'refusedTable' );

  var columns;
  if ( table 
       &amp;&amp; table.getElementsByTagName
       &amp;&amp; (columns = table.getElementsByTagName( 'th' ))
       &amp;&amp; columns[0] ) {

    var column1 = columns[0];
    var column2 = columns[1];

    columns[2].width = '54%'; // title
    columns[3].width = '36%'; // authors

    var button = get( 'unrefuse_button1' );
    button &amp;&amp; column1 &amp;&amp; set_width_as( column1, button, 12 );

    var number = get( 'ncLast' );
    number &amp;&amp; column2 &amp;&amp; set_width_as( column2, number, 6 );
  }

  table &amp;&amp; form &amp;&amp; set_width_as( table, form );

}
</script>

  </xsl:template>




  <xsl:template name='research-refused'>


    <h1>Refused research items</h1>

    <xsl:comment> subscreen <xsl:value-of select='$request-subscreen'/> </xsl:comment>

    <xsl:call-template name='show-status'/>

    <xsl:choose>
      <xsl:when test='$refused/list-item'>

        <xsl:call-template name='refused-list-all'/>

      </xsl:when>
    
      <xsl:otherwise> 

        <p>At this moment, there are no refused research
        items in your profile.</p>

      </xsl:otherwise>
  
    </xsl:choose>

    <script>

function remove_button_click() {
  var docid=this.getAttribute('docid');
  this.setAttribute("disabled", 1);
  var button = this;
  if ( docid ) {
    $.post( "/research/refused/xml", { unrefuse: docid },
      function () { 
        var parent = button.parentNode;
        $(parent.parentNode).addClass("disabled"); 
        $(button).hide();
        $(parent).append( "removed" );
      }
    );
  }
  return false;
}

    </script>
 
<script-onload>
// $('#theform').submit( function (){ return false; } );
$("input.RemoveButton").click( remove_button_click );
</script-onload>



  </xsl:template>





  <xsl:variable name='page-id'>researchRefused</xsl:variable>
  <xsl:variable name='additional-head-stuff'>
        <script type="text/javascript" src='{$base-url}/script/jquery.js'></script>
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