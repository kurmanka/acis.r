<!--   This file is part of the ACIS presentation template-set.   -->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">  


  <xsl:import href='../../email/general.xsl'/>
  <xsl:import href='../../email/arpm-notice.xsl'/>
  <xsl:import href='../page.xsl'/>



  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>re-search</xsl:with-param>
      
      <xsl:with-param name='content'>

<h1>ARPM email</h1>

<xsl:call-template name='arpm-email'/>

<hr/>

<pre>
<xsl:call-template name='arpm-notice'/>
</pre>

      </xsl:with-param>

    </xsl:call-template>
  </xsl:template>




</xsl:stylesheet>