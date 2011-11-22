<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
  version="1.0">
  <xsl:import href='page.xsl'/>
  <xsl:import href='../person/page.xsl'/>
  <xsl:variable name='current-screen-id'>
    <xsl:text>personal-menu</xsl:text>
  </xsl:variable>
  <xsl:template match='/data'>
    <xsl:call-template name='user-page'>
      <xsl:with-param name='title'>
        <xsl:value-of select='$record-name'/>
      </xsl:with-param>
      <!-- there was an xml:space=preserve here -->
      <xsl:with-param name='content'>
        <acis:phrase ref='announcements'/>
        <h1 class='name'>
          <xsl:value-of select='$record-name'/>
        </h1>
        <xsl:call-template name='show-status'/>
        <p>
          <xsl:text>The profile in its current state on </xsl:text>
          <a ref='@profile-overview'>
            <xsl:text>the overview page</xsl:text>
          </a>
          <xsl:text>.</xsl:text>
        </p>
        <p>
          <xsl:text>Edit the profile:</xsl:text>
        </p>        
        <xsl:call-template name='user-person-menu'/>
        <p>
          <xsl:text>Then you can </xsl:text>
          <a ref='off'
             title='logout' >
            <xsl:text>save changes and logout</xsl:text>
          </a>
          <xsl:text>.</xsl:text>
        </p>
        <p>
          <xsl:text>Manage your account:</xsl:text>
        </p>
        <ul class='menu'>
          <li>
            <a ref='settings'
               title='account settings'>
              <xsl:text>change account email and password</xsl:text>
            </a>
          </li>
          <!-- there used to be an xml:space='default' attribute on the next element -->
          <xsl:choose>
            <xsl:when test='not( $advanced-user )'>
              <li>
                <a ref='unregister'>
                  <xsl:text>delete your account</xsl:text>
                </a>
              </li>
            </xsl:when>
            <xsl:otherwise>
              <li>
                <xsl:text>delete this record -- not implemented yet</xsl:text>
              </li>
              <!-- XXX deleting a particular record of an advanced user -->
            </xsl:otherwise>
          </xsl:choose>
        </ul>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
