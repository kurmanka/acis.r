<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:import href='page.xsl'/>

  <xsl:variable name='records' select='//records/list-item'/>

  <xsl:variable name='current-screen-id' select='"record-menu"'/>
  

  <xsl:template match='/'>

    <xsl:call-template name='user-account-page'>
      
      <xsl:with-param name='title'>Records menu</xsl:with-param>

      <xsl:with-param name='content'>

<h1>Records menu</h1>

<p><xsl:value-of select="count( $records )" /> records</p>

<xsl:choose>
  <xsl:when test='count( $records )'>

<table class='records sql'>
<tr>
<th>name</th>
<xsl:call-template name='record-actions-th'/>
</tr>

<xsl:for-each select='$records'>

<tr>
<td><xsl:value-of select='name'/></td>
<xsl:call-template name='record-actions-td'>
  <xsl:with-param name='rec' select='.'/>
</xsl:call-template>
</tr>
</xsl:for-each>

</table>
  </xsl:when>
</xsl:choose>


<xsl:if test='$request/user/type/deceased-list-manager'>
  <p>Add a profile: <a ref='adm/search/person'>person search</a></p>
</xsl:if>


<p>Other options:</p>

<ul class='menu'>
  
  <li><a ref='settings' title='email, password, etc.' >account settings</a></li>

<xsl:if test='$request/user/type/deceased-list-manager'>
  <li><a ref='adm/search/person'>personal profile search</a></li>
</xsl:if>

  <li><a ref='off'>log off</a></li>

</ul>


      </xsl:with-param> <!-- /content -->
    </xsl:call-template>



  </xsl:template>


  <xsl:template name='record-actions-th'>
    <th colspan='8'>actions</th>
  </xsl:template>

  <xsl:template name='record-actions-td'>
    <xsl:param name='rec'/>
    <xsl:variable name='id'  select='$rec/id/text()'/>
    <xsl:variable name='sid' select='$rec/sid/text()'/>
    <xsl:variable name='record-sid' select='$rec/sid/text()'/>

  <xsl:variable name='research-suggestions-number-text'>
    <xsl:if test='$response-data/*[name()=$record-sid]/research-suggestions-exact and 
                  number($response-data/*[name()=$record-sid]/research-suggestions-exact/text()) &gt; 0'>
      <xsl:text> </xsl:text>
      <span class='notification-number'>
        <xsl:value-of select='$response-data/*[name()=$record-sid]/research-suggestions-exact'/>
      </span>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name='citation-suggestions-number-text'>
    <xsl:if test='$response-data/*[name()=$record-sid]/citation-suggestions-new-total and 
                  number($response-data/*[name()=$record-sid]/citation-suggestions-new-total/text()) &gt; 0'>
      <xsl:text> </xsl:text>
      <span class='notification-number'>
        <xsl:value-of select='$response-data/*[name()=$record-sid]/citation-suggestions-new-total'/>
      </span>
    </xsl:if>
  </xsl:variable>


    <td class='act'><a ref='@({$sid})/menu'>enter</a></td>
    <td class='act'><a ref='@({$sid})/name'>name</a></td>
    <td class='act'><a ref='@({$sid})/contact'>contact</a></td>
    <td class='act'><a ref='@({$sid})/affiliations'>affiliations</a></td>
    <td class='act'><a ref='@({$sid})/research'>research</a>
        <xsl:copy-of select='$research-suggestions-number-text'/>
    </td>
    <td class='act'>
      <!--[if-config(citations-profile)]
       <a ref='@({$sid})/citations'>citations</a>
       <xsl:copy-of select='$citation-suggestions-number-text'/>
          [end-if]-->
    </td>
    <td class='act'>
      <a ref='@({$sid})/deceased'>
        <xsl:choose>
          <xsl:when test='$rec/deceased/text()'>
            <xsl:value-of select='$rec/deceased/text()'/>
          </xsl:when>
          <xsl:when test='$rec/deceased'>
            <xsl:text>(yes)</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>(no)</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </a>
  </td>
    <td class='act'> <a ref='@({$sid})/profile-overview'>overview</a> </td>
  </xsl:template>


  <xsl:template name='record-brief-menu'>
    <xsl:param name='rec'/>

    <xsl:variable name='id'  select='$rec/id/text()'/>
    <xsl:variable name='sid' select='$rec/sid/text()'/>

    <!-- we absolutely assume record type="person" here -->
    <strong><span class='name'><xsl:value-of select='$rec/name'/></span></strong>:
    <a ref='@({$sid})profile-overview'>overview</a> | <a ref='@({$sid})menu'>menu</a>
    <br/>
    <small>
      <a ref='@({$sid})/name'>name</a> 
      | <a ref='@({$sid})/contact'>contact</a>
      | <a ref='@({$sid})/affiliations'>affiliations</a>
      | <a ref='@({$sid})/research'>research</a>
      <!--[if-config(citations-profile)]
        | <a ref='@({$sid})/citations'>citations</a>
          [end-if]-->
    </small>
  </xsl:template>



</xsl:stylesheet>