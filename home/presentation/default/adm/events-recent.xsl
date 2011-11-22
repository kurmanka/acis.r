<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis date"
    xmlns:date="http://exslt.org/dates-and-times"
    version="1.0">

  <xsl:import href='events-decode.xsl'/>



  <xsl:template match='/'>

    <xsl:variable name='amount' select='count(//events/list-item)'/>


    <xsl:call-template name='page'>
      <xsl:with-param name='title'
                      >recent events <xsl:value-of select='$timespan-string'/></xsl:with-param>
      <xsl:with-param name='content'>

        <xsl:call-template name='crumbs'/>

        <h1>
          <xsl:text>Recent events</xsl:text>

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

  <xsl:call-template name='go-back'/>

  <xsl:if test='$chunked'>
    <xsl:text>&#160; | &#160;</xsl:text>
    <xsl:call-template name='go-forward'/>
  </xsl:if>
  
  </p>
</xsl:if>

        <xsl:call-template name='show-events'/>

        <xsl:if test='$next-chunk-addr'>
<p style='text-align: center'>

  <xsl:call-template name='go-back'/>

  <xsl:if test='$chunked'>
    <xsl:text>&#160; | &#160;</xsl:text>
    <xsl:call-template name='go-forward'/>
  </xsl:if>

</p>
        </xsl:if>


        <xsl:call-template name='adm-menu'/>


      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>

      