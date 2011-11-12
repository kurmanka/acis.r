<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0"> 
  <xsl:import href='general.xsl'/>
  <!-- this template-specific variables: -->
  <xsl:variable name='rec'
                select='$response-data/record'/>
  <xsl:template match='/data'>
    <xsl:call-template name='message'>
      <xsl:with-param name='to'>
        <xsl:text>"</xsl:text>
        <xsl:value-of select='$user-name'/>
        <xsl:text>" &lt;</xsl:text>
        <xsl:value-of select='$user-login'/>
        <xsl:text>&gt;</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='subject'>
        <xsl:text>your profile data has changed</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='content'><xsl:text>&#10;&#10; Hello </xsl:text>
      <xsl:value-of select='$user-name'/>
      <xsl:text>,</xsl:text>
      <!--             <xsl:choose> -->
      <!--             <xsl:when test='$response-data/record/about-owner'> -->
      <!--             You or someone used your login and password to change  -->
      <!--             your personal profile in <xsl:value-of select='$site-name'/>. -->
      <!--             </xsl:when> -->
      <!--             <xsl:otherwise> -->
      <!--             User <xsl:value-of  -->
      <!--             Your profile in our system was changed by user ... this and that. -->      
      <xsl:text>&#10;&#10;We noticed you changed your profile in </xsl:text>
      <xsl:value-of select='$site-name'/>
      <xsl:text>.&#10;&#10;You may wish to check the updated profile at:&#10;&#10;</xsl:text>
      <xsl:value-of select='$response-data/permalink'/>
      <xsl:text>&#10;&#10;</xsl:text>
      <acis:phrase ref='email-updated-userdata-after-saved-profile-link'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>

