<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common"
                exclude-result-prefixes='exsl xml'
                >

  <xsl:import href='autosuggest-chunk.xsl'/>
  
  <xsl:variable name='current-screen-id'>research/autosuggest</xsl:variable>

  <xsl:variable name='portion-size'>7</xsl:variable>



  <xsl:template name='the-contributions'>

<!--
    <xsl:call-template name='contributions-breadcrumb'/>
-->


    <h1 id='title'>Automatic search suggestions, one by one</h1>

    <xsl:call-template name='show-status'/>

    <noscript>
      <p class='error'>Sorry, this page requires JavaScript, 
      but your browser either doesn't support it or has it disabled.
      
      <a ref='@research/autosuggest'>Return to the basic suggestions page.</a>
      </p>
    </noscript>


    <xsl:call-template name='the-suggestions-form'/>

    
  </xsl:template>



  <xsl:template name='the-suggestions-form'>

    <xsl:call-template name='tabset'>
      <xsl:with-param name='id'>tabs</xsl:with-param>
      <xsl:with-param name='tabs'>
        <tab><a ref='@research/autosuggest-all'>all at once</a></tab>
        <tab><a ref='@research/autosuggest'>12 per page</a></tab>
        <tab selected='1'>one by one</tab>
      </xsl:with-param>
      <xsl:with-param name='content'>

    <form xsl:use-attribute-sets='form' 
          id='SUG' 
          screen='@research/autosuggest-1by1#title'
          class='important'>

      <div><!-- input element in HTML 4.01 cannot just be direct
      content of the form element -->
        <input type='hidden' name='mode'   value='add'/>
        <input type='hidden' name='source' value='suggestions'/>
      </div>

      <xsl:call-template name='suggestions-items'/>

    </form>

      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>




  <xsl:template name='suggestions-items'>

    <xsl:choose xml:space='default'>
      <xsl:when test='$suggestions/list-item/list/list-item'>

        <xsl:variable name='suggested-items' select='$suggestions//list/list-item'/>

<script>

var CurrentPage; var AutoRefuse = 0; var TheForm = "SUG";


function go_to_page( page ) {
 if ( CurrentPage ) {
   hide( CurrentPage );
 }
 show( page );
 
 CurrentPage = page;
}


function make_next_page_id ( page ) {
  var digits = "0123456789";
  var digit_position;
  for (var i=0; i &lt;= page.length; i++) {
    var ch = page.charAt( i );
    if ( digits.indexOf( ch ) > -1 ) {
      digit_position = i;
      break;
    }
  }

  if ( digit_position ) {
    var prefix = page.substring( 0, digit_position );
    var ending = page.substring( digit_position );
    var number = Number( ending );
    number++;
    ending = String( number );
    return prefix + ending ;
  }
  return 0;
}


//var test;
//test = make_next_page_id( "fa45" );
//alert( test );
//test = make_next_page_id( "fa_4" );
//alert( test );


function go_to_next_page ( ) {
  var nextPage;

  var page = CurrentPage;

  nextPage = make_next_page_id( page );

  if ( ! document.getElementById( nextPage ) ) { 
    nextPage = "good_bye_page";
  }

  go_to_page( nextPage );

  if ( nextPage == "good_bye_page" ) {
    Submit( TheForm );
    hide( "where-to-go" );
  } 
}

function decision( sid, add, role, refuse ) {
  if ( add )    { set_parameter( TheForm, "add_"+sid,    add );     }
  if ( role )   { set_parameter( TheForm, "role_"+sid,   role );    }
  if ( refuse ) { set_parameter( TheForm, "refuse_"+sid, refuse );  }

  go_to_next_page( );
  hide( "where-to-go" );
}


function not_my( item ) {
  var refuse = AutoRefuse;
  decision( item, '', '', refuse );
}

function role( item, role ) {
  decision( item, 1, role, '' );
}

</script>

        <xsl:for-each select='$suggested-items'>

          <xsl:variable name='obj'  select='.'/>
          <xsl:variable name='first' select='position() = 1'/>
          <xsl:variable name='last' select='position() = last()
                        or position() = $portion-size'/>

          <xsl:variable name='ignore' select='position() &gt; $portion-size'/>
          <xsl:variable name='status' select='parent::list/parent::list-item/status'/>

          <xsl:if test='not( $ignore )'>

            <xsl:variable name='ID'>
              <xsl:text>sug</xsl:text>
              <xsl:value-of select='position()'/>
            </xsl:variable>

            <xsl:variable name='sid' select='sid/text()'/>

            <xsl:variable name='prevID'>
              <xsl:text>sug</xsl:text>
              <xsl:value-of select='position()-1'/>
            </xsl:variable>


            <xsl:variable name='role'>
              <xsl:choose>
                <xsl:when test='role/text()'>
                  <xsl:value-of select='role/text()'/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select='parent::*/role'/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <xsl:variable name='object-type' select='type/text()'/>
            <xsl:variable name="config-this-type" 
                          select='$config-object-types/*[name()=$object-type]'/>
             
            <xsl:variable name='options'>
              <!-- option
                     @role  - role id
                     text() - role label
                   option
              -->
              <xsl:if test='not($status)'>
                <option no-relation=''/>
              </xsl:if>

              <xsl:if test='string-length($role)'>
                <option role='{$role}'><xsl:value-of select='$role'/></option>
              </xsl:if>

              <xsl:for-each select="$config-this-type/roles/list-item[text()!=$role]">
                <option role='{text()}'>
                  <xsl:value-of select='text()'/>
                </option>
              </xsl:for-each>
              <xsl:if test='$status'>
                <option no-relation=''/>
              </xsl:if>
              
            </xsl:variable>

            <xsl:variable name='items-ahead' 
                          select='last() - position()'/>



            <xsl:text>

            </xsl:text>
          
            <div id='{$ID}' class='page'>
              <xsl:if test='not($first)'>
                <xsl:attribute name='style'> display: none; </xsl:attribute>
              </xsl:if>

              <xsl:if test='$first'>
