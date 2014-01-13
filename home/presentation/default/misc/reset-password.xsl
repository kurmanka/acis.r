<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='../page.xsl'/>
  
  <xsl:template match='/'>
    <xsl:call-template name='page'>
      <xsl:with-param name='title'>
        <xsl:text>reset password</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='content'>        
        <h1>
          <xsl:text>Reset Password</xsl:text>
        </h1>
        
        <xsl:call-template name='show-status'/>

        <xsl:if test='$success'>

          <acis:form xsl:use-attribute-sets='form' name='f' class='important'>
          
          <xsl:call-template name='fieldset'>
            <xsl:with-param name='content'>
              <h2>New password</h2>
              
              <table>
                <tr>
                  <td>
                    <label for='pass-in'>Password, required:</label>
                  </td>
                  <td>
                   <acis:input name='pass' id='pass-in' type='password'>
                    <acis:hint side=''>Minimum 6 digits or english letters.</acis:hint>
                    <acis:check nonempty=''/>
                    <acis:name>password</acis:name>
                   </acis:input>
                  </td>
                </tr>
                <tr>
                  <td>
                    <label for='pass-conf-in'>Password confirmation, required:</label>
                  </td>
                  <td>
                    <acis:input class='edit' name='pass-confirm' id='pass-conf-in'
                            type='password'>
                      <acis:hint side=''>Repeat the password.</acis:hint>
                      <acis:check nonempty=''/>
                      <acis:name>password confirmation</acis:name>
                    </acis:input>
                  </td>
                </tr>
                
                <tr>
                  <td></td>
                  <td>
                    <input type='submit' class='important' 
                      value='Done' />
                    <acis:script-onload>
                      document.f.pass.focus();
                    </acis:script-onload>
                  </td>
                </tr>
                
              </table>

            </xsl:with-param>
          </xsl:call-template>

          </acis:form>

        </xsl:if>
        
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
