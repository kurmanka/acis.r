<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:exsl="http://exslt.org/common"
                version="1.0">

  <xsl:import href='main.xsl' />
  
  <xsl:variable name='parents'>
    <par id='research/main'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>research/fturls</xsl:variable>


  <!--    v a r i a b l e s    -->
  <xsl:variable name='current'     select='$contributions/accepted'/>
  <xsl:variable name='config-object-types' select='$contributions/config/types'/> 
  <xsl:variable name='fturls'      select='//fturls'/>

  <xsl:variable name='doclinks' select='//doclinks'/>
  <xsl:variable name='doclinks-conf' select='//doclinks-conf'/>


  <xsl:variable name='recognition-menu-items'>
    <item code='n'>wrong</item>
    <item code='d'>abstract page</item>
    <item code='r' allow-second='y'>full-text file of another version</item>
    <item code='y' default='y' allow-second='y'>correct full-text file</item>
  </xsl:variable>
  <xsl:variable name='recognition-menu' select='exsl:node-set($recognition-menu-items)'/>

  <xsl:variable name='archival-menu-items'>
    <item code='y' default='y'>may be archived</item>
    <item code='c'>archive, but check for updates</item>
    <item code='n'>may not be archived</item>
  </xsl:variable>
  <xsl:variable name='archival-menu' select='exsl:node-set($archival-menu-items)'/>

  <xsl:template name='present-menu-choice'>
    <xsl:param name='code'/>
    <xsl:param name='menu'/>
    <xsl:if test='$menu/item[@code=$code]'>
      <xsl:value-of select='$menu/item[@code=$code]/text()'/>
    </xsl:if>
  </xsl:template>

  <xsl:template name='render-menu'>
    <xsl:param name='current'/>
    <xsl:param name='menu'/>
    <xsl:for-each select='$menu/item'>
        <li code='{@code}'>
          <xsl:if test='$current=@code'>
            <xsl:attribute name='class'>current</xsl:attribute>
          </xsl:if>
          <xsl:if test='@default'>
            <xsl:attribute name='class'>default</xsl:attribute>
          </xsl:if>
          <a href='#' class='evergreen'><xsl:value-of select='text()'/></a>
        </li>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name='render-menu-js'>
    <xsl:param name='name'/>
    <xsl:param name='menu'/>
<xsl:text/>var <xsl:value-of select='$name'/> = { <xsl:text/>
    <xsl:for-each select='$menu/item'>
'<xsl:value-of select='@code'/>': { label: "<xsl:value-of select='text()'/>"<xsl:text/>
    <xsl:choose><xsl:when
    test='@default'>, default: true</xsl:when><xsl:otherwise></xsl:otherwise></xsl:choose>
    <xsl:if test='@allow-second'>, second: true</xsl:if> 
    <xsl:text/> }<xsl:if test='position()&lt;last()'>,</xsl:if>
    </xsl:for-each>
<xsl:text> };
</xsl:text>
  </xsl:template>

  <xsl:template name='recognition-menu'>
    <p>this url for the above document is:</p>
    <ul id='recognition-menu' class='menu' menu='0'>
      <xsl:call-template name='render-menu'>
        <xsl:with-param name='menu' select='$recognition-menu'/>
      </xsl:call-template>
    </ul>
  </xsl:template>

  <xsl:template name='archival-menu'>
    <xsl:param name='current' select='"y"'/>
    <ul id='archival-menu' class='menu' menu='1'>
      <xsl:call-template name='render-menu'>
        <xsl:with-param name='menu' select='$archival-menu'/>
      </xsl:call-template>
    </ul>
  </xsl:template>


  <xsl:template name='doc-by-sid'>
    <xsl:param name='dsid'/>
    <xsl:variable name='doc' select='$current/list-item[sid=$dsid]'/>
    <a href='{$doc/url-about}'><xsl:value-of select='$doc/title'/></a>    
  </xsl:template>


  <xsl:template name='present-url'>
    <xsl:choose>
      <xsl:when test='string-length(url) &gt; 55'> 
        <!-- cut out the middle and replace it with an ellipsis. -->
        <xsl:value-of select='substring(url,1,30)'/>
        <xsl:text>...</xsl:text>
        <xsl:value-of select='substring(url,string-length(url)-20)'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='url'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name='present-choice'>
    <xsl:param name='choice' select='"yy"'/>
    <xsl:variable name='choice-str'>
      <xsl:choose>
        <xsl:when test='string-length($choice)'><xsl:value-of select='$choice'/></xsl:when>
        <xsl:otherwise><xsl:text>yy</xsl:text></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test='string-length($choice-str)'>
        <xsl:call-template name='present-menu-choice'>
          <xsl:with-param name='code' select='substring($choice-str,1,1)'/>
          <xsl:with-param name='menu' select='$recognition-menu'/>
        </xsl:call-template>
        <xsl:if test='string-length($choice-str) &gt; 1'>
          <xsl:text>, </xsl:text>
          <xsl:call-template name='present-menu-choice'>
            <xsl:with-param name='code' select='substring($choice-str,2,1)'/>
            <xsl:with-param name='menu' select='$archival-menu'/>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>


  <xsl:template name='scripts'>

