<!DOCTYPE xsl:stylesheet [

<!ENTITY nbsp   "&#160;"> <!-- no-break space = non-breaking space,
                               U+00A0 ISOnum -->

]>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl xml x'
  xmlns:x='http://x'
  version="1.0">  <!--  /page.xsl that is. (the global one.) defines "page" template -->
 

  <xsl:import href='global.xsl'/>
  <!-- global variables are there... -->

  <xsl:import href='forms.xsl'/>

  <xsl:output
    method="html"
    doctype-public="-//W3C//DTD HTML 4.01//EN"
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"
    omit-xml-declaration='yes'
    encoding='utf-8'/>


  <!-- new page templates (Sep 9, 2003) -->

  <!-- default: -->

  <xsl:template name='logged-notice'>
    <xsl:choose>
      <xsl:when test='$session-type = "user"'>
        <xsl:call-template name='user-logged-notice'/>
      </xsl:when>
      <xsl:when test='$session-type = "new-user"'>
        <xsl:call-template name='new-user-logged-notice'/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name='profile-menu'>
    <xsl:choose>
      <xsl:when test='$session-type = "user"'>
        <xsl:call-template name='user-profile-menu'/>
      </xsl:when>
      <xsl:when test='$session-type = "new-user"'>
        <xsl:call-template name='new-user-profile-menu'/>
      </xsl:when>
      <xsl:otherwise>
        <p class='menu'></p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:variable name='page-class'/>
  <xsl:variable name='page-id'/>

  <xsl:variable name='full-page-title'/>
  <xsl:variable name='page-title'/>
  <xsl:variable name='additional-head-stuff'/>


  <!-- GLOBAL ACIS PAGE TEMPLATE -->


  <xsl:template name='page'>
   <xsl:param name='content'/>
   <xsl:param name='title'/>

   <xsl:param name='body-title'/>

   <xsl:param name='into-the-top'/>
   <xsl:param name='navigation'/>

   <xsl:param name='show-errors'/>
   <xsl:param name='headers'   />

<html xml:space='preserve'>
 <head>

  <title><xsl:choose
><xsl:when test='string-length($full-page-title)'
><xsl:value-of select='$full-page-title'/></xsl:when
><xsl:when test='string-length($page-title)'
><xsl:value-of select='$site-name'/>: <xsl:value-of select='$page-title'
/></xsl:when><xsl:otherwise
><xsl:value-of select='$site-name'/>: <xsl:value-of select='$title'
/></xsl:otherwise></xsl:choose></title>


<xsl:text>
</xsl:text>

  <xsl:choose><xsl:when 
  test='$css-url'><link rel="stylesheet" href="{$css-url}" type="text/css"/></xsl:when
  ><xsl:otherwise>
<link rel="stylesheet" href="{$static-base-url}/style/main.css"
      type="text/css" title='default'/>
<xsl:text>
</xsl:text>
<link rel="alternate stylesheet"
      href="{$static-base-url}/style/brownish.css" 
      type="text/css" title='brownish'/>
</xsl:otherwise></xsl:choose>


<xsl:choose xml:space='default'>
  <xsl:when test='contains( $user-agent, "MSIE 6.0;")
            or contains( $user-agent, "MSIE 5.5;")'>
<xsl:text>
</xsl:text>
<link rel="stylesheet" href="{$static-base-url}/style/ie-font-sizes.css"
      type="text/css"/>
  </xsl:when>
</xsl:choose>



<xsl:copy-of select='$headers'/>
<xsl:copy-of select='$additional-head-stuff'/>

<meta http-equiv="Content-Script-Type" content="text/javascript"/>
<script type="text/javascript" src='{$static-base-url}/script/main.js'/>

<script type="text/javascript">
<xsl:for-each select='exsl:node-set( $content )//script[not(@insitu)]'>
<xsl:copy-of select='text()'/>
</xsl:for-each>

<xsl:apply-templates select='exsl:node-set( $content )//form' mode='scripting'/>

function onLoad() {
  onload_show_switcher();
<xsl:copy-of select='exsl:node-set( $content )//script-onload/text()'/>
}
</script>

