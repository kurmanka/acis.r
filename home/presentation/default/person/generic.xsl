<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">

  <xsl:import href='../page-universal.xsl'/>
<!--
  <xsl:import href='../forms.xsl'/>
-->

  <xsl:template name='generic-person-screen' xml:space='preserve'>

    <h1>The function performed</h1>
        
    <xsl:call-template name='show-status'/>

    <xsl:if test='$success'>
      <p>Pretty successful.</p>
    </xsl:if>
        
    <xsl:choose xml:space='default'>
      <xsl:when test='$session-type = "user"'>
        <p><a ref='@menu'>Return to the main menu.</a></p>
      </xsl:when>
    </xsl:choose>

  </xsl:template>



  <!--    t h e   p a g e  -->
  
  <xsl:template match='/data'>

    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>Generic</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='generic-person-screen'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

</xsl:stylesheet>
