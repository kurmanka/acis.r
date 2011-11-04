<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis date #default"
    xmlns:date="http://exslt.org/dates-and-times"
    version="1.0">

  <xsl:import href='index.xsl'/>
  <xsl:import href='events.xsl'/>
  <xsl:import href='events-overview.xsl'/>

  <xsl:variable name='asked-for' select='//asked_for'/>
  <xsl:variable name='chunked'   select='//to_be_continued' />

  <xsl:variable name='start'     select='$timespan/from'/>
  <xsl:variable name='start-date'  select='concat($start/day/text(), "T", $start/time/text())'/>

  <xsl:variable name='for-year'>
    <xsl:value-of select='substring($start-date,1,4)'/>
  </xsl:variable>

  <xsl:variable name='for-month'>
    <xsl:value-of select='substring($start-date,6,2)'/>
  </xsl:variable>

  <xsl:variable name='for-day' select='"day"'/>


  <xsl:variable name='startminusday' select='date:add($start-date,"-P1D")'/>

  <xsl:variable name='link-suffix'>
    <xsl:if test='$qsoptions'>?<xsl:value-of select='$qsoptions'/></xsl:if>
<!--
    <xsl:text>+</xsl:text>
-->
  </xsl:variable>

  <xsl:variable name='previous-day-addr'>

    <xsl:choose>
      <xsl:when test='$start-date'>
        <xsl:text>/adm/events/</xsl:text>
        <xsl:value-of select='substring($startminusday,1,10)'/>
        <xsl:if test='substring($startminusday,12,8) != "00:00:00"'>
          <xsl:text>/</xsl:text>
          <xsl:value-of select='substring($startminusday,12,8)'/>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
    
  </xsl:variable>


  <xsl:template name='go-back'>

    <xsl:choose>
      <xsl:when test='substring($start-date,12,8) != "00:00:00"'>
        
        <!-- there was an xmlns='http://nnn' on the next element -->
        <a
         class='int'
         href='{$base-url}/adm/events/{substring($start-date,1,10)}{$link-suffix}'
         title='this day start'
        >^&lt;&lt; day start</a>

      </xsl:when>
      <xsl:otherwise>

        <!-- there was an xmlns='http://nnn' on the next element -->
        <a 
           class='int'
           href='{$base-url}{$previous-day-addr}{$link-suffix}'
        >&lt;&lt;&lt; previous day</a>

      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>


  <xsl:template name='go-forward'>

    <!-- there was an xmlns='http://nnn' on the next element -->
    <a class='int'
       href='{$base-url}{$next-chunk-addr}{$link-suffix}'>
      <xsl:choose>
        <xsl:when test='$chunked'>next chunk </xsl:when>

        <xsl:when test='//next-second/time/text() = "00:00:00"'
                  >next day </xsl:when>
      </xsl:choose>

      <xsl:text>&gt;&gt;&gt;</xsl:text>
    </a>

  </xsl:template>


  <xsl:template name='navigate-back-forth'>
    <xsl:call-template name='go-back'/>
    <xsl:text>&#160; | &#160;</xsl:text>
    <xsl:call-template name='go-forward'/>
  </xsl:template>



  <!-- human-readable presentation of the shown timespan -->

  <xsl:variable name='timespan-string'>
    <xsl:for-each select='$timespan'>
      <xsl:value-of select='from/day'/>
      <xsl:text> </xsl:text>
      <xsl:value-of select='from/time'/>

      <xsl:choose>
        <xsl:when test='to/day/text() != from/day/text()'>
          <xsl:text> -- </xsl:text>
          <xsl:value-of select='to/day'/>
          <xsl:text> </xsl:text>
        </xsl:when>
        <xsl:otherwise>-</xsl:otherwise>
      </xsl:choose>
      
      <xsl:value-of select='to/time'/>
    </xsl:for-each>         
  </xsl:variable>



  <xsl:variable name='next-chunk-addr'>
    <xsl:text>/adm/events/</xsl:text>
    <xsl:value-of select='//next-second/day'/>
    <xsl:if test='//next-second/time/text() != "00:00:00"'>
      <xsl:text>/</xsl:text>
      <xsl:value-of select='//next-second/time'/>
    </xsl:if>
    <xsl:if test='$chunked'>
      <xsl:text>..</xsl:text>
      <xsl:value-of select='$asked-for/timespan/to/day'/>
      <xsl:text>/</xsl:text>
      <xsl:value-of select='$asked-for/timespan/to/time'/>
    </xsl:if>
  </xsl:variable>



  <xsl:template name='showing-what'>

    <xsl:for-each select='$showing'>
      <small>Showing: events: <xsl:value-of select='eventscount'/>,
      sessions: <xsl:value-of select='sessionscount'/>
      <xsl:if test='options/hidemagic'>, no magic sessions</xsl:if>
      <xsl:if test='options/onlyresearch'>, only research-profile claims</xsl:if>
      ...set your <a ref='/adm/events/pref'>preferences</a>.
      </small>
    </xsl:for-each>

  </xsl:template>




  <xsl:template match='/'>

    <xsl:variable name='amount' select='count(//events/list-item)'/>


    <xsl:call-template name='page'>
      <xsl:with-param name='title'
                      >Events <xsl:value-of select='$timespan-string'/></xsl:with-param>
      <xsl:with-param name='content'>

        <xsl:call-template name='crumbs'/>

        <h1>
          <xsl:text>Events</xsl:text>

          <xsl:if test='$timespan'>
            <xsl:text> for </xsl:text>
            <xsl:value-of select='$timespan-string'/>
          </xsl:if>
        </h1>

        <xsl:call-template name='show-status'/>

<xsl:if test='$showing'>
  <p>
    <xsl:call-template name='showing-what'/>
    <br />
    <xsl:call-template name='navigate-back-forth'/>
  </p>
</xsl:if>

        <xsl:call-template name='show-events'/>

        <xsl:if test='$next-chunk-addr'>
<p style='text-align: center'>

 <xsl:call-template name='navigate-back-forth'/>

</p>
        </xsl:if>


        <xsl:call-template name='adm-menu'/>


      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>

      