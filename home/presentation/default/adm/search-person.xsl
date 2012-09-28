<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings" 
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl html acis"
    version="1.0">  

  <!--   This file is part of the ACIS presentation template set.   -->

  <xsl:import href='index.xsl'/>

  <xsl:variable name='result' select='$response-data/result'/>
  <xsl:variable name='items'  select='$result/data/list-item'/>

  <xsl:variable name='admin-mode'                 select='//user/type/admin'/>
  <xsl:variable name='deceased-list-manager-mode' select='//user/type/deceased-list-manager'/>

  <xsl:template match='/data'>
    <xsl:call-template name='page'>
      <xsl:with-param name='title'>adm/search/person</xsl:with-param>
      <xsl:with-param name='content'>

<style>
form h2 { margin-top: 1px; }
form.wide h2 { margin-right: 1em; float: left; }
co { 
 font-family: monospaced, courier;
}

</style>

<h1>Search personal records</h1>

<acis:form>

<p>
<!--
<label for='key'>Email, short-id or name: </label>
-->
<label for='key'>Email or short-id: </label>
<input type='text' id='key' name='key' value='{$form-values/key}' size='60'/>
q
<xsl:text> </xsl:text>
<input type='submit' class='important' value='SEARCH'/>
</p>

</acis:form>

        <xsl:if test='$result/problem'>
          
          <p>
            <big>
              <xsl:for-each select='$result/problem/*'>
                <xsl:value-of select='text()'/>
              </xsl:for-each>
          </big>
          </p>
          
        </xsl:if>

        <xsl:if test='$result'>
          <table class='sql'>
            <tr>
              <th>shortid</th>
              <th>name</th>
              <th>email</th>
              <th>handle</th>
              <th>actions</th>
            </tr>

            <xsl:for-each select='$items'>
              <tr>
                <td><xsl:value-of select='shortid'/></td>
                <td><xsl:value-of select='namefull'/></td>
                <td>
                  <xsl:value-of select='owner'/>
                </td>
                <td><xsl:value-of select='id'/></td>
                <td>
                  <xsl:if test='$admin-mode'>
                    <a ref='adm/log_into?login={owner}'>
                      log into account
                    </a>
                  </xsl:if>
                  <br/>
                  <xsl:if test='$deceased-list-manager-mode'>
                    <a ref='adm/move-record?from={str:replace(owner,"+","%2b")}&amp;sid={shortid}'>add to my account</a>
                  </xsl:if>
                </td>
              </tr>
            </xsl:for-each>

          </table>

        </xsl:if>
        
        <xsl:if test='$admin-mode'>
          <xsl:call-template name='adm-menu'/>
        </xsl:if>
      
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

</xsl:stylesheet>
