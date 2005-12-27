<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">

  <xsl:import href='page.xsl'/>

  <xsl:variable name='records' select='//records/list-item'/>

  <xsl:variable name='current-screen-id' select='"record-menu"'/>
  

  <xsl:template match='/'>

    <xsl:call-template name='user-account-page'>

      <xsl:with-param name='title'>Records menu</xsl:with-param>

      <xsl:with-param name='content'>

<h1>Records menu</h1>

<p>Here are the records that you own:</p>

<xsl:choose>
  <xsl:when test='count( $records )'>

<ul class='records'> 

<xsl:for-each select='$records'>

<li><!-- <xsl:value-of select='name/full'/><br /> -->
<xsl:call-template name='record-brief-menu'>
  <xsl:with-param name='rec' select='.'/>
</xsl:call-template>
</li>

</xsl:for-each>
</ul>
  </xsl:when>
</xsl:choose>


<p>Other options:</p>

<ul class='menu'>
  
  <li><a ref='settings' title='email, password, etc.' >account settings</a></li>

  <li><a ref='new-person' title='does not work'>create new personal record</a>

  <!-- XXX -->
  <xsl:text> </xsl:text>
  <i>(Does not yet work)</i>
  </li>

  <li><a ref='off'>log off</a></li>

  <li><a ref='unregister' >delete your account</a></li>

</ul>


      </xsl:with-param> <!-- /content -->
    </xsl:call-template>



  </xsl:template>


  <xsl:template name='record-brief-menu'>
    <xsl:param name='rec'/>

    <xsl:variable name='id'  select='$rec/id/text()'/>
    <xsl:variable name='sid' select='$rec/sid/text()'/>
    

    <xsl:choose>
      <xsl:when test='$rec/type="person"'>
        <strong><span class='name'><xsl:value-of select='$rec/name/full'/></span></strong>:
        <a ref='@({$sid})profile-overview'>overview</a> | <a ref='@({$sid})menu'>menu</a>
        <br/>
        <small>
        <a ref='@({$sid})/name'>name</a> 
        | <a ref='@({$sid})/contact'>contact</a>
        | <a ref='@({$sid})/affiliations'>affiliations</a>
        | <a ref='@({$sid})/research'>research</a>
<!--        | <a ref='{$sid}/photo'>photo</a>
        | <a ref='{$sid}/interests'>interests</a>
-->
<!--        | <a ref='{$sid}/'></a> -->

        </small>
        <!-- XXX remove the record -->
      </xsl:when>
      <xsl:otherwise>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



</xsl:stylesheet>