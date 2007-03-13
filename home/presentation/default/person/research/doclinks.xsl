<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='main.xsl' />
  
  <xsl:variable name='parents'>
    <par id='research/main'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>research/doclinks</xsl:variable>


  <!--    v a r i a b l e s    -->
  <xsl:variable name='current'       select='$contributions/accepted'/>
  <xsl:variable name='config-object-types' select='$contributions/config/types'/> 
  <xsl:variable name='doclinks'      select='//doclinks'/>
  <xsl:variable name='doclinks-conf' select='//doclinks-conf'/>

  <xsl:template name='link-label'>
    <xsl:param name='name' select='list-item[2]/text()'/>
    <xsl:text> </xsl:text>
    <xsl:value-of select='$doclinks-conf/*[name()=$name]/label/text()'/>
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template name='reverse-link-label'>
    <xsl:param name='name' select='list-item[2]/text()'/>
    <xsl:variable name='reverse'
                  select='$doclinks-conf/*[name()=$name]/reverse/text()'/>
    <xsl:choose>
      <xsl:when test='$reverse'>
        <xsl:call-template name='link-label'>
          <xsl:with-param name='name' select='$reverse'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name='link-label'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name='doc-by-sid'>
    <xsl:param name='dsid'/>
    <xsl:variable name='doc' select='$current/list-item[sid=$dsid]'/>
    <a href='{$doc/url-about}'><xsl:value-of select='$doc/title'/></a>    
  </xsl:template>


  <xsl:template name='present-link'>
    <xsl:param name='dsid'/>
    <li>
      <xsl:choose>
        <xsl:when test='list-item[1]/text()=$dsid'>
          <xsl:call-template name='link-label'/>
          <xsl:call-template name='doc-by-sid' ><xsl:with-param name='dsid'
          select='list-item[3]/text()'/></xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name='reverse-link-label'/>
          <xsl:call-template name='doc-by-sid' ><xsl:with-param name='dsid'
          select='list-item[1]/text()'/></xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text> </xsl:text>
      <a class='linkdelete'
         ref='@research/doclinks?src={list-item[1]/text()}&amp;rel={list-item[2]/text()}&amp;trg={list-item[3]/text()}&amp;del=1'>[X]</a>
    </li>
  </xsl:template>

  <xsl:template name='link-form-hidden'>
    <div style='display:none' id='link-form'>
      <form screen='@research/doclinks'>
        <div style='float:right'><a href='#' class='closeform' title='close this'>[X]</a></div>

        <div><b>add a link</b>

        <table>
          <tr><th>of type</th><th>to document</th></tr>
          <tr>
            <td valign='top'>
        <select name='rel' size='{count($doclinks-conf/*)}'>
          <xsl:for-each select='$doclinks-conf/*'>
            <option value='{name()}'><xsl:value-of select='label'/></option>
          </xsl:for-each>
        </select> 
        <xsl:if test='count($accepted/*)&gt;count($doclinks-conf/*)*2'>
          <br/>
          <input type='submit' name='add' value=' create link '/>
        </xsl:if>
        </td>
        <td valign='top'>
          <xsl:for-each select='$accepted/*'>
            <input type='radio' name='trg' id='trg{sid}' value='{sid}' />
            <label for='trg{sid}'><xsl:text> </xsl:text><xsl:value-of
            select='title'/></label> <xsl:if test='url-about'> (<a href='{url-about}'>details</a>)</xsl:if><br/>
          </xsl:for-each>
<!--
        <select name='trg'>
          <xsl:for-each select='$accepted/*'>
            <option value='{sid}'><xsl:value-of select='title'/></option>
          </xsl:for-each>
        </select>
