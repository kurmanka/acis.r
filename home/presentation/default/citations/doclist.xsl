<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes='exsl xml'
    version="1.0">
 
  <xsl:import href='general.xsl'/>

  <xsl:variable name='current-screen-id'>citations/doclist</xsl:variable>
  <xsl:variable name='list' select='$response-data/doclist'/>
  <xsl:variable name='identified-num' select='number($response-data/identified-number)'/>
  <xsl:variable name='potent-new-num' select='number($response-data/potential-new-number)'/>
  
  <xsl:template name='doclisttable'>
    <xsl:param name='max' select='count($list/list-item)'/>
    <style>
      td.link span.a,
      td.link a:link,
      td.link a:visited {
         width: 100%; 
         padding: 1ex 2ex;
      } 
      td.link a:hover { background: #f4f4f4; }
      tr.secondary th { font-weight: normal; }
    </style>

    <table>
      <tr>
        <th rowspan='2' align='left'
            valign='bottom'
            >document</th>
        <th colspan='3'>citations</th>
      </tr>
      <tr class='secondary'>
        <th>identified</th>
        <th>new</th>
        <th>old</th>
      </tr>
      <xsl:for-each select='$list/list-item[position()&lt;=$max]'>
        <tr>
          <td>
            <big><xsl:value-of select='doc/title'/></big>
            <br/><small><a href='{doc/url-about}'>details</a></small>
          </td>
          <td class='link' valign='top'>
            <xsl:choose> 
              <xsl:when test='number(id/text())'>
                <a ref='@citations/identified/{doc/sid}'><xsl:value-of select='id'/></a>
              </xsl:when>
              <xsl:otherwise>
<!--                <span class='a'><xsl:value-of select='id'/></span> -->
              </xsl:otherwise>
            </xsl:choose>
          </td>
          <td class='link' valign='top' style='xbackground:#{similarity/text()}0000;'
              >
            <xsl:choose>
              <xsl:when test='number(new/text())'>
                <a ref='@citations/potential/{doc/sid}'><xsl:value-of select='new'/></a> 
              </xsl:when>
              <xsl:otherwise>
              </xsl:otherwise>
            </xsl:choose>
          </td>
          <td class='link' valign='top'>
            <xsl:choose>
              <xsl:when test='number(old/text())'>
                <a ref='@citations/potential/{doc/sid}?old=y'><xsl:value-of select='old'/></a> 
              </xsl:when>
              <xsl:otherwise>
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
      </xsl:for-each>

    </table>
  </xsl:template>


  <xsl:template name='doclist'>
    <h1>Citations for your documents</h1><!-- XXX fix grammar: plural ending -->
    <xsl:choose>
      <xsl:when test='$list/list-item'>
        
        <p>Overall, you have <xsl:value-of
        select='$identified-num'/> identified citations and
        <xsl:value-of select='$potent-new-num'/> new unique
        potential citations.</p><!-- XXX fix grammar -->

        <xsl:call-template name='doclisttable'/>
      </xsl:when>
      <xsl:otherwise>
        <p>You have no documents in your <a
        ref='@research/identified'>research profile</a>,
        sorry.</p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match='/'>
    <xsl:call-template name='cit-page'>
      <xsl:with-param name='title'>citations for your documents</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='doclist'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>