<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
 version="1.0">

  <xsl:import href='../page.xsl'/>


  <xsl:variable name='showing'   select='//showing'/>
  <xsl:variable name='timespan'  select='//showing/timespan'/>
  <xsl:variable name='options'   select='$showing/options'/>


  <xsl:variable name='qsoptions' select='$request/querystring/text()'/>

  <xsl:variable name='columns'>
<!--
    <acis:c name='type'>Type</c>
    <acis:c name='class'>Class</c>
    <acis:c name='action'>Action</c>
-->
    <acis:c name='descr'>Description</acis:c>
    <acis:c name='data'>Data</acis:c>
    <acis:c name='chain'>Session</acis:c>
    <acis:c name='startend'>Start/End</acis:c>
  </xsl:variable>

  <xsl:variable name='event-dates'>
    <dates>
      <xsl:for-each select='//events/list-item'>
        <xsl:variable name='fullday'>
          <xsl:choose>
            <xsl:when test='about/date'>
              <xsl:value-of select='about/date'/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select='date'/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name='day' select='substring($fullday, 1, 10)'/>
        <xsl:attribute name='day{$day}'>1</xsl:attribute>
      </xsl:for-each>
    </dates>
  </xsl:variable>


  <xsl:template name='listify'>
    <xsl:param name='string'/>
    <xsl:variable name='item' select='substring-before( $string, "&#xa;" )'/>
    <xsl:variable name='rest' select='substring-after(  $string, "&#xa;" )'/>
    <xsl:variable name='first'>
      <xsl:choose>
        <xsl:when test='$item'><xsl:value-of select='$item'/></xsl:when>
        <xsl:otherwise><xsl:value-of select='$string'/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

      <xsl:choose>
        <xsl:when test='not( starts-with( $first, "URL" ))'>
    <li>
          <xsl:value-of select='$first'/>
<xsl:text>
</xsl:text>
          </li>
        </xsl:when>
      <xsl:otherwise>
<!--        <xsl:value-of select='substring-before( $first, ": " )'/>: 
<a href='{substring-after( $first, ": " )}'
   ><xsl:value-of select='substring-after( $first, ": " )'
/></a>
-->
        </xsl:otherwise>
      </xsl:choose>

    <xsl:if test='$rest'>
      <xsl:call-template name='listify'>
        <xsl:with-param name='string' select='$rest'/>
      </xsl:call-template>
    </xsl:if>

  </xsl:template>



  <xsl:template name='format-event-data'>
    <xsl:param name='string'/>
    <xsl:if test='string-length( $string )'>
      <ul>
      <xsl:call-template name='listify'>
        <xsl:with-param name='string' select='$string'/>
      </xsl:call-template>
      </ul>
    </xsl:if>
  </xsl:template>

  <!--    <xsl:variable name='first' select='string-before( $data, " -->





  <!--  SESSION BOX  -->


  <xsl:template name='session'>

    <xsl:variable name='time' select='substring( date, 11 )'/>

    <xsl:variable name='id' select='generate-id()'/>

    <tr class='session' id='{$id}'>
      <td colspan='8' class='session'>

<div class='sw'><a href='#' onclick='showhide_log("{$id}");return false;'
>show/hide log</a></div>
                      
<!--
        <div style='float: right'>
          <span id='{$id}totalhide'
                >[<a href='#{$id}' 
onclick=
'javascript:hide("{$id}det");hide("{$id}totalhide");show("{$id}totalshow");return false;'
          >hide</a>]</span> 


<span id='{$id}totalshow'
      >[<a href='#{$id}' 
onclick=
'javascript:show("{$id}det"); hide("{$id}totalshow"); show("{$id}totalhide"); return false;'
                           >show</a>]</span> 

        </div>
-->

<!--
                           <acis:script-onload>
