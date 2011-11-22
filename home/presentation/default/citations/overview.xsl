<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
 
  <xsl:import href='general.xsl'/>
  <xsl:import href='doclist.xsl'/>

  <xsl:variable name='current-screen-id'>citations</xsl:variable>

  <xsl:variable name='identified-num' select='number($response-data/identified-number)'/>
  <xsl:variable name='potent-new-num' select='number($response-data/potential-new-number)'/>
  <xsl:variable name='refused' select='number($response-data/refused-number)'/>

  <xsl:template name='overview'>
    <h1>Citation Profile</h1>

    <!-- intro -->
    <p>
      <big>Here you deal with citations to your works by
      other researchers.  We search for citations based on
      your <a ref='@name#variations'>name variations</a> and
      your <a ref='@research/identified' >research
      profile</a>.  The search is automatic and is done in
      offline, but you deal with its results here.</big>
    </p>


    <!-- potential, identified & doclist -->
    <xsl:choose> 
      <xsl:when test='$list/list-item[1]/new'>
        <p>We have found <a ref='@citations/autosug'>
        <xsl:value-of select='$potent-new-num'/> new potential citation
        <xsl:if test='$potent-new-num&gt;1'>s</xsl:if>
        </a> to your works, please check <xsl:choose >
        <xsl:when test='$potent-new-num &gt;1' >them
      </xsl:when>
      <xsl:otherwise >it</xsl:otherwise>
        </xsl:choose>.</p>
      </xsl:when>
      <xsl:when test='not($list/list-item)'>
        <p>We haven't found any citations for you yet.</p>
      </xsl:when>
      <xsl:when test='$potent-new-num=0 and $list/list-item[1]/old'>
        <p>We don't have any new citations for you.</p>
      </xsl:when>
      <xsl:otherwise>
        <p>Currently we don't have any citations for you.</p>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:choose>
      <xsl:when test='$list/list-item'>
        
        <xsl:choose>
          <xsl:when test='$identified-num = 1'>

            <p>
              Just 1 citation is identified to a document of
              your <a ref='@research/identified'>research profile</a>.
              </p>
            
          </xsl:when>
          <xsl:otherwise>
            
            <p>A total of <xsl:value-of select='$identified-num'/> 
            citations are identified to <a ref='@citations/doclist' >the
            documents</a> of your <a ref= '@research/identified' >research profile</a>.</p>
            
          </xsl:otherwise>
        </xsl:choose>
        
        <div style='margin: 0px 2em 2em 2em; font-size: smaller;'>
          
        <xsl:call-template name='doclisttable-overview'>
          <xsl:with-param name='max' select='"5"'/>
        </xsl:call-template>
        
        <p><small><a ref='@citations/doclist'>Full
        table of documents and citations.</a ></small></p>

        </div>

      </xsl:when>
    </xsl:choose>

    
    <!-- refused -->
    <xsl:choose>
      <xsl:when test='number($refused)'>

    <p>You have <a ref='@citations/refused'><xsl:value-of
    select='$refused' /> refused citation<xsl:if
    test='number($refused) &gt; 1'>s</xsl:if></a>, which you
    may review.</p>

      </xsl:when>
      <xsl:otherwise>

    <p>There is also a screen of <a ref='@citations/refused'>refused citations</a>, but you
    currently don't have any.</p>
    
      </xsl:otherwise>
    </xsl:choose>


    <!-- auto-update -->

    <p>You may choose your citations' profile <a
    ref='@citations/autoupdate'>automatic update
    preferences</a>.</p>
    
  </xsl:template>

  <xsl:template match='/'>
    <xsl:call-template name='cit-page'>
      <xsl:with-param name='title'>citation profile</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='overview'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
