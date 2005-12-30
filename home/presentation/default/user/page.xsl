<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl xml x'
  xmlns:x='http://x'
  version="1.0">   <!-- user/page.xsl that is. defines "user-page" template. -->


  <xsl:import href='../page.xsl'/>


  <xsl:template name='user-profile-menu'>
    <xsl:choose>
      <xsl:when test='$record-type = "person"'>
        <xsl:call-template name='user-person-profile-menu'/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name='user-logged-notice'>
    <xsl:call-template name='link-filter'>
      <xsl:with-param name='content'>
        
        <p class='logged-notice'
           HULULL=''
           title='{$user-login}'
           >User <span class='name'>
              <xsl:value-of select='$user-name'/>
        </span>:

        <span class='menu'>

<a ref='settings' screen='account-settings' 
title='your account settings: email and password' >settings</a>

    <xsl:text>&#160;|&#160;</xsl:text>

<xsl:choose>
  <xsl:when test='$advanced-user'>
    <a ref='welcome' screen='record-menu' title='records menu' >records&#160;menu</a>
  </xsl:when>
  <xsl:otherwise>
    <a ref='welcome' screen='personal-menu' title='profile menu' >menu</a>
  </xsl:otherwise>
</xsl:choose>

    <xsl:text>&#160;|&#160;</xsl:text>

    <a ref='off' screen='account-logoff' title='log off: save changes, close session'
>exit</a>

</span>
     </p>
   </xsl:with-param></xsl:call-template>

  </xsl:template>


  <xsl:template name='user-page'>
    <xsl:param name='content'/>
    <xsl:param name='navigation'/>
    <xsl:param name='title'/>
 
    <xsl:call-template name='page'>
      <xsl:with-param name='into-the-top'>
        <xsl:call-template name='user-logged-notice'/>
      </xsl:with-param>
      <xsl:with-param name='navigation'>
        <xsl:call-template name='user-profile-menu'/>
        <xsl:copy-of select='$navigation'/>
      </xsl:with-param>
      <xsl:with-param name='title' select='$title'/>
      <xsl:with-param name='content' select='$content'/>
    </xsl:call-template>
  </xsl:template>


  <xsl:template name='user-account-page'>
    <xsl:param name='content'/>
    <xsl:param name='navigation'/>
    <xsl:param name='title'/>
 
    <xsl:call-template name='page'>
      <xsl:with-param name='into-the-top'>
        <xsl:call-template name='user-logged-notice'/>
      </xsl:with-param>
      <xsl:with-param name='navigation'>
        <xsl:copy-of select='$navigation'/>
      </xsl:with-param>
      <xsl:with-param name='title'      select='$title'/>
      <xsl:with-param name='content'    select='$content'/>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>