hide("<xsl:value-of select='$id'/>det"); 
hide("<xsl:value-of select='$id'/>totalhide"); 
show("<xsl:value-of select='$id'/>totalshow");
</acis:script-onload>
-->

        <span class='time'><xsl:value-of select='$time'/></span>
        <xsl:text>&#160;</xsl:text>
        <strong><span class='name'><xsl:value-of
        select='about/humanname'/></span> session</strong>
        
        <xsl:if test='about/stype'>
          <xsl:text> </xsl:text>
          <span title='session type'
          >(<xsl:value-of select='about/stype'/>)</span>
        </xsl:if>
        
        <div id='{$id}det'>
          
          <ul>
            <li>login: <xsl:value-of select='about/login'/></li>
            <li>userdata file: <xsl:value-of select='about/userdata-file'/></li>
            
            <xsl:if test='about/IP'>
              <li>IP: <xsl:value-of select='about/IP'/></li>
            </xsl:if>
            
            <xsl:for-each select='about/*'>
              <xsl:choose>
                <xsl:when test='name() ="login" or name() ="userdata-file" or name() ="IP" or name()="session-type" or name()="stype" or name()="humanname"'/>
                <xsl:otherwise>
                  <li><xsl:value-of select='name()'/>: <xsl:value-of select='text()'/>
                  </li>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>

          </ul>

          <table id='{$id}log'>
            <caption>Log</caption>
            <tr>
              <th>[type] class - action</th>
              <th>description</th>
            </tr>

            <xsl:for-each select='log/list-item'>

              <tr title='{date}'>
                <xsl:if test='type/text()'>
                  <xsl:attribute name='class'>
                    <xsl:value-of select='type'/>
                  </xsl:attribute>
                </xsl:if>
                <td>
                  
                  <xsl:if test='type/text()'
                     > [<xsl:value-of select='type'/>] </xsl:if
                  >
                  <xsl:value-of select='class'/>
                  <xsl:if test='action/text()'
                          > - <xsl:value-of select='action'/>
                  </xsl:if>
                </td>
                <td>

                  <xsl:choose>
                    <xsl:when test='URL/text()'>
                      <a href='{URL}'>
                        <xsl:choose>
                          <xsl:when test='descr/text()'>
                            <xsl:value-of select='descr'/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select='URL'/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </a>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select='descr'/>
                    </xsl:otherwise>
                  </xsl:choose>
                  
                  <xsl:if test='string-length( descr/text() )'>
                    <br />
                  </xsl:if>
                  
                  <xsl:if test='data/text()'>
                    <xsl:call-template name='format-event-data'>
                      <xsl:with-param name='string' select='data/text()'/>
                    </xsl:call-template>
                  </xsl:if>
                  
                </td>
              </tr>

            </xsl:for-each>    


            <xsl:if test='not(log/list-item)'>
              <xsl:value-of disable-output-escaping='yes' select='log/text()'/>
            </xsl:if>


          </table>


<!--

-->
          
        </div>
        
      </td>
    </tr>


  </xsl:template>





  <xsl:template name='single-event'>

    <xsl:choose>
      <xsl:when test='date'>

        <xsl:variable name='time' select='substring( date, 12 )'/>

    <tr class='orphan'>
      
      <xsl:if test='type/text()'>
        <xsl:attribute name='class'><!-- for CSS -->
        <xsl:text>orphan </xsl:text>
        <xsl:value-of select='type'/>
        </xsl:attribute>
      </xsl:if>
      
      <td><xsl:value-of select='$time'/></td>

      <td>
        <xsl:if test='type/text()'>
          <small>[<xsl:value-of select='type'/>] </small>
        </xsl:if>
        
        <xsl:value-of select='class'/>
        <xsl:if test='action/text()'> - <xsl:value-of select='action'/>
        </xsl:if>
      </td>

      <td><xsl:value-of select='descr/text()'/></td>
      <td><xsl:value-of select='data/text()'/></td>
      <td><xsl:value-of select='chain/text()'
      /><xsl:if test='startend'>&#160;<xsl:value-of select='startend/text()'/></xsl:if></td>

    </tr>

      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='text()' disable-output-escaping='yes'/>        
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>





  <xsl:template name='show-events'>

    <style>
.ie5compat table.events {
 width: auto;
}

.brief .orphan {
 display: none;
}

