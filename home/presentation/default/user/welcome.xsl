<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">

  <xsl:import href='page.xsl'/>
  <xsl:import href='../person/page.xsl'/>

  <xsl:variable name='current-screen-id'>personal-menu</xsl:variable>

  
  <xsl:template match='/data'>
    <xsl:call-template name='user-page'>

      <xsl:with-param name='title'><xsl:value-of select='$record-name'/></xsl:with-param>

      <xsl:with-param name='content' xml:space='preserve'>

        <phrase ref='announcements'/>

<!-- this supposed to be a table for news:
        <table>
          <tr>
            <td>
-->        
        <h1 class='name'><xsl:value-of select='$record-name'/></h1>
        
        <xsl:call-template name='show-status'/>
        
        <p>The profile in its current state on <a
        ref='@profile-overview' >the overview page</a>.</p>

        <p>Edit the profile:</p>
        
        <xsl:call-template name='user-person-menu'/>


        <p>Then you can <a ref='off' title='log off' >save changes and exit</a>.</p>

        <p>Manage your account:</p>

        <ul class='menu'>

          <li><a ref='settings' title='account settings' >change account email
          and password</a></li>

          <xsl:choose xml:space='default'>
            <xsl:when test='not( $advanced-user )'>
              <li><a ref='unregister' >delete your account</a></li>
            </xsl:when>
            <xsl:otherwise>
              <li>delete this record -- not implemented yet</li>
              <!-- XXX deleting a particular record of an advanced user -->
            </xsl:otherwise>
          </xsl:choose>
        </ul>

<!--            </td>
            <td class='news'>
            </td>
          </tr>
        </table> -->


      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  
</xsl:stylesheet>
