<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
  version="1.0">
 
  <xsl:import href='../global.xsl'/>

  <xsl:import href='../widgets.xsl'/>

  <xsl:import href='../page-universal.xsl'/> <!-- for the link-filter mode -->

  <xsl:import href='../person/research/listings.xsl'/><!-- for present-resource template -->

  <xsl:variable name='parents'>
    <acis:par id='citations'/>
  </xsl:variable>


  <!-- render a citation -->
  <xsl:template name='citation'>
    <xsl:param name='label'/>

    <p class='citing-document'><i class='tech'>in: </i>

          <xsl:choose>
            <xsl:when test='string(srcdocurlabout)'>
              <a class='citingtitle' href='{srcdocurlabout}' title='the citing document'><xsl:value-of select='srcdoctitle'/></a>
            </xsl:when>
            <xsl:otherwise>
              <span class='citingtitle' title='the citing document'><xsl:value-of select='srcdoctitle'/></span>
            </xsl:otherwise>
          </xsl:choose>
          by <xsl:value-of select='srcdocauthors'/></p>
          
          <p class='cited-as'>
   <i class='tech'>as: </i> 

          <xsl:choose>
            <xsl:when test='$label'>
              <label for='{$label}' class='citstring' title='is this your work mentioned here?'
                     ><xsl:value-of select='ostring'/></label>
            </xsl:when>
            <xsl:otherwise>
              <span class='citstring' title='is this your work mentioned here?'
                    ><xsl:value-of select='ostring'/></span>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text> </xsl:text>
          </p>

  </xsl:template>

  <!-- this variant is used on the citations/potential screen if configuration parameter citation-presentation-reverse is enabled -->
  <xsl:template name='citation-as-in-by'>
    <xsl:param name='label'/>
    <p class='cit-first'><i class='tech'>as: </i> 
    <xsl:choose>
      <xsl:when test='$label'>
        <label for='{$label}' class='citstring' title='is this your work mentioned here?'
               ><xsl:value-of select='ostring'/></label>
      </xsl:when>
      <xsl:otherwise>
        <span class='citstring' title='is this your work mentioned here?'
              ><xsl:value-of select='ostring'/></span>
      </xsl:otherwise>
    </xsl:choose>
    </p>

    <p class='cit-follow'><i class='tech'>in: </i>
    <xsl:choose>
      <xsl:when test='string(srcdocurlabout)'>
        <a class='citingtitle' href='{srcdocurlabout}' title='the citing document'><xsl:value-of select='srcdoctitle'/></a>
      </xsl:when>
      <xsl:otherwise>
        <span class='citingtitle' title='the citing document'><xsl:value-of select='srcdoctitle'/></span>
      </xsl:otherwise>
    </xsl:choose>
    by <xsl:value-of select='srcdocauthors'/></p>
    
  </xsl:template>
   




  <xsl:template name='cit-page'>
    <xsl:param name='title'/>
    <xsl:param name='content'/>

    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>
        <xsl:choose>
          <xsl:when test='not(string-length( $title ))'>
            <xsl:text>citation profile</xsl:text>
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
            <acis:hl screen='citations/doclist'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@citations/doclist'>document&#160;list</a>
              <xsl:text>&#160;</xsl:text>
            </acis:hl>

            <acis:hl screen='citations/autosug'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@citations/autosug'>auto&#160;suggestions</a>
              <xsl:text>&#160;</xsl:text>
            </acis:hl>

            <acis:hl screen='citations/refused'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@citations/refused'>refused</a>
              <xsl:text>&#160;</xsl:text>
            </acis:hl>

            <acis:hl screen='citations/autoupdate'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@citations/autoupdate'>auto&#160;update</a>
              <xsl:text>&#160;</xsl:text>
            </acis:hl>

          </span>
        </p>
        <xsl:text> 
        </xsl:text>
    </xsl:with-param></xsl:call-template>
    
  </xsl:template>


  <xsl:variable name='to-go-options'>
    <xsl:if test='$request-screen != "citations"'>
      <acis:op><a ref='@citations' >main citations page</a></acis:op>
    </xsl:if>
    <acis:root/>
  </xsl:variable>

</xsl:stylesheet>