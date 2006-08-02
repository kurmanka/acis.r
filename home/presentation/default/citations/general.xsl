<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl xml'
  version="1.0">
 
  <xsl:import href='../global.xsl'/>

  <xsl:import href='../widgets.xsl'/>

  <xsl:import href='../page-universal.xsl'/> <!-- for the link-filter mode -->

  <xsl:import href='../person/research/listings.xsl'/><!-- for present-resource template -->

  <xsl:variable name='parents'>
    <par id='citations'/>
  </xsl:variable>

  <xsl:template name='cit-page'>
    <xsl:param name='title'/>
    <xsl:param name='content'/>

    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>
        <xsl:choose>
          <xsl:when test='not(string-length( $title ))'>
            <xsl:text>citations profile</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='$title'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>

      <xsl:with-param name='content' select='$content'/>

    </xsl:call-template>

  </xsl:template>




  <xsl:template name='additional-page-navigation'>

    <xsl:call-template name='link-filter'>
      <xsl:with-param name='content'>
        
        <xsl:text>
        </xsl:text>
        <p class='menu submenu'>
          <span class='head here'><xsl:text>&#160;</xsl:text>
            <xsl:choose>
              <xsl:when test='$current-screen-id = "citations"'>
                <b>Citations:</b>
              </xsl:when>
              <xsl:otherwise>
                <a ref='@citations'>Citations:</a>
              </xsl:otherwise>
            </xsl:choose>
          <xsl:text>&#160;</xsl:text></span>

          <span class='body'>
            <hl screen='citations/doclist'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@citations/doclist'>document&#160;list</a>
              <xsl:text>&#160;</xsl:text>
            </hl>

            <hl screen='citations/autosug'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@citations/autosug'>auto&#160;suggest</a>
              <xsl:text>&#160;</xsl:text>
            </hl>

            <hl screen='citations/refused'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@citations/refused'>refused</a>
              <xsl:text>&#160;</xsl:text>
            </hl>

          </span>
        </p>
        <xsl:text> 
        </xsl:text>
    </xsl:with-param></xsl:call-template>
    
  </xsl:template>


  <xsl:variable name='to-go-options'>
    <xsl:if test='$request-screen != "citations"'>
      <op><a ref='@citations' >main citations page</a></op>
    </xsl:if>
    <root/>
  </xsl:variable>

</xsl:stylesheet>