<style type="text/css">
<xsl:copy-of select='exsl:node-set( $content )//style/text()'/>
</style>

 </head>

 <body class='{$page-class} {$current-screen-id}'
       onload='onLoad();'
       ><xsl:if test='string-length( $page-id )'
       ><xsl:attribute name='id'><xsl:value-of select='$page-id'/></xsl:attribute></xsl:if
       ><xsl:choose
><xsl:when test='$page-class'
><xsl:attribute name='class'><xsl:value-of select='$page-class'/></xsl:attribute></xsl:when
><xsl:when test='$current-screen-id'
><xsl:attribute name='class'><xsl:value-of select='$current-screen-id'/>Screen</xsl:attribute
></xsl:when></xsl:choose>

   <xsl:comment> service.announcement go here </xsl:comment>

   <div class='header' id='top'>

     <p class='site-title'>
       <big><big>
       <span class='site-title'>
         <a class='site-title' href='{$home-url}'><xsl:value-of select='$site-name-long'/></a>
       </span>
       </big></big>
     </p>

     <xsl:copy-of select='$into-the-top'/>
     
   </div>

   <xsl:if test='exsl:node-set($navigation)/*'>

     <div class='subHeader' xml:space='default'>
       <xsl:copy-of select='$navigation'/>
       <xsl:call-template name='additional-page-navigation'/>
     </div>

   </xsl:if>

   <div class='content'>

   <xsl:if test='$body-title' xml:space='default'>
     <h1><xsl:value-of select='$body-title'/></h1>
   </xsl:if>

   <xsl:if test='$show-errors' xml:space='default'>
       <xsl:call-template name='show-errors'/>
   </xsl:if>

     <xsl:apply-templates select='exsl:node-set( $content )' mode='link-filter'/>

     <xsl:call-template name='link-filter' xml:space='default'>
       <xsl:with-param name='content'>
         <xsl:call-template name='content-bottom-navigation'/>
       </xsl:with-param>
     </xsl:call-template>

   </div>

   <xsl:call-template name='link-filter' xml:space='default'>
     <xsl:with-param name='content' xml:space='preserve'>

       <div class='footer'>
         
         <phrase ref='page-footer'>

           <p class='menu'>
             <small>

       <a href='mailto:{$admin-email}' 
          class='int email'
          no-form-check=''
               >ADMINISTRATOR EMAIL</a>
       | <a href='{$home-url}' class='int' >HOME</a>

<span style='float: right; padding-top: 1em;'>
  <span style='display: none;'>| </span> 
  <a href='#top' 
     class='int' 
     no-form-check='' >PAGE&#160;TOP&#160;<!--&#x2191;-->^</a>
</span>
               
             </small>
           </p>
           
         </phrase>

         <p title='Page colors' id='styleSwitch' style='display: none;'
            ><small
            >Theme: <a class='int' 
            title='black on white'
            href="javascript:setActiveStyleSheet('default');"
            >default</a> | <a class='int' title=''
            href="javascript:setActiveStyleSheet('brownish');"
         >brownish</a></small></p>
         
       </div>


       <phrase ref='after-footer'/>

     </xsl:with-param>
   </xsl:call-template>

 </body>
