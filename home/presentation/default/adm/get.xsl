<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis date"
    xmlns:date="http://exslt.org/dates-and-times"
    version="1.0">  

  <!--   This file is part of the ACIS presentation template set.   -->


  <xsl:import href='index.xsl'/>



  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>Logs:
      	  <xsl:value-of select='$form-input/name'/>
      </xsl:with-param>
      
      <xsl:with-param name='content'>

        <xsl:choose>
          <xsl:when test='//nosuchrecord'>
            <h1>Record not found</h1>
            
            <p><big><xsl:value-of select='$form-input/id'/></big></p>
                        
          </xsl:when>
          <xsl:when test='$form-input/name/text()'>
            
            <h1>Log <xsl:value-of select='$form-input/id'/></h1>
            
            <xsl:call-template name='menu'/>
            
          </xsl:when>
          <xsl:otherwise>
            
            
          </xsl:otherwise>
        </xsl:choose>
        
        <xsl:text> </xsl:text>

        <acis:form class='xxx-wide'>
          <h1>See the logs</h1>
          
          <p>
            <label for='col'>collection: </label>
            <input type='text' id='col' name='col' value='{$form-input/col}' size='12'/>
            <br/>
            
            <label for='id'>id: </label>
            <input type='text' id='id' name='id' value='{$form-input/id}' size='60'/>
            <br/>

            <select name='op' size='1'>
              <option>record</option>
              <option selected=''>history</option>
              <option value='ardb'>ARDB</option>
            </select>
            
            <xsl:text> </xsl:text>

            <br/>
            <input type='submit' value='GO!' />
          </p>
          
        </acis:form>
        
        <xsl:call-template name='adm-menu'/>
        
      </xsl:with-param>
      
    </xsl:call-template>
</xsl:template>


  <xsl:template match='*[list-item]' mode='dump'>
    <p><xsl:value-of select='name()'/></p>
    <table class='list'>
      <xsl:for-each select='list-item'>
        <tr><td><xsl:apply-templates mode='dump'/></td></tr>
      </xsl:for-each>
    </table>
  </xsl:template>


  <xsl:template match='*' mode='dump'>
    <xsl:choose>
      
      <xsl:when test='*'>
        <p><xsl:value-of select='name()'/></p>
        <ul>
          <xsl:for-each select='*'>
            <li><xsl:apply-templates select='current()' mode='dump'/></li>
          </xsl:for-each>
        </ul>
      </xsl:when>

      <xsl:otherwise>
        <p><xsl:value-of select='name()'/>: <xsl:value-of select='text()'/></p>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>



</xsl:stylesheet>