-->
        </td></tr></table>
        
        <input type='hidden' name='src' value=''/>
        <input type='submit' name='add' value=' create link '/>
        or <a href='#' class='closeform'>cancel</a>
        </div>
      </form>
    </div>
  </xsl:template>


  <xsl:template name='table-resources-for-links'>
    <xsl:param name='list'/>

    <tr class='here'>
      <th class='desc'> item description </th>
    </tr>
    
    <xsl:for-each select='$list/list-item[id and title]' xml:space='preserve'>
      <xsl:variable name="sid"  select='generate-id(.)'/>
      <xsl:variable name="dsid" select='sid'/>
      <xsl:variable name="id"   select='id'/>
      <xsl:variable name='role' select='role/text()'/>

      <xsl:variable name='alternate'><xsl:if test='position() mod 2'> alternate</xsl:if></xsl:variable>
      <tr class='resource{$alternate}' id='row_{$sid}'>
        
        <td class='description'>

          <xsl:call-template name='present-resource' xml:space='default'>
            <xsl:with-param name='resource' select='.'/>
            <xsl:with-param name='for' select='concat( "remove_", $sid )' />
          </xsl:call-template>
          
          <xsl:variable name='cidentified' select='$citations/identified'/>
          <xsl:variable name='cpotential'  select='$citations/potential'/>

          <xsl:if test='$citations//*[name()=$dsid]'>
            <br/><small>citations: 
            <xsl:if test='$citations/identified/*[name()=$dsid]'>
              <a ref='@citations/identified/{$dsid}' ><xsl:value-of
              select='$citations/identified/*[name()=$dsid]/text()' />
              identified</a >
            </xsl:if>

            <xsl:if test='count($citations/*/*[name()=$dsid])&gt;1'>|</xsl:if> 
            
            <xsl:if test='$citations/potential/*[name()=$dsid]'>
              <a ref='@citations/potential/{$dsid}'><xsl:value-of
              select='$citations/potential/*[name()=$dsid]/text()'/>
              potential</a>
            </xsl:if>

            </small>
          </xsl:if>

          <br/>
          <small>
            <ul class='links' sid='{$dsid}'>
              <xsl:for-each select='$doclinks//*[name()=$dsid]/list-item'>
                <xsl:call-template name='present-link'>
                  <xsl:with-param name='dsid' select='$dsid'/>
                </xsl:call-template>
              </xsl:for-each>
              <li sid='{$dsid}'><a ref='#0' class='linkadd' >add a link</a></li>
            </ul>
          </small>
            
    </td>
    </tr>

    </xsl:for-each>
  </xsl:template>



  <xsl:variable name='additional-head-stuff'>
        <script type="text/javascript" src='{$base-url}/script/jquery.js'></script>
  </xsl:variable>

  <xsl:template name='research-identified'>

    <style>
ul.links {
 margin-top: 0; 
 margin-bottom: 0; 
}

ul.links a.linkdelete {
  color: #999;
  text-decoration: none;
}

ul.links a.linkadd {
  text-decoration: none;
}
#link-form { padding: 0px; border: 1px solid #666; }
#link-form th { text-align: left; font-weight: normal; }
#link-form form { 
  padding: 6px; 
  margin:0; 
}
    </style>

<script-onload>
$("a.linkadd").click( add_link_form );
$("a.closeform").click( close_add_link_form );
</script-onload>
<script>
var record_sid = "<xsl:value-of select='$record-sid'/>";
var session_id = "<xsl:value-of select='$session-id'/>";
var form_open;
function add_link_form () {
  if( form_open ) { close_add_link_form() }
  var dsid=this.parentNode.getAttribute('sid');
  var f=get('link-form');
  this.parentNode.insertBefore( f, null );
  $( f ).show('slow');
  form_open = true;
  //f.style.display = "";
  $("input[@name='src']", f).get(0).setAttribute('value', dsid);
  $("#trg"+dsid, f).get(0).setAttribute('disabled', 'y'); 
  f.setAttribute('dsid', dsid);
  this.style.display = 'none';
  return false;
}
function close_add_link_form () {
  var f=get('link-form');
  var dsid=f.getAttribute('dsid', dsid);
  if(dsid) {
     $("#trg"+dsid, f).get(0).removeAttribute('disabled'); 
  }
  f.style.display = "none";
  $("a.linkadd").show();
  return false;
}
</script>

    <xsl:call-template name='link-form-hidden'/>

    <h1>Document to document links</h1>

    <xsl:call-template name='show-status'/>

    <xsl:variable name='current-count' 
                  select='count( $current/list-item )'/>

    <xsl:choose>
      <xsl:when test='$current/list-item'>
          <xsl:choose>
          <xsl:when test='$current-count &gt; 1'>
            <p>Here are the <xsl:value-of select='$current-count'/>
            works, that you claim you have authored:</p>
          </xsl:when>
          <xsl:when test='count( $current/list-item ) = 1'>
            <p>Here is the work, that you claim you have authored:</p>
          </xsl:when>
          </xsl:choose>

          <p><small>This page requires JavaScript in your browser to work.</small></p>
          
          <table class='resources'>
            <xsl:call-template name='table-resources-for-links'>
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
      <xsl:with-param name='title'>your works</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='research-identified'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

    

</xsl:stylesheet>