.session div.sw { float: right; }
.session div.sw a:link,
.session div.sw a:visited { padding: 5px; }

.brief   #brief-switch-on, 
.nobrief #brief-switch-off { border-color: #333; }

span.switch { border: 1px solid transparent; padding: 3px;}

.closed table { display: none; }


    </style>

    <script>
function no_brief_mode( id ) {
 set_class_if( id, "brief",   false );
 set_class_if( id, "nobrief", true );
}

function brief_mode( id ) {
 set_class_if( id, "brief",   true );
 set_class_if( id, "nobrief", false );
}

function close_ses_boxes() {
  var close = readCookie( 'opensbox' );
  if ( close == 'true' ) { return; }

  var list = document.getElementsByTagName("tr");
  for ( var i = 0; i &lt; list.length; i++ ) {
    var el = list[i];
    if ( el.className == "session" ) {
      el.className = "session closed";
    }
  }
}
    
function showhide_log ( id ) {
  toggle_class( id, "closed" );
}
    </script>

<!--
    <acis:script-onload>brief_mode("theEvents");</acis:script-onload>
-->
<acis:script-onload>close_ses_boxes();</acis:script-onload>

    <div id='theEvents' class='brief'>
      <xsl:if test='contains( $user-agent, "MSIE 5.5;")'>
        <xsl:attribute name='class'>ie5compat</xsl:attribute>
      </xsl:if>
              

      <p><small>
      ORPHAN EVENTS:
      <xsl:choose>
        <xsl:when test='$options/orphan'>
      <span id='brief-switch-off' class='switch'
            ><a href='javascript:no_brief_mode("theEvents");' class='int'
      >SHOW</a></span>
            <xsl:text> </xsl:text>

            <span id='brief-switch-on' class='switch'
                  ><a href='javascript:brief_mode("theEvents");' class='int'
          >HIDE</a>
            </span>
        </xsl:when>
        <xsl:otherwise>no</xsl:otherwise>
      </xsl:choose>

          </small>
      </p>


        <xsl:for-each select='//showing/days/*[name() != "empty-hash"]'>
          <xsl:sort select='name()'/>
          <xsl:variable name='date' select='substring(name(),2)'/>

          <h2><xsl:value-of select='$date'/></h2>


          <table class='events' id='tab{$date}'>
            <tr>
              <th>time</th>
              <th>type, class - action</th>
              <th>description</th>
              <th>data</th>
              <th>session s/e</th>
            </tr>
            
            <xsl:for-each 
             select='$root//events/list-item[starts-with(date, $date)]'>
              <xsl:variable name='time' select='substring( date, 11 )'/>
              
              <xsl:choose>
                <xsl:when test='about'>
                  <!-- session -->
                  
                   <xsl:call-template name='session'/>
<!-- -->
                </xsl:when>
                <xsl:otherwise>
                  <!-- orphan event -->

                  <xsl:call-template name='single-event'/>

                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>

          </table>
        </xsl:for-each>

<xsl:if test='not(//showing/days)'>
        <xsl:for-each select='exsl:node-set( $event-dates )/dates/@*'>
          <xsl:variable name='date' select='substring( name(), 4 )'/>

          <h2><xsl:value-of select='$date'/></h2>


          <table class='events' id='tab{$date}'>
            <tr>
              <th>time</th>
              <th>type, class - action</th>
              <th>description</th>
              <th>data</th>
              <th>session s/e</th>
            </tr>
            
            <xsl:for-each 
             select='$root//events/list-item[starts-with(date, $date)]'>
              <xsl:variable name='time' select='substring( date, 11 )'/>
              
              <xsl:choose>
                <xsl:when test='about'>
                  <!-- session -->
                  
                   <xsl:call-template name='session'/>
<!-- -->
                </xsl:when>
                <xsl:otherwise>
                  <!-- orphan event -->

                  <xsl:call-template name='single-event'/>

                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>

          </table>
        </xsl:for-each>
</xsl:if>

      </div>


  </xsl:template>


</xsl:stylesheet>

      