<xsl:stylesheet
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:exsl='http://exslt.org/common'
    xmlns:acis='http://acis.openlib.org'
    xmlns:html='http://www.w3.org/1999/xhtml'
    exclude-result-prefixes='exsl xml html acis'
    version='1.0'>  

  <!-- This is the global "page" template -->
  <!-- has the global variables, error and handling -->
  <xsl:import href='global.xsl'/>
  <!-- has the fieldset templates -->
  <xsl:import href='forms.xsl'/>

  <xsl:output
      method="html"
      doctype-public="-//W3C//DTD HTML 4.01//EN"
      doctype-system="http://www.w3.org/TR/html4/strict.dtd"
      omit-xml-declaration='yes'
      encoding='utf-8'/>


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
    <html>
      <head>
        <!-- title element -->
        <title>
          <xsl:choose>
            <xsl:when test='string-length($full-page-title)'>
              <xsl:value-of select='$full-page-title'/>
            </xsl:when>
            <xsl:when test='string-length($page-title)'>
              <xsl:value-of select='$site-name'/>
              <xsl:text>: </xsl:text>
              <xsl:value-of select='$page-title'/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select='$site-name'/>
              <xsl:text>: </xsl:text>
              <xsl:value-of select='$title'/>
            </xsl:otherwise>
          </xsl:choose>
        </title>
        <xsl:text> </xsl:text>
        <!-- link to the stylesheet file -->
        <xsl:choose>
          <xsl:when  test='$css-url'>
            <link rel='stylesheet'
                  href='{$css-url}'
                  type="text/css"/>
	  </xsl:when>
          <xsl:otherwise>
            <link rel='stylesheet'
                  href="{$static-base-url}/style/main.css"
                  type='text/css'
                  title='default'/>
	    <xsl:text>
	    </xsl:text>
	    <!-- brownish style disabled -->
            <!-- <link rel="alternate stylesheet" href="{$static-base-url}/style/brownish.css" -->
            <!-- type="text/css" title='brownish'/>  -->
          </xsl:otherwise>
	</xsl:choose>	
        <xsl:copy-of select='$headers'/>
        <xsl:copy-of select='$additional-head-stuff'/>
        <meta http-equiv='Content-Script-Type' content='text/javascript'/>
        <script type='text/javascript' src='{$static-base-url}/script/main.js'/>        
        <script type='text/javascript' src='{$static-base-url}/script/jquery.js'/>        
        <script type='text/javascript'>
          <xsl:for-each select='exsl:node-set( $content )//script[not(@insitu)]'>
            <xsl:copy-of select='text()'/>
          </xsl:for-each>          

          <!-- Collect javascript code to be put in the header by runnng the -->
          <!-- scripting modes over the contents of acis:form elements -->
          <!-- This is the "form Javascript" -->
          <xsl:apply-templates select='exsl:node-set( $content )//acis:form' 
                               mode='scripting'/>          

	  <!-- Collect other javascript from the acis:script-onload that the -->
	  <!-- templates may have. Such javascript is put into a load function -->
            <xsl:text>
  function onLoad() {
//    onload_show_switcher();
	    </xsl:text>

          <!-- ToK 2008-04-02: do this only if it exists, adding an extra if -->
          <xsl:if test='exsl:node-set( $content )//acis:script-onload/text()'>            
            <xsl:copy-of select='exsl:node-set( $content )//acis:script-onload/text()'/>
          </xsl:if>
	  <xsl:text>
  }
	  </xsl:text>
        </script>

        <!-- ToK 2008-04-03 add calls to external javascript. -->
        <xsl:for-each select='exsl:node-set( $content )//script/@src'>
          <script type='text/javascript'>
            <xsl:attribute name='src'>
              <xsl:value-of select='$static-base-url'/>
              <xsl:text>/script/</xsl:text>
              <xsl:value-of select='.'/>
            </xsl:attribute>
          </script>
        </xsl:for-each>
        <!-- add the style sheet from <style> in the page  -->
        <!-- ToK 2008-03-30: wrap an if so we don't have it when there is nothing in it -->
        <xsl:if test='exsl:node-set( $content )//style/text()'>
          <style type='text/css'>
            <xsl:copy-of select='exsl:node-set( $content )//style/text()'/>
          </style>
        </xsl:if>
      </head>
      <!-- body of the page -->
      <!-- first, the <body> element and its attributes --> 
      <body class='{$page-class} {$current-screen-id}' onload='onLoad();'>
	<!-- pace an id= on the <body> if there is a $page-id -->
	<xsl:if test='string-length( $page-id )'>
          <xsl:attribute name='id'>
            <xsl:value-of select='$page-id'/>
          </xsl:attribute>
        </xsl:if>
	<!-- The following probably overwrites the default, which is to have -->
	<!-- the $page-class and current-screen-id. We append 'Screen' to the -->
	<!-- $current-screen-id -->
        <xsl:choose>
          <xsl:when test='$page-class'>
            <xsl:attribute name='class'>
              <xsl:value-of select='$page-class'/>
            </xsl:attribute>
          </xsl:when>
          <xsl:when test='$current-screen-id'>
            <!-- create a class name for the page 2008-01-09 -->
            <!-- first replace / because it is not allowed in a class name -->
            <xsl:variable name='own-page-class'
                          select='translate($current-screen-id,"/","_")'/>
            <xsl:attribute name='class'>
            <xsl:value-of select='$own-page-class'/>Screen</xsl:attribute>
          </xsl:when>
        </xsl:choose>
	<!-- ToK 2008-03-30: remove this comment, make it a comment -->
        <xsl:comment> service announcements go here </xsl:comment>
	<!-- the header division --> 
        <div class='header'
             id='top'>
          <p class='site-title'>
	    <!-- FIXME: the <big><big> should be replaced by a font indication in -->
            <!-- the site-title class is CSS -->
            <big>
              <big>
                <span class='site-title'>
                  <a href='{$home-url}'
                     class='site-title'>
                    <xsl:value-of select='$site-name-long'/>
                  </a>
                </span>
              </big>
            </big>
          </p>
          <!-- other material to be put into the header division, page specific --> 
	  <xsl:copy-of select='$into-the-top'/>          
        </div>
        <!-- the subHeader division contains the $navigation, passed through -->
        <!-- an additional-page-nagivation template set. If only Ivan had chosen -->
	<!-- more uniform names! --> 
	<xsl:if test='exsl:node-set($navigation)/*'>
	  <div class='subHeader'
               xml:space='default'>
            <xsl:copy-of select='$navigation'/>
            <xsl:call-template name='additional-page-navigation'/>
          </div>	  
        </xsl:if>        
        <!-- the content divisions -->
        <div class='content'>          
          <!-- content div starts with the $body-title -->
          <xsl:if test='$body-title' xml:space='default'>
	    <h1>
              <xsl:value-of select='$body-title'/>
            </h1>
          </xsl:if>	  
          <!-- then show errors, if there are any --> 
          <xsl:if test='$show-errors'
                  xml:space='default'>
            <xsl:call-template name='show-errors'/>
          </xsl:if>          
          <!-- pass the contents through the link-filter templates -->
          <xsl:apply-templates select='exsl:node-set( $content )'
                               mode='link-filter'/>
          <!-- call the content-bottom-navigation, and pass it through -->
          <!-- the link-filter -->
          <xsl:call-template name='link-filter'
                             xml:space='default'>
            <xsl:with-param name='content'>
              <xsl:call-template name='content-bottom-navigation'/>
            </xsl:with-param>
          </xsl:call-template>          
        </div>       
        <!-- page footer -->
        <xsl:call-template name='link-filter' xml:space='default'>
          <xsl:with-param name='content' xml:space='preserve'>
	    <div class='footer'>	      
	      <!-- create the acis page-footer phrase --> 
              <acis:phrase ref='page-footer'>
                <p class='menu'>
		  <!-- FIXME: introduce a class for this <small> element --> 
		  <small>
		    <span class='footer-navigation'>
                      <!-- not sure what the no-form-check does here -->
                      <a href='mailto:{$admin-email}'
                         class='int email' 
                         no-form-check=''>ADMINISTRATOR EMAIL</a>
                      | <a href='{$home-url}' class='int' >HOME</a>
		    </span>
                  </small>
                </p>
              </acis:phrase>
            </div>            
            <acis:phrase ref='after-footer'/>
          </xsl:with-param>
        </xsl:call-template>  
      </body>
    </html>
  </xsl:template>

  <!-- this closes the global page template --> 
  <!-- by default, the additional-page-navigation and the content-bottom-navigation are empty -->
  <xsl:template name='additional-page-navigation'/>
  <xsl:template name='content-bottom-navigation'/>

  <!-- I don't understand this --> 
  <xsl:variable name='current-screen-id' select='""'/>
  <xsl:variable name='current-screen-id-real'>
    <xsl:value-of select='$current-screen-id'/>
  </xsl:variable>

  <!-- by default, there is no scription on elements and text --> 
  <xsl:template match='*'      mode='scripting'/>
  <xsl:template match='text()' mode='scripting'/>

  <!-- the main definition of the link-filter: -->
  <!-- pipe all children through all templates in the link-filter mode -->
  <xsl:template name='link-filter'>
    <xsl:param name='content'/>
    <xsl:apply-templates select='exsl:node-set( $content )'
                         mode='link-filter'/>
  </xsl:template>

  <!-- blank link-filter rules -->
  <xsl:template match='style'  mode='link-filter'/>
  <xsl:template match='acis:script-onload'
                               mode='link-filter'/>

  <!-- link filter copies all attributes -->
  <xsl:template match='@*|*'   mode='link-filter'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:apply-templates mode='link-filter'/>
    </xsl:copy>
  </xsl:template>

  <!-- make acis:comments a comment in the output -->
  <!-- there are such comments in research/autosuggest-chunk -->  
  <xsl:template match='acis:comment' mode='link-filter'>
    <xsl:comment>
      <xsl:apply-templates mode='link-filter'/>
    </xsl:comment>
  </xsl:template>

  <!-- pass the acis hint through the link filter -->
  <xsl:template match='acis:hint' mode='link-filter'>
    <xsl:apply-templates mode='link-filter'/>
  </xsl:template>

  <!-- the link-filter rules for the fieldset elements -->
  <!-- in html: or null namespace, not when in acis: namespace -->
  <xsl:template match='input|select|textarea|select|textarea|input'
                mode='link-filter'>    
    <xsl:variable name='class'>
      <!-- variable class is string "input@type" where @type is type attribute -->
      <xsl:if test='name() = "input"'>
        <xsl:text>input</xsl:text>
        <xsl:value-of select='@type'/>
      </xsl:if>
      <!-- append the class attrbiute value to the value of $class -->
      <xsl:if test='@class'>
        <xsl:if test='name() = "input"'>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select='@class'/>
      </xsl:if>
    </xsl:variable>      
    <xsl:copy>
      <!-- copy all attributes -->
      <xsl:copy-of select='@*'/>
      <!-- add attribute class with value $class -->
      <xsl:attribute name='class'>
        <xsl:value-of select='$class'/>
      </xsl:attribute>
      <!-- create new attribute onfocus -->
      <xsl:if test='not(@type="hidden")'>        
        <xsl:attribute name='onfocus'>
          <xsl:if test='@onfocus'>
            <xsl:value-of select='@onfocus'/>;<xsl:text/>
          </xsl:if>
          <!-- use $class as this.className -->
          <xsl:text>this.className='</xsl:text>
          <xsl:value-of select='$class'/>
          <xsl:text> active';</xsl:text>
          <xsl:if test='acis:hint'>
            <xsl:text>show('</xsl:text>
            <xsl:value-of select='@id'/>
            <xsl:text>Hint');</xsl:text>
          </xsl:if>
          <xsl:if test='@onfocus_after'>
            <xsl:value-of select='@onfocus_after'/>
            <xsl:text>;</xsl:text>
          </xsl:if>
        </xsl:attribute>
        <!-- create new attribute onblur -->
        <xsl:attribute name='onblur'>
          <xsl:if test='@onblur'>
            <xsl:value-of select='@onblur'/>;<xsl:text/>
          </xsl:if>
          <!-- use $class as this.className -->
          <xsl:text>this.className='</xsl:text>
          <xsl:value-of select='$class'/>
          <xsl:text>';</xsl:text>
          <xsl:if test='acis:hint'>
            <xsl:text>hide('</xsl:text>
            <xsl:value-of select='@id'/>
            <xsl:text>Hint');</xsl:text>
          </xsl:if>
          <xsl:if test='@onblur_after'>
            <xsl:value-of select='@onblur_after'/>
            <xsl:text>;</xsl:text>
          </xsl:if>
        </xsl:attribute>        
      </xsl:if>
      <!-- if the <acis:form> class= attribute has the value important, -->
      <!-- make a special deal for onchange= attribute -->
      <xsl:if test='contains( ancestor::acis:form/@class, "important" )'>
        <xsl:attribute name='onchange'>
          <xsl:if test='@onchange'>
            <xsl:value-of select='@onchange'/>;<xsl:text/>
          </xsl:if>
          <!-- if the <acis:form> name = -->
          <xsl:text>a_parameter_change( "</xsl:text>
          <xsl:value-of select='ancestor::acis:form/@name'/>
          <xsl:text>" );</xsl:text>
        </xsl:attribute>
      </xsl:if>      
      <!-- for select, apply the linkfilter to children -->
      <xsl:if test='name() = "select"'>
        <xsl:apply-templates mode='link-filter'/>
      </xsl:if>
      
      <!-- for textarea, copy the text -->
      <xsl:if test='name()="textarea"'>
        <xsl:copy-of select='text()'/>
      </xsl:if>            
      <!-- but this is still in copy -->
    </xsl:copy>    
    <!-- do any hint that comes with the fieldset elements -->
    <xsl:if test='acis:hint'>
      <xsl:call-template name='input-hint'/>
    </xsl:if>    
  </xsl:template>  

  <!-- the link-filter for the form --> 
  <xsl:template match='acis:form' mode='link-filter'>
    <xsl:text>
    </xsl:text>      
    <!-- create form element, in null namespace -->
    <xsl:element name='form'
                 use-attribute-sets='form'>      
      <!-- copy all attributes except screen=. maybe there is name= to add here -->
      <xsl:copy-of select='@*[name()!="screen" and name()!="name"]'/>      
      <!-- where is the action=? It is in the screen= -->
      <xsl:attribute name='action'>
        <xsl:choose>
          <xsl:when test='@screen'>
            <!-- build $ref, first screen= -->
            <xsl:variable name='ref'
                          select='@screen'/>
            <xsl:variable name='fragment'>
              <!-- build $fragment, part of ref after a #, if there -->
              <xsl:choose>
                <xsl:when test='contains( $ref, "#" )'>
                  <xsl:value-of select='substring-after( $ref, "#" )'/>
                </xsl:when>
              </xsl:choose>
            </xsl:variable>            
            <!-- build variable $sceen-to -->
            <xsl:variable name='screen-to'>
              <!-- build variable $sceen-to-1, the part before the session id -->
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
                  <xsl:value-of select='substring-after( $screen-to-1, ")" )'/>
                </xsl:when>
                <xsl:when test='contains( $ref, "@" )'>
                  <xsl:value-of select='substring-after( $screen-to-1, "@" )'/>
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
            <!-- now building to-object-id, a pointer to an object being handled -->
            <!-- by an advanced user, who can handle not only her own objects -->
            <xsl:variable name='to-object-id'>              
              <xsl:variable name='destination'>
                <xsl:choose>
                  <xsl:when test='contains( $ref, "@(" )'>
                    <xsl:variable name='tail'
                                  select='substring-after( $ref, "@(" )'/>
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
      <!-- if there is an onsubsubmit or check, the form will go through -->
      <!-- a checking function taking its name from the name= attribute of the form -->
      <xsl:choose>
        <xsl:when test='.//acis:onsubmit or .//acis:check'>
          <xsl:attribute name='onsubmit'>
          <xsl:text>return form_check_</xsl:text>
          <xsl:value-of select='@name'/>
          <xsl:text>();</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <!-- an old otherwise in case that the name= is not there -->
        <!--    <xsl:otherwise> -->
        <!--    <xsl:attribute name='onsubmit'>return form_submit();</xsl:attribute>  -->
        <!--    </xsl:otherwise> -->
      </xsl:choose>      
      <xsl:apply-templates mode='link-filter'/>
    </xsl:element>
  </xsl:template>

  <!-- the link-filter for links with href -->
  <xsl:template match='a[@href]' mode='link-filter'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <!-- <xsl:copy-of select='@href|@tabindex|@class|@title|@id|@name|@style|@onclick|@accesskey'/> -->
      <xsl:call-template name='link-attributes'/>
      <xsl:apply-templates mode='link-filter'/>
    </xsl:copy>
  </xsl:template>


  <!-- the link-filter for links with ref -->
  <xsl:template match='a[@ref]|acis:a[@ref]' name='aref' mode='link-filter'>
    <!--
    a[ref] element usage:
    <a ref='name'>names screen</a>
    <a ref='@name'>names for current user & record</a>
    <a ref='name#variations'>variations on the names screen</a>
    <a ref='name?back=contributions#variations'>variations with return</a>
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
          <xsl:value-of select='substring-after( $screen-to-1, ")" )'/>
        </xsl:when>
        <xsl:when test='contains( $ref, "@" ) and substring-before( $ref, "@" )=""'>
          <xsl:value-of select='substring-after( $screen-to-1, "@" )'/>
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

    <!-- start building the actual link -->
    <a>
      <xsl:copy-of select='@title|@tabindex|@onclick'/>


      <!-- it it has class at all, it is internal -->
      <xsl:attribute name='class'>
        <xsl:text>int</xsl:text>
        <xsl:if test='@class'>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@class"/>
        </xsl:if>
      </xsl:attribute>

      <!-- building the href attribute -->
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
      <!-- call the link-attributes -->
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

  <xsl:template match='span' mode='content-filter'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:apply-templates mode='content-filter'/>
    </xsl:copy>
  </xsl:template>

  <!-- the screens, used at the registration stage -->
  <xsl:template match='a[@screen]' mode='link-filter'>
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

  <!-- building an email link -->
  <xsl:template match='a[@email]' mode='link-filter'>
    <xsl:variable name='address' select='@email'/>
    <xsl:variable name='user'    select='substring-before( $address, "@" )'/>
    <xsl:variable name='host'    select='substring-after(  $address, "@" )'/>
    <script>
        <xsl:text>Obfuscate( '</xsl:text>
        <xsl:value-of select='$host'/>
        <xsl:text>','</xsl:text>
        <xsl:value-of select='$user'/>
        <xsl:text>','</xsl:text>
        <xsl:for-each select='@*'>
          <xsl:if test='name() != "href" and name() != "class" and name() != "email"'>
            <xsl:value-of select='name()'/>
            <xsl:text>="</xsl:text>
            <xsl:value-of select='.'/>
            <xsl:text>" </xsl:text>
            <xsl:text/>
          </xsl:if>
        </xsl:for-each>
        <xsl:text>class="email </xsl:text>
        <xsl:value-of select='@class'/>
	<xsl:text>"' );</xsl:text>
    </script>                                                                                  
    <noscript>
      <span>
        <xsl:text>[email address hidden, enable JavaScript to see it]</xsl:text>
      </span>
    </noscript>    
  </xsl:template>

  <!-- building an email link, mailto address  -->
  <xsl:template match='a[starts-with( @href, "mailto:" )]' mode='link-filter'>
    <xsl:variable name='address' select='substring-after( @href, ":" )'/>
    <xsl:variable name='user'    select='substring-before( $address, "@" )'/>
    <xsl:variable name='host'    select='substring-after(  $address, "@" )'/>
    <!-- I don't understand this -->
    <xsl:variable name='content'>
      <xsl:apply-templates mode='link-filter'/>
    </xsl:variable>
    <script type='text/javascript'>
      <xsl:text>Obfuscate_with_body( '</xsl:text>
      <xsl:value-of select='$host'/>
      <xsl:text>','</xsl:text>
      <xsl:value-of select='$user'/>
      <xsl:text>','</xsl:text>
      <xsl:for-each select='@*'>
        <xsl:if test='name() != "href" and name() != "class"'>
          <xsl:value-of select='name()'/>
          <xsl:text>="</xsl:text>
          <xsl:value-of select='.'/>
          <xsl:text>" </xsl:text>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>class="email </xsl:text>
      <xsl:value-of select='@class'/>
      <xsl:text>"',</xsl:text> 
      '<xsl:value-of disable-output-escaping='yes' select='string( $content )'/>
      <xsl:text>' );</xsl:text>
    </script>
    <noscript>
      <xsl:choose>
        <xsl:when test='@noscript'>
          <xsl:value-of disable-output-escaping='yes'
                        select='@noscript'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select='$content'/>
          <span>
            <xsl:text>[email hidden, enable JavaScript to see it]</xsl:text>
          </span>
        </xsl:otherwise>
      </xsl:choose>
    </noscript>    
  </xsl:template>

  <!-- create an empty node-set $parents -->
  <xsl:variable name='parents'/>
  <xsl:variable name='parents-set'
                select='exsl:node-set($parents)'/>

  <!-- link filter for <hl> elements -->
  <xsl:template match='acis:hl[@screen]' mode='link-filter'>
    <xsl:variable name='screen'
                  select='@screen'/>
    <xsl:choose>
      <xsl:when test='$current-screen-id and ($current-screen-id = @screen)'>
        <span class='here'
              title='You are here'>
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

  <xsl:template match='acis:onsubmit|acis:check|acis:hint'
                mode='null'/>

  <xsl:template match='acis:onsubmit|acis:check' mode='link-filter'/>

  <xsl:template name='phrase'>
    <xsl:param name='ref'/>
    <xsl:variable name='cont'>
      <acis:phrase ref='{$ref}'/>
    </xsl:variable>
    <xsl:apply-templates select='exsl:node-set( $cont )' mode='link-filter'/>
  </xsl:template>

  <xsl:template match='acis:phrase' mode='link-filter'>
    <xsl:apply-templates mode='link-filter'/>
  </xsl:template>

  <xsl:template match='acis:phrase[@ref]' mode='link-filter'>
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

  <xsl:template match='acis:script-onload' mode='scripting'>
    <xsl:copy-of select='text()'/>
  </xsl:template>

  <xsl:template match='acis:form[descendant::acis:onsubmit or descendant::acis:check]'
                mode='scripting'>
    <xsl:text>
function form_check_</xsl:text>
    <xsl:value-of select='@name'/>
    <xsl:text>() { 
    var element;    
    var value;
</xsl:text>    
    <xsl:for-each select='.//*[name() = "acis:onsubmit" or name() = "acis:check"]'>
      <xsl:if test='parent::input'>
        <xsl:for-each select='parent::input'>
          <xsl:text>
    {
          element = getRef( "</xsl:text>
          <xsl:value-of select='@id'/>
          <xsl:text>" );
          value = element.value;          
</xsl:text>
          <xsl:if test='acis:check/@nonempty'>
            <xsl:text>
        if ( value == '' ) { 
            </xsl:text>
            <xsl:choose>
              <xsl:when test='acis:name'>
                <xsl:text>alert( "Please enter </xsl:text>
                <xsl:value-of select='acis:name/text()'/>
                <xsl:text>." );</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>alert( "Please enter a value into the </xsl:text>
                <xsl:value-of select='@name'/> field." );
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text>
              element.focus();
              return( false );
        }            
</xsl:text>
          </xsl:if>
          <xsl:text>
    }
</xsl:text>
        </xsl:for-each>
      </xsl:if>      

      <xsl:if test='parent::input'>
        <xsl:for-each select='parent::input'>
          <xsl:text>
    {
          element = getRef( "</xsl:text>
          <xsl:value-of select='@id'/>
          <xsl:text>" );
          value = element.value;
</xsl:text>
          <xsl:if test='acis:check/@nonempty'>           
            <xsl:text>
          if ( value == '' ) { </xsl:text>
            <xsl:choose>
              <xsl:when test='acis:name'>                
                <xsl:text>alert( "Please enter </xsl:text>
                <xsl:value-of select='acis:name/text()'/>
                <xsl:text>." ); </xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text> alert( "Please enter a value into the </xsl:text>
                <xsl:value-of select='@name'/>
                <xsl:text> field." ); </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text>element.focus();
            return( false );
          }
</xsl:text>
          </xsl:if>
          <xsl:text>
    }
</xsl:text>
        </xsl:for-each>
      </xsl:if>      

      <xsl:if test='name() = "acis:check" and @test'>
        <xsl:text>if ( </xsl:text>
        <xsl:value-of select='@test'/>
        <xsl:text> ) { 
        </xsl:text>
        <xsl:value-of select='do'/>
        <xsl:text>}
        </xsl:text>
      </xsl:if>      
      <xsl:if test='name() = "acis:onsubmit"'>
        <xsl:value-of select='text()'/>
      </xsl:if>

    </xsl:for-each>

    <xsl:text>
     formChanged = false;
     return true;
 }
    </xsl:text>
  </xsl:template>

  <xsl:template name='input-hint'>
    <span id='{@id}Hint' style='display: none;'>
      <xsl:if test='not(acis:hint/@side)'>
        <br/>
        <xsl:text> </xsl:text>
      </xsl:if>
      <span class='WrapHint'>
        <xsl:choose>
          <xsl:when test='acis:hint/@side'>
            <span class='SideHint'>
              <xsl:apply-templates select='acis:hint'
                                   mode='link-filter'/>
            </span>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name='style'>
              <xsl:text>padding-left: 10px; padding-top: 0;</xsl:text>
            </xsl:attribute>
            <span class='Hint'>
              <xsl:apply-templates select='acis:hint'
                                   mode='link-filter'/>
            </span>
          </xsl:otherwise>
        </xsl:choose>
      </span>
    </span>
  </xsl:template>

  <!-- Will add a call to check_form_changes() javascript, if there -->
  <!--  is an "important" form on the page and there are changes -->
  <xsl:template name='link-attributes'>
    <xsl:if test='//acis:form[ contains( @class, "important" ) ]'>
      <xsl:if test='not( @no-form-check )'>
        <xsl:if test='@onclick'>
          <xsl:attribute name='onclick'>
            <xsl:value-of select='@onclick'/>
            <!-- remove 2009-11-23 removed check_form_changes -->
            <!-- <xsl:text>return check_form_changes();</xsl:text> -->
          </xsl:attribute>
        </xsl:if>
      </xsl:if>
    </xsl:if>    
  </xsl:template>

</xsl:stylesheet>
