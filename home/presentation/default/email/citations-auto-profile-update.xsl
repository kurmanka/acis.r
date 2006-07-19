<!--   This file is part of the ACIS presentation template-set.   -->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">  


  <xsl:import href='general.xsl'/>

  <xsl:template match='/data' name='acpu-notice'>
    <xsl:call-template name='format-message'>
      <xsl:with-param name='to'>"<xsl:value-of select='$user-name'/>" &lt;<xsl:value-of select='$user-login'/>&gt;</xsl:with-param>
      <xsl:with-param name='subject'>citations automatically added</xsl:with-param>

      <xsl:with-param name='content'>
        <xsl:call-template name='acpu-email'/>
      </xsl:with-param>      
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template name='acpu-email'>

    <p>Dear <xsl:value-of select='$user-name'/>,</p>

    <xsl:if test='$advanced-user'>
      <p>Note: this message concerns the record of <xsl:value-of
      select='$record-name'/> (id: <xsl:value-of
      select='$record-id'/>, short-id: <xsl:value-of
      select='$record-sid'/>).</p>
    </xsl:if>

    <p>This is an automatic message from <xsl:value-of
    select='$site-name-long'/>.  You don't need to reply.</p>

    <p>We ran a search for citations to your documents in
    our service and found some, which we think point to
    these your documents, see below.  We added these
    citations to your profile, but if there's an error, you
    can fix it.</p>

    <xsl:for-each select='//doc-w-cit/list-item'>
      <p>Document:</p>

      <p class='indent'><xsl:value-of select='title'/><br/>
      <xsl:value-of select='type'/> by <xsl:value-of
      select='authors'/><br/>
      <xsl:value-of select='url-about'/></p>
      
      <p>Citation<xsl:if
      test='count(citations/list-item)&gt;1'>s</xsl:if>:</p>

      <ul>
      <xsl:for-each select='citations/list-item'>
        <li>
          <xsl:value-of select='ostring'/><br/>
          <xsl:if test='srcdocdetails/text()'>
            <xsl:text>source: </xsl:text>
            <xsl:value-of select='srcdocdetails'/>
          </xsl:if>
        </li>
      </xsl:for-each>
      </ul>
        

    </xsl:for-each>

    <p>Your updated profile is at its permanent address:<br/>
    <xsl:value-of select='//saved-profiles//link'/></p>
 
    <p>If necessary, review and change your preferences with regard to
    automatic citations profile update at:<br/> <a
    href='{$base-url}/citations/autoupdate'
    ><xsl:value-of select='$base-url'/>/citations/autoupdate</a>
    </p>

    <xsl:if test='$user-pass and not($user-type/hide-password)'>
      <p>Your password in our service is: <xsl:value-of select='$user-pass'/></p>
    </xsl:if>

  </xsl:template>


  
</xsl:stylesheet>


