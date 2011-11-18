<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
 version="1.0">

  <xsl:import href='index.xsl'/>


  <xsl:template match='/'>

    <xsl:variable name='result' select='$response-data/result'/>
    <xsl:variable name='query'  select='$form-input/body' />

    <xsl:variable name='par1'  select='$form-input/par1' />
    <xsl:variable name='par2'  select='$form-input/par2' />
    <xsl:variable name='par3'  select='$form-input/par3' />
    <xsl:variable name='par4'  select='$form-input/par4' />


    <xsl:call-template name='page'>
      <xsl:with-param name='title'
      >sql: <xsl:value-of select='$query'/></xsl:with-param>

      <xsl:with-param name='content'>
        
        <p style='float:right'><small><a ref='adm/sql'>/adm/sql</a></small></p>

        <h1>sql</h1>

        <acis:form xsl:use-attribute-sets="form" id='sql' 
              screen='adm/sql' style='padding-right: 4px;'>
          <input name='body' value="{$query}" style='width: 90%'/>

          <span style='display: none;'><xsl:text> </xsl:text></span>
          <input type='SUBMIT' value='go' />
          <span style='display: none;'><xsl:text> </xsl:text></span>
          <input type='RESET'  value='re' />
          
<!--
          <small><small><br /><br /></small></small>
          
          <input type='text' name='par1' style='width: 80%' value='{$par1}'/><br/>
          <input type='text' name='par2' style='width: 80%' value='{$par2}'/><br/>
          <input type='text' name='par3' style='width: 80%' value='{$par3}'/><br/>
          <input type='text' name='par4' style='width: 80%' value='{$par4}'/><br/>
-->
        </acis:form>


        <xsl:if test='$result'>

          <h2><xsl:value-of select='$query'/></h2>

          <xsl:choose>
            <xsl:when test='$result/problem'>
              <p class='error'>Problem:</p>
              <ul>
                <xsl:for-each select='$result/problem/*'>
                  <li><xsl:value-of select='local-name()'/>: 
                  <xsl:value-of select='text()'/>
                  </li>
                </xsl:for-each>
              </ul>
            </xsl:when>
          </xsl:choose>


          <xsl:variable name='cols' select='$result/columns'/>
          
          <table class='sql'>
            <xsl:for-each select='$cols/list-item'>
              <th><xsl:value-of select='text()'/></th>
            </xsl:for-each>
            <xsl:for-each select='$result/data/list-item'>
              <tr>
                <xsl:for-each select='list-item'>
                  <td><xsl:value-of select='text()'/></td>
                </xsl:for-each>
              </tr>
            </xsl:for-each>
          </table>

        </xsl:if>


        <xsl:call-template name='adm-menu'/>


      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>