<script-onload>
 CurrentPage="<xsl:value-of select='$ID'/>";
</script-onload>
              </xsl:if>

            <xsl:text>
            </xsl:text>

            
            <p class='explanation'
               ><xsl:call-template name='suggestions-sublist-explanation'>
            <xsl:with-param name='list' select='ancestor::list-item'/>
            </xsl:call-template></p>

            <xsl:text>
            </xsl:text>
            

            <p class='poster alternate'>
                  <big>
                    <xsl:call-template name='present-resource'>
                      <xsl:with-param name='resource' select='.'/>
                    </xsl:call-template>
              </big>

            <xsl:text>
            </xsl:text>

                  <input type='hidden' name='add_{$sid}'  />
                  <input type='hidden' name='id_{$sid}' value='{id/text()}'/>
                  <input type='hidden' name='role_{$sid}' />
<!-- XXX ?? -->          <input type='hidden' name='refuse_{$sid}' />

            </p>

<script-onload>
// set initial empty parameter values.  Mozilla might misbehave otherwise.
set_parameter("SUG", "add_<xsl:value-of select='$sid'/>",    '');
set_parameter("SUG", "role_<xsl:value-of select='$sid'/>",   '');
set_parameter("SUG", "refuse_<xsl:value-of select='$sid'/>", '');
</script-onload>

            <xsl:text>
            </xsl:text>

              <!--
            <div style='float: left; width: auto; margin-right: 5em;'>
              -->

              <p><big>Is this your work?</big></p>
              
              <ol class='questionChoices'>
                
                <xsl:for-each select='exsl:node-set($options)/option'>
                  <li name='{$ID}li{position()}'>
                    
                    <xsl:choose>
                      <xsl:when test='@role'>

                        <xsl:variable name='key'>
                          <xsl:value-of select='substring(@role, 1, 1)'/>
                        </xsl:variable>

                        <xsl:variable name='roletail'>
                          <xsl:value-of select='substring(@role, 2)'/>
                        </xsl:variable>

                            <a href='javascript:role("{$sid}","{@role}")'
                               tabindex='1'
                               class='int' no-form-check='1'
                               _accesskey='{substring(@role, 1, 1)}'
                               >Yes, I am the <!--<b class='access'><xsl:value-of 
                               select='$key'/></b><xsl:value-of select='$roletail'/>-->
                               <xsl:value-of select='text()'/> of this 
                        <xsl:value-of select='$obj/type'/>.</a>
                          </xsl:when>
                          <xsl:otherwise>
                            <a href='javascript:not_my("{$sid}")'
                               class='int' no-form-check='1'
                               tabindex='1'
                               _accesskey='N'
                               ><!--<b class='access'>N</b>-->No, I have no
                            connection to it.</a>
                          </xsl:otherwise>
                        </xsl:choose>

                      </li>                          
                    </xsl:for-each>

                  </ol>

<!--
            <table>
              <tr>
                <td>
                  <div style='width: 10em;' 
                  ><xsl:text> </xsl:text></div>
                </td>
                <td>
                </td>
              </tr>
            </table>
-->

            <xsl:if test='not($first)'>
<!--
              <p class='spacer'/>
-->
              <p style='float: left; clear: both;'>
                <a href= 'javascript:go_to_page("{$prevID}");'
                   title='Previous item'
                   no-form-check=''
                class='int' >&#x2190; back</a>
              </p>
            </xsl:if>

            <p style='text-align: right;'>
              <a href= 'javascript:go_to_next_page();'
                 title='Next item'
                 no-form-check=''
              class='int' >next &#x2192;</a>
            </p>

<!--
            <div style='clear: both;'>
              <div style='float: left'>
              </div>
            </div>
-->
            <p class='details' style='clear: both; text-align: right;'>
              <xsl:text/>Item<xsl:if test='number($items-ahead) !=
              1'>s</xsl:if> ahead: <xsl:text/>
              <xsl:value-of select='$items-ahead'/>.
            </p>



            </div>

          </xsl:if>

        </xsl:for-each>


<script-onload>
  formChanged = false;
</script-onload>

        <div id='good_bye_page' style='display: none;'>

          <h2>Please wait while we save your decisions<xsl:text/>
          
          <xsl:if test='count($suggested-items) &gt; $portion-size'>
            <xsl:text> and load next portion of research items</xsl:text>
          </xsl:if>

          <xsl:text>.</xsl:text></h2>
        </div>

      </xsl:when>
      <xsl:otherwise>

        <h2>Thank you, that's all!</h2>
        
        <p>No more suggestions for your profile.</p>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  
  <xsl:variable name='to-go-options'>
    <op><a ref='@research/autosuggest' >all suggestions at once</a></op>
    <op><a ref='@research' >main research page</a></op>
    <root/>
  </xsl:variable>






  <!--   n o w   t h e   p a g e   t e m p l a t e    -->

  
  <xsl:template match='/data'>

    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>suggestions, one by one</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='the-contributions'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>



</xsl:stylesheet>

<!--
          <xsl:variable name='first-complex' 
                        select='not(preceding::list-item[ancestor::suggest and parent::list])'/>

          <xsl:variable name='last-complex'  
                        select='not(following::list-item
                        [ ancestor::suggest
                        and parent::list
                        and ancestor::contributions])'/>
-->          