<script>

<xsl:call-template name='render-menu-js'>
  <xsl:with-param name='name' select='"recognition_menu"'/>
  <xsl:with-param name='menu' select='$recognition-menu'/>
</xsl:call-template>
<xsl:call-template name='render-menu-js'>
  <xsl:with-param name='name' select='"archival_menu"'/>
  <xsl:with-param name='menu' select='$archival-menu'/>
</xsl:call-template>

var menus = new Array(recognition_menu,archival_menu);
var psid = "<xsl:value-of select='$record-sid'/>";
var session_id = "<xsl:value-of select='$session-id'/>";
var form;
var form_open;
var dsid;
var href;
var item;

function change_choice_click () {
  if( form_open ) { close_choice_form() }
  dsid=this.getAttribute('dsid');
  item=$(this).parents('li')[0];
  href=$(item).find('a.ft').attr('href');
  form=get('choice-form');
  if (!item) {alert('no item');}
  $(item).append( form );
  $(form).slideDown('normal');
  form_open = true;
  this.style.display = 'none';
  return false;
}

function close_choice_form () {
  dsid=null;
  form.style.display = "none";
  form.setAttribute('choice','');
  hide_menu2();
  $("a.changechoice").show();
  return false;
}

function show_menu2(el) {
  //$('#menu1').hide();
  //$('#menu2').show();
  if (el) {
    $(el).after( get('menu2') );
  } else {
    $('#menu1').after( get('menu2') );
  }
  $('#menu2').slideDown('normal');
}

function hide_menu2() {
  hide('menu2');
  $('#choice-menu').append( get('menu2') );
}

function choice() {
  // which particular choice is that? in which menu?
  // for which document? 
  var code = this.parentNode.getAttribute('code');
  var el = this.parentNode;
  while( el &amp;&amp; el.nodeName != 'UL' ) { el = el.parentNode; }
  var menu = el.getAttribute('menu'); // should be either 0 or 1
  if (menu!=0 &amp;&amp; menu!=1) { alert( "can't get menu number" ); }
  var prevchoice = String(form.getAttribute('choice'));
  var newchoice = '';
  if (prevchoice.length==0) {
    if (menu==0) { newchoice=code; }
    else { alert( "can't set second code, when the first one is not set" ); }
  } else {
    newchoice= prevchoice.substring(0,menu) + code;
  }
  form.setAttribute('choice', newchoice );
  if (menu==0 &amp;&amp; menus[0][code].second) { 
     show_menu2(this); 
     return false; 
  }
  send_choice( dsid, psid, href, newchoice );
  return false;
}

function send_choice( dsid, psid, href, choice ) {
  var url = "fturls/xmlpost!" + session_id;
  $.post( url, 
    { 'dsid': dsid, 'href': href, 'choice': choice }, 
    function(data) { update_page( dsid, href, choice ); }
  );
}

function update_page(dsid, href, choice) {
  //close_choice_form();
  $(item).find('span.choice').empty().removeClass('default').addClass('new').append( make_choice_text(choice) );
  //$('a.changechoice[@dsid='+dsid+']').parent().find('a[@href="'+href+'"]');
  close_choice_form();
}

function make_choice_text(choice) {
  var text = menus[0][choice.substr(0,1)].label;
  if (choice.length &gt; 1) {
    text = text + ', ' + menus[1][choice.substr(1,1)].label
  }
  return text;
}

