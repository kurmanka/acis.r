<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes='exsl xml'
    version="1.0">
 
  <xsl:import href='general.xsl'/>
  <xsl:import href='doclist.xsl'/>

  <xsl:variable name='current-screen-id'>citations</xsl:variable>

  <xsl:variable name='refused' select='number($response-data/refused-number)'/>

  <xsl:template name='overview'>
    <h1>Citations Profile</h1>

    <!-- intro -->
    <p><big>Here you deal with citations to your works by
    other researchers.  We search for citations based on
    your <a ref='@name#variations'>name variations</a> and
    your <a ref='@research/identified' >research
    profile</a>.  The search is automatic and is done in
    offline, but you deal with its results here.</big></p>


    <!-- potential, identified & doclist -->
    <xsl:choose> 
      <xsl:when test='$list/list-item[1]/new'>
        <p>There are some <a ref='@citations/autosug'>new
        potential citations</a> to your works, please check
        them.</p>
      </xsl:when>
    </xsl:choose>

    <xsl:choose>
      <xsl:when test='$list/list-item'>

        <p><a ref='@citations/doclist'>The documents</a> of your <a ref='@research/identified'>research profile</a>:</p>

        <div style='padding: 0px 2em 0px 2em; font-size: smaller;'>

        <xsl:call-template name='doclisttable'>
          <xsl:with-param name='max' select='"5"'/>
        </xsl:call-template>

        <p><i>You may actually have more documents than
        you see above, these are just the first 5.  <a
        ref='@citations/doclist'>See full
        table.</a></i></p>

        </div>

      </xsl:when>
    </xsl:choose>

    
    <!-- refused -->
    <xsl:choose>
      <xsl:when test='number($refused)'>

    <p>You have <a ref='@citations/refused'><xsl:value-of
    select='$refused' /> refused citations</a>, which you
    may review.</p>

      </xsl:when>
      <xsl:otherwise>

    <p>There is also a screen of <a
    ref='@citations/refused'>refused citations</a>, but you
    currently don't have any.</p>

      </xsl:otherwise>
    </xsl:choose>


    <!-- auto-update -->

    <p>Then also we will make the <a
    ref='@citations/autoupdate'>automatic update
    preferences</a> screen.  Not yet.</p>
    
  </xsl:template>

  <xsl:template match='/'>
    <xsl:call-template name='cit-page'>
      <xsl:with-param name='title'>citations profile</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='overview'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
