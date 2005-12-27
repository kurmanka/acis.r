<xsl:stylesheet
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:exsl="http://exslt.org/common"
 exclude-result-prefixes='exsl'
 version="1.0">

  <xsl:import href='../page.xsl'/>


  <xsl:template match='/'>



    <xsl:variable name='se'       select='$response-data/se'/>

    <xsl:variable name='id'         select='$se/id/text()'/>
    <xsl:variable name='user-login' select='$se/owner/login/text()'/>
    <xsl:variable name='user-name'  select='$se/owner/name/text()'/>
    <xsl:variable name='text'       select='$se/text/text()'/>
    <xsl:variable name='diff-sec'   select='number($se/diff/text())'/>
    <xsl:variable name='diff-min'   select='round( $diff-sec div 60 )'/>
    <xsl:variable name='diff-hr'    select='round( $diff-sec div 3600 )'/>


    <xsl:call-template name='page'>
      <xsl:with-param name='title'>peek-view of a session</xsl:with-param>

      <xsl:with-param name='content'>
        
        <h1>session <xsl:value-of select='$id'/></h1>

        <p>User: <xsl:value-of select='$user-login'/> 
        (<xsl:value-of select='$user-name'/>),

        <a href='{$base-url}/welcome!{$id}' class='int'>menu</a>.</p>



        <p>Last modified: <xsl:value-of select='$diff-min'/> minutes
        ago (roughly <xsl:value-of select='$diff-hr'/> hours ago).</p>

        <pre><xsl:value-of select='$text'/></pre>

      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>