</script>

  </xsl:template>




  <xsl:template name='table-resources-for-ftlinks'>
    <xsl:param name='list'/>

    <tr class='here'>
      <th class='desc'> item description </th>
    </tr>
    
    <xsl:for-each select='$list/list-item[id and title]'>
      <xsl:sort
          select='count($fturls/list-item/*[name()=current()/sid]//choice[not(text())])' 
          order='descending'/>
      <xsl:variable name="sid"  select='generate-id(.)'/>
      <xsl:variable name="dsid" select='sid'/>
      <xsl:variable name="id"   select='id'/>
      <xsl:variable name='role' select='role/text()'/>

      <xsl:if test='$fturls/list-item/*[name()=$dsid]'>

      <xsl:variable name='alternate'><xsl:if test='position() mod 2'> alternate</xsl:if></xsl:variable>
      <tr class='resource{$alternate}' id='row_{$sid}'>
        
        <td class='description'>
          <xsl:call-template name='present-resource' xml:space='default'>
            <xsl:with-param name='resource' select='.'/>
          </xsl:call-template>
          <br/><ul>
          <xsl:for-each select='$fturls/list-item/*[name()=$dsid]/list-item'>
            <li><a href='{url}' class='ft'><xsl:call-template name='present-url'/></a>
            <br/>
            <xsl:text>is: </xsl:text> 
            <span class='choice' xml:space='default'>
              <xsl:if test='not(string-length(choice))'>
                <xsl:attribute name='class'>choice default</xsl:attribute>
              </xsl:if>                
              <xsl:call-template name='present-choice' xml:space='default'>
                <xsl:with-param name='choice' select='choice/text()'/>
              </xsl:call-template>
            </span>
            <span class='change'> - 
            <a href='#' class='evergreen changechoice' choice='{choice/text()}'
               dsid='{$dsid}' >change</a></span>
            </li>
          </xsl:for-each>
          </ul>

    </td>
    </tr>
      </xsl:if>

    </xsl:for-each>
  </xsl:template>


  <xsl:template name='hidden-choice-form'>
    <div style='display: none' id='choice-form'>
      <form>
        <div style='float:right'><a ref='#' class='evergreen closeform'>[X]</a></div>
        <div id='menu1'><xsl:call-template name='recognition-menu'/></div>
      </form>
    <div id='menu2' style='display:none;'><xsl:call-template
    name='archival-menu'/></div>
    </div>

  </xsl:template>

  <xsl:variable name='additional-head-stuff'>
    <script type="text/javascript" src='{$base-url}/script/jquery.js'></script>
  </xsl:variable>

  <xsl:template name='research-fturls'>

    <style>
a.closeform {
  font-family: monospace;
  font-weight: bold;
  font-size: larger;
  text-decoration: none;
}
#choice-form form div ul.menu { margin: 12px; margin-left: 30px; xpadding: 2px; }
span.new {color: green;font-style:italic}
span.default {color: gray}
#menu1, #menu2 { padding: 6px; }
#choice-form { padding: 0px; border: 1px solid #666; }
#choice-form form { 
  font-size: smaller;
  padding: 6px; 
  margin:0; 
}

    </style>

<script-onload>
$("a.changechoice").click( change_choice_click );
$("a.closeform").click( close_choice_form );
$("ul.menu a").click( choice );
</script-onload>

<xsl:call-template name='scripts'/>
<xsl:call-template name='hidden-choice-form'/>

    <h1>Documents' full-text links</h1>

    <xsl:call-template name='show-status'/>

    <xsl:variable name='current-count' 
                  select='count($fturls/list-item/*)'/>

    <xsl:choose>
      <xsl:when test='$current/list-item'>
          <xsl:choose>
          <xsl:when test='$current-count &gt; 1'>
            <p>Here are your works, for which we have full text links.</p>
          </xsl:when>
          </xsl:choose>

          <p><small>This page requires JavaScript in your browser to work.</small></p>
          
          <table class='resources'>
            <xsl:call-template name='table-resources-for-ftlinks'>
              <xsl:with-param name='list' select='$current'/>
            </xsl:call-template>
          </table>

      </xsl:when>
      <xsl:otherwise>
        <p>At this moment, there are no works in your research profile; and
        there are no links either.</p>
      </xsl:otherwise>
    </xsl:choose>
    


  </xsl:template>




  <!--   n o w   t h e   p a g e   t e m p l a t e    -->

  
  <xsl:template match='/data'>

    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>full-text links</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='research-fturls'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

    

</xsl:stylesheet>