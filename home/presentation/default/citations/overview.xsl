<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes='exsl xml'
    version="1.0">
 
  <xsl:import href='general.xsl'/>
  <xsl:import href='doclist.xsl'/>

  <xsl:variable name='current-screen-id'>citations</xsl:variable>

  <xsl:template name='overview'>
    <h1>Citations Profile</h1>

    <xsl:choose> 
      <xsl:when test='$list/list-item[1]/new'>
        <p>Please <a ref='@citations/autosug'>check this</a>
        for the new potential citations to your works (the
        most interesting document).</p>
      </xsl:when>
    </xsl:choose>

    <xsl:choose>
      <xsl:when test='$list/list-item'>

        <p>The documents of your <a ref='@research/identified'>research profile</a>:</p>

        <xsl:call-template name='doclisttable'>
          <xsl:with-param name='max' select='"5"'/>
        </xsl:call-template>

      </xsl:when>
    </xsl:choose>

    <p>You may have some citations <a
    ref='@citations/refused'>refused</a>, but that screen
    doesn't work yet.</p>

    <p>Then also we will make a <a
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
