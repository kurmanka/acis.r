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

    <xsl:for-each select='$list/list-item[id]' xml:space='preserve'>
      <xsl:variable name="nid" select='generate-id(.)'/>
      <xsl:variable name="id" select='id'/>

      <xsl:variable name='alternate'><xsl:if test='position() mod 2'> alternate</xsl:if></xsl:variable>
      <tr class='resource{$alternate}' id='row_{$nid}'  valign='baseline'>

        <td class='but'>
          <input type='submit' name='unrefuse_{$nid}' value='remove' 
                               class='RemoveButton'   docid='{id}' 
           ><xsl:if test='position() = 1'><xsl:attribute name='id'
            >unrefuse_button1</xsl:attribute></xsl:if></input>

          <input type='hidden' name='id_{$nid}' value='{id}'/>
        </td>

        <td class='numb'>
          <xsl:choose><xsl:when test='position() = last()'>
            <span id='ncLast'><xsl:value-of select='position()'/>.</span>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='position()'/>.<xsl:text/>
          </xsl:otherwise>
          </xsl:choose>
        </td>

<xsl:choose>
  <xsl:when test='title'>
        <td class='title' ><a href='{url-about}' title='{normalize-space(title/text())}'><xsl:value-of select='title' /></a></td>
  </xsl:when>
  <xsl:when test='url-about'>
        <td class='title' >unknown, id: <a href='{url-about}'><xsl:value-of select='id' /></a></td>
  </xsl:when>
  <xsl:otherwise>
        <td class='title' ><small>title unknown, id: <xsl:value-of select='id'/></small></td>
  </xsl:otherwise>
</xsl:choose>
        <td class='authors' title='{authors}'><xsl:value-of select='authors'/></td>

      </tr>

    </xsl:for-each>
  </xsl:template>

  <xsl:template name='refused-list-all'>

        <form class='refused' 
              id='theform'
              screen='@research/refused' xsl:use-attribute-sets='form'>

          <xsl:choose>
          <xsl:when test='$refused-count &gt; 1'>
            <p>Here are the <xsl:value-of select='$refused-count'/>
            items that you have refused so far:</p>
          </xsl:when>
          <xsl:when test='$refused-count = 1'>
            <p>Here is the single item that you have refused so far:</p>
          </xsl:when>
          </xsl:choose>
          
          <table id='refusedTable' class='briefResources xfixedRowTable' cols='4'>
            <tr
              ><th class='but'
             /><th class='numb' 
             /><th>title of the work</th
             ><th class='authors'>the authors</th
            ></tr>
            <xsl:call-template name='table-resources-for-review'>
              <xsl:with-param name='list' select='$refused'/>
            </xsl:call-template>
          </table>
          
        </form>


<script-onload>
$("input.RemoveButton").click( remove_button_click );
setup_the_table();
</script-onload>

<script>

function setup_the_table() {

  var form   = get( 'theform' );
  var table  = get( 'refusedTable' );
  table &amp;&amp; form &amp;&amp; set_width_as( table, form );

  var table  = $( '#refusedTable' );
  table &amp;&amp; table.addClass( 'fixedRowTable' );

  var columns;
  if ( 0
       &amp;&amp; table 
       &amp;&amp; table.getElementsByTagName
       &amp;&amp; (columns = table.getElementsByTagName( 'th' ))
       &amp;&amp; columns[0] ) {

    var column1 = columns[0];
    var column2 = columns[1];

    var button = get( 'unrefuse_button1' );
    DEBUG( get_width( button ) + ' ' + get_width( column1 ) );

    button &amp;&amp; column1 &amp;&amp; set_width_as( column1, button, 32 );
    DEBUG( get_width( button ) + ' ' + get_width( column1 ) );

    var number = get( 'ncLast' );
    number &amp;&amp; column2 &amp;&amp; set_width_as( column2, number, 6 );
    DEBUG( get_width( button ) + ' ' + get_width( column1 ) );

  }

}


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
 



  </xsl:template>




  <xsl:template name='research-refused'>


    <h1 id='display'>Refused research items</h1>

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

  </xsl:template>





  <xsl:variable name='page-id'>researchRefused</xsl:variable>
  <xsl:variable name='additional-head-stuff'>
        <script type="text/javascript" src='{$base-url}/script/jquery.js'></script>
        <style type='text/css'>
/*  Fixed Row Table -- table with disabled text wrapping */

table.fixedRowTable {
        width: 100%;    /* need to be adjusted in IE */
	table-layout: fixed;
	border-collapse: collapse;
}

table.fixedRowTable tr td.title,
table.fixedRowTable tr td.authors {
	text-overflow:ellipsis;
	overflow: hidden;
	white-space:nowrap;
} 


/*   research/refused   */

form.refused { 
  padding-left:   0;
  padding-right:  0;
  padding-bottom: 0;
  margin-bottom: 3em;
}

form.refused p {
  margin-left:  2em;
  margin-right: 2em;
}


.briefResources {
  table-layout: auto;
  border-collapse: collapse;
  margin: 0;
  background:   #fff;
}

.briefResources td {
  padding-top:   .6ex;
  padding-left:  1ex;
  vertical-align: baseline;
}

.briefResources .but {
  width: 9.5ex;
  padding-left:  0;
}

.briefResources .numb {
  width: 4ex;
  color: #666;
  font-size: smaller;
}

table.briefResources th {
  border-bottom: 1px solid #ccc;
  font-weight: normal;
}

#researchRefused table tr .authors,
#researchRefused table.fixedRowTable  tr .authors,
#researchRefused table.briefResources tr .authors {
  width: 33%;
  padding-left: 1ex;
}

#researchRefused table tr td.authors,
#researchRefused table.fixedRowTable  tr td.authors,
#researchRefused table.briefResources tr td.authors {
  padding-bottom: 1em;
}

#researchRefused table.briefResources .but,
#researchRefused table.fixedRowTable .but  { 
  width: 9.5ex; 
  padding-left: 0;
}

#researchRefused table.briefResources .numb,
#researchRefused table.fixedRowTable .numb {
  width: 4ex; 
}

#researchRefused table.fixedRowTable {}
#researchRefused table.fixedRowTable td {
  padding-top:   .6ex;
  vertical-align: baseline;
}





#researchRefused input.RemoveButton {
  background: #f4f4f4;
  font-size: 80%;
  margin: 0;
}


/* removed-items-rows */

table.briefResources tr.disabled td.but { 
  font-size: 80%;
}

table.briefResources tr.disabled td,
table.briefResources tr.disabled td a:link {
  color: #999;
}
table.briefResources tr.disabled td a:visited { color: #777; }



</style>

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