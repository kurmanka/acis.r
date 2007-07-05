<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl xml x'
  xmlns:x='http://x'
  version="1.0">
 
  <xsl:import href='../user/page.xsl'/>
  <xsl:variable name='current-screen-id'></xsl:variable>

  <xsl:template name='user-person-profile-menu'>
    <xsl:call-template name='link-filter'>
      <xsl:with-param name='content'>
        <xsl:text>
        </xsl:text>
    
        <p class='menu'>
    <hl screen='personal-menu'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@menu' title='main menu'>
        <xsl:choose>
          <xsl:when test='$record-about-owner'>Profile:</xsl:when>
          <xsl:otherwise>
            <span class='name'><xsl:value-of select='$record-name'/></span>
            <xsl:text>'s profile:</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </a>
      <xsl:text>&#160;</xsl:text>
    </hl>

    <xsl:text> </xsl:text>
    <hl screen='personal-name'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@name' title='name details'>names</a>
      <xsl:text>&#160;</xsl:text>
    </hl>
    
    <xsl:text> </xsl:text>
    <hl screen='personal-contact'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@contact' title='contact information'>contact</a>
      <xsl:text>&#160;</xsl:text>
    </hl>
       
    <xsl:text> </xsl:text>
    <hl screen='affiliations'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@affiliations' title='places where you work'>affiliations</a>
      <xsl:text>&#160;</xsl:text>
    </hl>
    
      <xsl:text> </xsl:text>

    <hl screen='research/main'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@research' title='research profile' >research</a>
      <xsl:text>&#160;</xsl:text>
    </hl>

    <!--[if-config(citations-profile)]-->
    <xsl:text> </xsl:text>
    <hl screen='citations'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@citations' title='citation profile' >citations</a>
      <xsl:text>&#160;</xsl:text>
    </hl>
    <!--[end-if]-->

    <xsl:text> | </xsl:text>
    <hl screen='personal-overview'>
      <xsl:text>&#160;</xsl:text>
      <a ref='@profile-overview' title='current state of the profile' >overview</a>
      <xsl:text>&#160;</xsl:text>
    </hl>
    </p>

<xsl:text> 
</xsl:text>

    </xsl:with-param></xsl:call-template>
  </xsl:template>

  
  <!--  USER'S PERSON RECORD MENU   -->
  <xsl:template name='user-person-menu'>  
    <ul class='menu'>
      <li><a ref='@name' >name details</a></li>
      <li><a ref='@contact' >contact details</a></li>
      <li><a ref='@affiliations' >affiliations</a></li>
      <li><a ref='@research' >research</a></li>
      <!--[if-config(citations-profile)]-->
      <li><a ref='@citations' >citations</a></li>
      <!--[end-if]-->
    </ul>
  </xsl:template>

</xsl:stylesheet>