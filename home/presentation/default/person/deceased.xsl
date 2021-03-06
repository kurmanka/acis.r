<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  <xsl:import href='../forms.xsl'/>
  
  <xsl:variable name='current-screen-id'>personal-deceased</xsl:variable>
  
  <xsl:template name='deceased-details' xml:space='default'>
    
    <h1>Deceased</h1>
    
    <xsl:call-template name='show-status'/>
    
    <xsl:call-template name='fieldset'>
      <xsl:with-param name='content'>
        <acis:form xsl:use-attribute-sets='form' >

          <script src='deceased.js'/>
          <p>
            <acis:input type='checkbox' name='dead' id='dead' onclick='dead_checkbox_click(this)'/>
            <label for='dead'>the person is deceased</label>
            <br />

            <table class='date'>
              <caption>
                <label for='date-y'>Date of death</label>
              </caption>
              <tr><th>year</th><th>month</th><th>day</th></tr>
              <tr>
                <td>
                  <acis:input name='date-y' id='date-y' size='4'/>
                </td>
                <td>

            <acis:select name='date-m' id='date-m'>
              <option value=''>-</option>
              <option name='January' value='01'>January</option>
              <option name='February' value='02'>February</option>
              <option name='March' value='03'>March</option>
              <option name='April' value='04'>April</option>
              <option name='May' value='05'>May</option>
              <option name='June' value='06'>June</option>
              <option name='July' value='07'>July</option>
              <option name='August' value='08'>August</option>
              <option name='September' value='09'>September</option>
              <option name='October' value='10'>October</option>
              <option name='November' value='11'>November</option>
              <option name='December' value='12'>December</option>
            </acis:select>
                </td>
                <td>
                  <acis:input name='date-d' id='date-d' size='2'/>
                </td>
              </tr>
            </table>
          </p>
          
          <p xml:space='default'>
            <input type='submit' class='important'
                   value='SAVE CHANGES' name='continue' />
          </p>
        </acis:form>      
        
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match='/data'>
    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>Deceased</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='deceased-details'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>





