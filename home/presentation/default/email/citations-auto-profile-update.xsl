<!--   This file is part of the ACIS presentation template-set.   -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">  
  <xsl:import href='general.xsl'/>
  <xsl:template match='/data' name='acpu-notice'>
    <xsl:call-template name='format-message'>
      <xsl:with-param name='to'>
        <xsl:text>"</xsl:text>
        <xsl:value-of select='$user-name'/>
        <xsl:text>" &lt;</xsl:text>
        <xsl:value-of select='$user-login'/>
        <xsl:text>&gt;</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='subject'>
        <xsl:text>citations automatically added</xsl:text>
      </xsl:with-param>      
      <xsl:with-param name='content'>
        <xsl:call-template name='acpu-email'/>
      </xsl:with-param>      
    </xsl:call-template>
  </xsl:template>
  <xsl:template name='acpu-email'>    
    <p>
      <xsl:text>&#10;&#10;Dear </xsl:text>
      <xsl:value-of select='$user-name'/>
      <xsl:text>,</xsl:text>
    </p>
    <xsl:if test='$advanced-user'>
      <p>
        <xsl:text>&#10;Note: this message concerns the record of </xsl:text>
        <xsl:value-of select='$record-name'/>
        <xsl:text>(id: </xsl:text>
        <xsl:value-of select='$record-id'/>
        <xsl:text>, short-id: </xsl:text>
        <xsl:value-of select='$record-sid'/>
        <xsl:text>).</xsl:text>
      </p>
    </xsl:if>    
    <p>
      <xsl:text>&#10;&#10;This is an automatic message from </xsl:text>
      <xsl:value-of select='$site-name-long'/>
      <xsl:text>.  You don't need to reply.</xsl:text>
    </p>    
    <p>
    <xsl:text>&#10;&#10;We ran a search for citations to your documents in our service and found some, which we think point to these your documents, see below.  We added these citations to your profile, but if there's an error, you can fix it.</xsl:text>
    </p>    
    <xsl:for-each select='//docs-w-cit/list-item'>
      <p>
        <xsl:text>&#10;&#10;Document:&#10;</xsl:text>
      </p>      
      <p class='indent'>
        <xsl:value-of select='title'/>
        <br/>
        <xsl:value-of select='type'/>
        <xsl:text>&#10;by </xsl:text>
        <xsl:value-of select='authors'/>
        <br/>
        <xsl:value-of select='url-about'/>
      </p>      
      <p>
        <xsl:text>&#10;&#10;Citation</xsl:text>
        <xsl:if test='count(citations/list-item)&gt;1'>
          <xsl:text>s</xsl:text>
        </xsl:if>
        <xsl:text>:</xsl:text>
      </p>      
      <ul>
        <xsl:for-each select='citations/list-item'>
          <li>
            <xsl:text>&#10;in: </xsl:text>
            <xsl:value-of select='srcdoctitle'/>
            <br/>        
            <xsl:text>&#10;by </xsl:text>
            <xsl:value-of select='srcdocauthors'/>
            <br/>
            <xsl:if test='srcdocurlabout'>
              <xsl:value-of select='srcdocurlabout'/>
              <br/>
            </xsl:if>
            <br/>                
            <xsl:text>&#10;cited as: </xsl:text>
            <xsl:value-of select='ostring'/>
          </li>
        </xsl:for-each>
      </ul>      
    </xsl:for-each>
    <p>
      <xsl:text>&#10;&#10;You may review and change your citation profile at:</xsl:text>
      <br/> 
      <a href='{$base-url}/citations'>
        <xsl:value-of select='$base-url'/>
        <xsl:text>/citations</xsl:text>
      </a>
    </p>    
    <p>
      <xsl:text>If necessary, review and change your preferences with regard to automatic citation profile update at:</xsl:text>
      <br/> 
      <a href='{$base-url}/citations/autoupdate'>
        <xsl:value-of select='$base-url'/>
        <xsl:text>/citations/autoupdate</xsl:text>
      </a>
    </p>    
    <xsl:if test='$user-pass and not($user-type/hide-password)'>
      <p>
        <xsl:text>Your password in our service is: </xsl:text>
        <xsl:value-of select='$user-pass'/>
      </p>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>


