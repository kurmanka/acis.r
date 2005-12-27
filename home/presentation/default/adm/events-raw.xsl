<xsl:stylesheet
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:exsl="http://exslt.org/common"
 exclude-result-prefixes='exsl'
 version="1.0">

  <xsl:import href='index.xsl'/>

  <xsl:variable name='columns'>
    <c name='date'>Date</c>
    <c name='type'>Type</c>
    <c name='class'>Class</c>
    <c name='action'>Action</c>
    <c name='descr'>Description</c>
    <c name='data'>Data</c>
    <c name='chain'>Session</c>
    <c name='startend'>S/E</c>
  </xsl:variable>

  <xsl:template match='/'>

    <xsl:variable name='amount' select='count(//events/list-item)'/>


    <xsl:call-template name='page'>
      <xsl:with-param name='title'>recent events</xsl:with-param>
      <xsl:with-param name='content'>

        <h1>Recent events</h1>

        <xsl:call-template name='show-status'/>

        <xsl:choose>
          <xsl:when test='$amount'>
            <table>
              <tr>
                <xsl:for-each select='exsl:node-set($columns)/c'>
                  <th><xsl:value-of select='text()'/></th>
                </xsl:for-each>
              </tr>

              <xsl:for-each select='//events/list-item'>
                <xsl:variable name='e' select='.'/>
                <tr>
                  <xsl:for-each select='exsl:node-set($columns)/c'>
                    <td><xsl:value-of select='$e/*[name()=current()/@name]/text()'/></td>
                  </xsl:for-each>

                </tr>
              </xsl:for-each>
            </table>
          </xsl:when>
          <xsl:otherwise>
            <p>no events</p>
          </xsl:otherwise>
        </xsl:choose>


        <xsl:call-template name='adm-menu'/>


      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>

      