</html>
 </xsl:template>



  <xsl:template name='additional-page-navigation'/>

  <xsl:template name='content-bottom-navigation'/>



 <xsl:variable name='current-screen-id' select='""'/>
 <xsl:variable name='current-screen-id-real'>
   <xsl:value-of select='$current-screen-id'/>
 </xsl:variable>
 

  <xsl:template match='*'      mode='scripting'/>
  <xsl:template match='text()' mode='scripting'/>


  <xsl:template name='link-filter'>
    <xsl:param name='content'/>
    <xsl:apply-templates select='exsl:node-set( $content )' mode='link-filter'/>
  </xsl:template>


  <xsl:template match='@*|*' mode='link-filter'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:apply-templates mode='link-filter'/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match='comment' mode='link-filter'>
    <xsl:comment>
      <xsl:apply-templates mode='link-filter'/>
    </xsl:comment>
  </xsl:template>


  <xsl:template match='hint' mode='link-filter'>
    <xsl:apply-templates mode='link-filter'/>
  </xsl:template>


  <xsl:template match='input|select|textarea' mode='link-filter'>

    <xsl:variable name='class'>
      <xsl:if test='name() = "input"'>
        <xsl:text>input</xsl:text>
        <xsl:value-of select='@type'/>
      </xsl:if>
      <xsl:if test='@class'>
        <xsl:if test='name() = "input"'>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select='@class'/>
      </xsl:if>
    </xsl:variable>      

    <xsl:copy>
      <xsl:copy-of select='@*'/>

      <xsl:attribute name='class'>
        <xsl:value-of select='$class'/>
      </xsl:attribute>

      <xsl:if test='not(@type="hidden")'>

        <xsl:attribute name='onfocus'>
          <xsl:if test='@onfocus'>
            <xsl:value-of select='@onfocus'/>;<xsl:text/>
          </xsl:if>
          <xsl:text>this.className="</xsl:text>
          <xsl:value-of select='$class'/>
          <xsl:text> active";</xsl:text>
          <xsl:if test='hint'>show("<xsl:value-of
          select='@id'/>Hint");<xsl:text/></xsl:if>
          <xsl:if test='@onfocus_after'>
            <xsl:value-of select='@onfocus_after'/>;<xsl:text/>
          </xsl:if>
        </xsl:attribute>

        <xsl:attribute name='onblur'>
          <xsl:if test='@onblur'>
            <xsl:value-of select='@onblur'/>;<xsl:text/>
          </xsl:if>
          <xsl:text>this.className="</xsl:text>
          <xsl:value-of select='$class'/>";<xsl:text/>
          <xsl:if test='hint'>hide("<xsl:value-of select='@id'/>Hint");<xsl:text/></xsl:if>
          <xsl:if test='@onblur_after'>
            <xsl:value-of select='@onblur_after'/>;<xsl:text/>
          </xsl:if>
        </xsl:attribute>

      </xsl:if>

      <xsl:if test='contains( ancestor::form/@class, "important" )'>
        <xsl:attribute name='onchange'>
          <xsl:if test='@onchange'>
            <xsl:value-of select='@onchange'/>;<xsl:text/>
          </xsl:if>
          <xsl:text/>a_parameter_change( "<xsl:value-of
          select="ancestor::form/@name"
          />" );<xsl:text/>
        </xsl:attribute>
      </xsl:if>

      <xsl:if test='name() = "select"'>
        <xsl:apply-templates mode='link-filter'/>
      </xsl:if>

      <xsl:if test='name() = "textarea"'>
        <xsl:copy-of select='text()'/>
      </xsl:if>      

    </xsl:copy>

    <xsl:if test='hint'>
      <xsl:call-template name='input-hint'/>
    </xsl:if>

  </xsl:template>



  <xsl:template name='input-hint'>

      <span id='{@id}Hint' 
            style='display: none;'
            >
            <xsl:if test='not(hint/@side)'>
              <br /><xsl:text> </xsl:text>
            </xsl:if>
        <span class='WrapHint'
            >
        <xsl:choose>
          <xsl:when test='hint/@side'>
            <span class='SideHint'>
              <xsl:apply-templates select='hint' mode='link-filter'/>
            </span>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name='style'
>padding-left: 10px; padding-top: 0;</xsl:attribute>
            <span class='Hint'>
              <xsl:apply-templates select='hint' mode='link-filter'/>
            </span>
          </xsl:otherwise>
        </xsl:choose>
      </span>
      </span>
  </xsl:template>



  <xsl:template match='style'  mode='link-filter'/>
  <xsl:template match='script-onload' mode='link-filter'/>
  <xsl:template match='script' mode='link-filter'/>

  <xsl:template match='script[@insitu]' mode='link-filter'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:attribute name='type'>text/JavaScript</xsl:attribute>
      <xsl:choose>
        <xsl:when test='comment'>
          <xsl:apply-templates mode='link-filter'/>
        </xsl:when>
        <xsl:otherwise>

          <xsl:comment><xsl:text>
</xsl:text>
            <xsl:apply-templates mode='link-filter'/>
            <xsl:text>
//</xsl:text> 
          </xsl:comment>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  

  <xsl:template match='script-onload' mode='scripting'>
    <xsl:copy-of select='text()'/>
  </xsl:template>


  <xsl:template match='form[descendant::onsubmit or descendant::check]' mode='scripting'>

function form_check_<xsl:value-of select='@name'/> () {
  var element;
  var value;
            <xsl:for-each select='.//*[name() = "onsubmit" or name() = "check"]'>
              <xsl:if test='parent::input'>
                <xsl:for-each select='parent::input'>
  {
    element = getRef( "<xsl:value-of select='@id'/>" );
    value = element.value;
    <xsl:if test='check/@nonempty'>
      if ( value == '' ) { 
      <xsl:choose>
        <xsl:when test='name'>
          alert( "Please enter <xsl:value-of select='name/text()'/>." );
        </xsl:when>
        <xsl:otherwise>
          alert( "Please enter a value into the <xsl:value-of 
          select='@name'/> field." );
        </xsl:otherwise>
      </xsl:choose>
        element.focus();
        return( false );
      }
    </xsl:if>
                </xsl:for-each>
              </xsl:if>


    <xsl:if test='name() = "check" and @test'>
      if ( <xsl:value-of select='@test'/> ) { 
      <xsl:value-of select='do'/>
      }
    </xsl:if>

    <xsl:if test='name() = "onsubmit"'>
      <xsl:value-of select='text()'/>
    </xsl:if>
    <xsl:if test='parent::input'>
  }
    </xsl:if>
            </xsl:for-each>
  formChanged = false;
  return true;
}


  </xsl:template>


  <xsl:template match='form' mode='link-filter'>

<xsl:text>
</xsl:text>      


    <form xsl:use-attribute-sets='form'>
      <xsl:copy-of select='@*[name()!="screen"]'/>
      <xsl:attribute name='action'>
        <xsl:choose>

          <xsl:when test='@screen'>

            <xsl:variable name='ref' select='@screen'/>

            <xsl:variable name='fragment'>
              <xsl:choose>
                <xsl:when test='contains( $ref, "#" )'>
                  <xsl:value-of select='substring-after( $ref, "#" )'/>
                </xsl:when>
              </xsl:choose>
            </xsl:variable>
            

            <xsl:variable name='screen-to'>
              
              <xsl:variable name='screen-to-1'>
                <xsl:choose>
                  <xsl:when test='contains( $ref, "!" )'>
                    <xsl:value-of select='substring-before( $ref, "!" )'/>
                  </xsl:when>
                  <xsl:when test='contains( $ref, "?" )'>
                    <xsl:value-of select='substring-before( $ref, "?" )'/>
                  </xsl:when>
                  <xsl:when test='contains( $ref, "#" )'>
                    <xsl:value-of select='substring-before( $ref, "#" )'/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select='$ref'/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              
              <xsl:choose>
                <xsl:when test='contains( $ref, "@(" )'>
                  <xsl:value-of 
                   select='substring-after( $screen-to-1, ")" )'/>
                </xsl:when>
                <xsl:when test='contains( $ref, "@" )'>
                  <xsl:value-of 
                   select='substring-after( $screen-to-1, "@" )'/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select='$screen-to-1'/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            
            <xsl:variable name='to-session-id'>
              
              <xsl:variable name='destination-session-id'>
                <xsl:choose>
                  <xsl:when test='contains( $ref, "!" )'>
                    <xsl:variable name='tail' select='substring-after( $ref, "!" )'/>
                    <xsl:choose>
                      <xsl:when test='contains( $tail, "?" )'>
                        <xsl:value-of select='substring-before( $tail, "?" )'/>
                      </xsl:when>
                      <xsl:when test='contains( $tail, "#" )'>
                        <xsl:value-of select='substring-before( $tail, "#" )'/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select='$tail'/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                </xsl:choose>
              </xsl:variable>

              <xsl:choose>
                <xsl:when test='contains( $ref, "!" )'>
                  <xsl:value-of select='$destination-session-id'/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select='$session-id'/>
                </xsl:otherwise>
              </xsl:choose>

            </xsl:variable>              
              
            <xsl:variable name='to-object-id'>
              
              <xsl:variable name='destination'>
                <xsl:choose>
                  <xsl:when test='contains( $ref, "@(" )'>
                    <xsl:variable name='tail' select='substring-after( $ref, "@(" )'/>
                    <xsl:value-of select='substring-before( $tail, ")" )'/>
                  </xsl:when>
                  <xsl:when test='contains( $ref, "@" )'>
                    <!-- default object-id is $record-sid -->
                    <!--        <xsl:if test='starts-with( $record-sid, "p" )'>  -->
                    <xsl:if test='$advanced-user'>
                      <xsl:value-of select='$record-sid'/>
                    </xsl:if>
                  </xsl:when>
                </xsl:choose>
              </xsl:variable>
              
              <xsl:choose>
                <xsl:when test='string-length( $destination )'>
                  <xsl:value-of select='$destination'/>
                </xsl:when>
              </xsl:choose>
            </xsl:variable>
    


            <xsl:if test='string-length( $screen-to )'>
              <xsl:value-of select='$base-url'/>
              
              <xsl:if test='string-length( $to-object-id )'>
                <xsl:text>/</xsl:text>
                <xsl:value-of select='$to-object-id'/>
              </xsl:if>
              
              <xsl:if test='not( starts-with( $screen-to, "/" ) )'>
                <xsl:text>/</xsl:text>
              </xsl:if>
              <xsl:value-of select='$screen-to'/>
                
              <xsl:if test='string-length( $to-session-id )'>
                <xsl:text>!</xsl:text>
                <xsl:value-of select='$to-session-id'/>
              </xsl:if>
              
            </xsl:if>
              

            <xsl:if test='string-length( $fragment )'>
              <xsl:text>#</xsl:text>
              <xsl:value-of select='$fragment'/>
            </xsl:if>

          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='@action'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>

      <!-- onsubmit -->
      <xsl:choose>
        <xsl:when test='.//onsubmit or .//check'>
          <xsl:attribute name='onsubmit'>return form_check_<xsl:value-of
          select='@name'/> ();</xsl:attribute>
        </xsl:when>
<!--        <xsl:otherwise>
          <xsl:attribute name='onsubmit'>return form_submit();</xsl:attribute>
        </xsl:otherwise>
-->
      </xsl:choose>
      
<xsl:text>
</xsl:text>

      <xsl:apply-templates mode='link-filter'/>

<xsl:text>
</xsl:text>      
    </form>
<xsl:text>
</xsl:text>      
  </xsl:template>


  <xsl:template name='link-attributes'>

    <!-- Will add a call to check_form_changes() javascript, if there
         is an "important" form on the page. -->

    <xsl:if test='//form[ contains( @class, "important" ) ]'>
      <xsl:if test='not( @no-form-check )'>
        <xsl:attribute name='onclick'>
          <xsl:value-of select='@onclick'/>
          <xsl:text>return check_form_changes();</xsl:text>
        </xsl:attribute>
      </xsl:if>
    </xsl:if>

  </xsl:template>



  <xsl:template match='a[@href]' mode='link-filter'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
<!--
      <xsl:copy-of select='@href|@tabindex|@class|@title|@id|@name|@style|@onclick|@accesskey'/>
-->
      <xsl:call-template name='link-attributes'/>
      <xsl:apply-templates mode='link-filter'/>
    </xsl:copy>
  </xsl:template>




  <xsl:template match='a[@ref]' name='aref' mode='link-filter'>

    <!--

      a[ref] element usage:
      
  <a ref='name'>names screen</a>
  <a ref='@name'>names for current user & record</a>
  <a ref='name#variations'>variations on the names screen</a>
  <a ref='name?back=contributions#variations'>variations with
  return</a>
  <a ref='about!'>about, but out of current session</a>

    -->

    <xsl:variable name='ref' select='@ref'/>

    <xsl:variable name='fragment'>
      <xsl:choose>
        <xsl:when test='contains( $ref, "#" )'>
          <xsl:value-of select='substring-after( $ref, "#" )'/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>


    <xsl:variable name='screen-to'>
      
      <xsl:variable name='screen-to-1'>
        <xsl:choose>
          <xsl:when test='contains( $ref, "!" )'>
            <xsl:value-of select='substring-before( $ref, "!" )'/>
          </xsl:when>
          <xsl:when test='contains( $ref, "?" )'>
            <xsl:value-of select='substring-before( $ref, "?" )'/>
          </xsl:when>
          <xsl:when test='contains( $ref, "#" )'>
            <xsl:value-of select='substring-before( $ref, "#" )'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='$ref'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test='contains( $ref, "@(" )'>
          <xsl:value-of 
              select='substring-after( $screen-to-1, ")" )'/>
        </xsl:when>
        <xsl:when test='contains( $ref, "@" ) and substring-before( $ref, "@" )=""'>
          <xsl:value-of 
              select='substring-after( $screen-to-1, "@" )'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='$screen-to-1'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
        

    <xsl:variable name='to-session-id'>

      <xsl:variable name='destination-session-id'>
        <xsl:choose>
          <xsl:when test='contains( $ref, "!" )'>
            <xsl:variable name='tail' select='substring-after( $ref, "!" )'/>
            <xsl:choose>
              <xsl:when test='contains( $tail, "?" )'>
                <xsl:value-of select='substring-before( $tail, "?" )'/>
              </xsl:when>
              <xsl:when test='contains( $tail, "#" )'>
                <xsl:value-of select='substring-before( $tail, "#" )'/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select='$tail'/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      
      <xsl:choose>
        <xsl:when test='contains( $ref, "!" )'>
          <xsl:value-of select='$destination-session-id'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='$session-id'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name='query'>
      <xsl:variable name='draft'>
        <xsl:if test='contains( $ref, "?" )'>
          <xsl:value-of select='substring-after( $ref, "?" )'/>
        </xsl:if>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test='contains( $draft, "#" )'>
          <xsl:value-of select='substring-before( $draft, "#" )'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='$draft'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    

    <xsl:variable name='to-object-id'>

      <xsl:variable name='destination'>
        <xsl:choose>
          <xsl:when test='contains( $ref, "@(" )'>
            <xsl:variable name='tail' select='substring-after( $ref, "@(" )'/>
            <xsl:value-of select='substring-before( $tail, ")" )'/>
          </xsl:when>
          <xsl:when test='contains( $ref, "@" )'>
            <!-- default object-id is $record-sid -->
            <xsl:if test='$advanced-user'>
              <xsl:value-of select='$record-sid'/>
            </xsl:if>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      
      <xsl:choose>
        <xsl:when test='string-length( $destination )'>
          <xsl:value-of select='$destination'/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <a>
      <xsl:copy-of select='@title|@tabindex|@onclick'/>

      <xsl:attribute name='class'>
        <xsl:text>int</xsl:text>
        <xsl:if test='@class'>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@class"/>
        </xsl:if>
      </xsl:attribute>

      <xsl:attribute name='href'>

        <xsl:if test='string-length( $screen-to )'>
          <xsl:value-of select='$base-url'/>
          
          <xsl:if test='string-length( $to-object-id )'>
            <xsl:text>/</xsl:text>
            <xsl:value-of select='$to-object-id'/>
          </xsl:if>

          <xsl:if test='not( starts-with( $screen-to, "/" ) )'>
            <xsl:text>/</xsl:text>
          </xsl:if>
          <xsl:value-of select='$screen-to'/>

          <xsl:if test='string-length( $to-session-id )'>
            <xsl:text>!</xsl:text>
            <xsl:value-of select='$to-session-id'/>
          </xsl:if>

        </xsl:if>

        <xsl:if test='string-length( $query )'>
          <xsl:text>?</xsl:text>
          <xsl:value-of select='$query'/>
        </xsl:if>

        <xsl:if test='string-length( $fragment )'>
          <xsl:text>#</xsl:text>
          <xsl:value-of select='$fragment'/>
        </xsl:if>

      </xsl:attribute>
      <xsl:call-template name='link-attributes'/>
      <xsl:apply-templates mode='link-filter'/>
    </a>


  </xsl:template>




  <xsl:template match='*' mode='content-filter'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:apply-templates mode='content-filter'/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match='a' mode='content-filter'>
    <xsl:apply-templates mode='content-filter'/>
  </xsl:template>



  <xsl:template match='a[@screen]'
                mode='link-filter'>

    <xsl:variable name='screen' select='@screen'/>

    <xsl:choose>

      <xsl:when test='$parents-set/*[@id=$screen]'>
        <span class='here' title='You are in this section now'>
          <xsl:text>&#160;</xsl:text>
          <xsl:call-template name='aref'/>
          <xsl:text>&#160;</xsl:text>
        </span>
      </xsl:when>

      <xsl:when test='$current-screen-id and ($current-screen-id = @screen)'>
        <span class='here' title='You are here'>
          <xsl:text>&#160;</xsl:text>
          <xsl:apply-templates mode='link-filter'/>
          <xsl:text>&#160;</xsl:text>
        </span>
      </xsl:when>

      <xsl:otherwise>
        <xsl:call-template name='aref'/>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>


  <xsl:template match='a[@email]' mode='link-filter'>
    <xsl:variable name='address' select='@email'/>
    <xsl:variable name='user'    select='substring-before( $address, "@" )'/>
    <xsl:variable name='host'    select='substring-after(  $address, "@" )'/>
    
    <script><xsl:comment>
 Obfuscate( '<xsl:value-of select='$host'/>', 
            '<xsl:value-of select='$user'/>',
            '<xsl:for-each select='@*'>
<xsl:if test='name() != "href" and name() != "class" and name() != "email"'>
  <xsl:value-of select='name()'/>="<xsl:value-of select='.'/>" <xsl:text/>
</xsl:if>
</xsl:for-each>
<xsl:text>class="email </xsl:text><xsl:value-of select='@class'/>"<xsl:text
/>' );
    </xsl:comment></script>
    <noscript>[email address hidden, enable JavaScript to see it]</noscript>

  </xsl:template>


  <xsl:template match='a[starts-with( @href, "mailto:" )]'
                mode='link-filter'>
    <xsl:variable name='address' select='substring-after( @href, ":" )'/>
    <xsl:variable name='user'    select='substring-before( $address, "@" )'/>
    <xsl:variable name='host'    select='substring-after(  $address, "@" )'/>

    <xsl:variable name='content'>
      <xsl:apply-templates mode='link-filter'/>
    </xsl:variable>
    
    <script><xsl:comment>
 Obfuscate_with_body( '<xsl:value-of select='$host'/>', 
            '<xsl:value-of select='$user'/>',
            '<xsl:for-each select='@*'>
<xsl:if test='name() != "href" and name() != "class"'>
  <xsl:value-of select='name()'/>="<xsl:value-of select='.'/>" <xsl:text/>
</xsl:if>
</xsl:for-each>
<xsl:text>class="email </xsl:text><xsl:value-of select='@class'/>"<xsl:text/>', 
'<xsl:value-of disable-output-escaping='yes' select='string( $content )'/>' );
    </xsl:comment></script>

    <noscript>
      <xsl:choose>
        <xsl:when test='@noscript'>
          <xsl:value-of disable-output-escaping='yes' select='@noscript'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select='$content'/>
          <xsl:text> [email hidden, enable JavaScript to see it]</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </noscript>

  </xsl:template>



  <xsl:variable name='parents'/>
  <xsl:variable name='parents-set'  select='exsl:node-set($parents)'/>

  <xsl:template match='hl[@screen]'
                mode='link-filter'>

    <xsl:variable name='screen' select='@screen'/>

    <xsl:choose>
      <xsl:when test='$current-screen-id and ($current-screen-id = @screen)'>
        <span class='here' title='You are here'>
          <xsl:apply-templates mode='content-filter'/>
        </span>
      </xsl:when>

      <xsl:when test='$parents-set/*[@id=$screen]'>
        <span class='here' title='You are in this section now'>
          <xsl:apply-templates mode='link-filter'/>
        </span>
      </xsl:when>

      <xsl:otherwise>
        <span class='hl'>
          <xsl:apply-templates mode='link-filter'/>
        </span>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>




  <xsl:template match='onsubmit|check|hint' mode='null'/>
  <xsl:template match='onsubmit|check' mode='link-filter'/>

  <xsl:template name='phrase'>
    <xsl:param name='ref'/>
    <xsl:variable name='cont'>
      <phrase ref='{$ref}'/>
    </xsl:variable>
    <xsl:apply-templates select='exsl:node-set( $cont )' mode='link-filter'/>
  </xsl:template>

  <xsl:template match='phrase' mode='link-filter'>
    <xsl:apply-templates mode='link-filter'/>
  </xsl:template>

  <xsl:template match='phrase[@ref]' mode='link-filter'>
    <xsl:variable name='ref' select='@ref'/>
    <xsl:choose>
      <xsl:when test='$phrase-local/*[@id=$ref]'>
        <xsl:apply-templates mode='link-filter'
                             select='$phrase-local/*[@id=$ref]'/>
      </xsl:when>
      <xsl:when test='$phrase/*[@id=$ref]'>
        <xsl:apply-templates mode='link-filter'
                             select='$phrase/*[@id=$ref]'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode='link-filter'
                             select='*|text()'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



</xsl:stylesheet>
