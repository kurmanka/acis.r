<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  <xsl:import href='../forms.xsl'/>
  
  
  <xsl:variable name='current-screen-id'>personal-name</xsl:variable>

  
  <xsl:template name='the-name-details' xml:space='default'>
    
    <h1>Name details</h1>
    
    <xsl:call-template name='show-status'/>
    

    <xsl:call-template name='fieldset'>
      <xsl:with-param name='content'>
        <acis:form xsl:use-attribute-sets='form' action='{$base-url}/name!{$session-id}'>

          <p>
            <label for='full'>Full name, required.  Use your native language.</label>
            <br />
            <acis:input name='full-name' id='full' size='50'/>
          </p>
          <p>
            <label for='fn'>First name, required. No titles:</label><br/>
            <acis:input name='first-name' id='fn' size='50'/>
            <br />
            <label for='mn'>Middle name:</label><br />
            <acis:input name='middle-name' id='mn' size='50'/>
            <br />
            <label for='ln'>Last name, required:</label><br />
            <acis:input name='last-name' id='ln' size='50'/>
            <br />
            <label for='ns'>Name suffix, if any (III, Jr., no titles):</label><br />
            <acis:select name='name-suffix' class="suffix" id='ns' size='1'>
              <option selected='' value=''>- none -</option>
              <option>Sr.</option>
              <option>Jr.</option>
              <option>II</option>
              <option>III</option>
              <option>IV</option>
              <option>V</option>
            </acis:select>
          </p>
          
          <p>
            <label for='nlat'>Name in pure English alphabet letters.  Required if
            your name has at least one non-English character.</label>
            <br />
            <acis:input name='name-latin' id='nlat' size='50'/>
          </p>


          <p id='variations'>
            
            <label for='nvar'>The variations of your name, one per
            line.  We will use them to find your works in our database
            automatically. We cannot find works where your name
            appears differently than below. Include initials or middle
            name if you published with such wording of your
            name.</label>

          </p>
          
          <table>
            <tr>
              <td>
                <acis:textarea name='name-variations' id='nvar' cols='40' rows='12'/>                
              </td>
              <td valign='top'>
                <xsl:text>&#160; </xsl:text>                
                <input id='suggest' type='button'
                       style='display: none;'
                       onclick='suggest_variations();'
                       title='based on the first, middle and last names above'
                       class='significant'
                       value='Suggest variations'/>
                
                <br />
                <xsl:text>&#160; </xsl:text>                
                <input id='reset_nvar' type='button'
                       onclick='reset_variations();'
                       style='display: none; margin-top: 4px;'
                       class='significant'
                       title='return variations to the initial value'
                       value='UNDO' />

                <script src="name.js"/>

                <acis:script-onload>
                  <![CDATA[
                           nvar = getRef( "nvar" );
                           if ( nvar ) {
                             if (nvar.value ) {
                                initial_variations = nvar.value;
                               if ( initial_variations ) {
                                 if ( initial_variations.split ) {
                                   initial_list = initial_variations.split( /\n\r?|\r\n?/ );
                                   show( "suggest" );
                                 }
                               }
                             }
                           }   
                  ]]>
                </acis:script-onload>
                
              </td>
            </tr>
          </table>
        
          

      <xsl:variable name='screen-back' select='$response-data/screen-back/text()'/>
      <xsl:if test='string-length( $screen-back )'>
        <input type='hidden' name='back' value='{$screen-back}' />
      </xsl:if>
        
      
      <p xml:space='default'>
        <input type='submit' class='important'
               value='SAVE AND RETURN TO MENU' name='continue' >
          <xsl:if test='$screen-back'>
            <xsl:if test='starts-with( $screen-back, "research" )'>
              <xsl:attribute name='value'>SAVE AND GO BACK TO RESEARCH</xsl:attribute>
            </xsl:if>
            <xsl:if test='$screen-back = "research/autoupdate"'>
              <xsl:attribute name='value'>
              SAVE AND RETURN TO RESEARCH AUTOUPDATE</xsl:attribute>
            </xsl:if>
          </xsl:if>
        </input>
        
        <xsl:if test='not( string-length( $screen-back ) )'>
          <xsl:text>&#160; </xsl:text>
          <input type='submit' class='important' name='gotoresearch'
                 value='SAVE AND GO TO RESEARCH' />
        </xsl:if>
      </p>
    </acis:form>      

  </xsl:with-param>
</xsl:call-template>
</xsl:template>
  

  
  
  
  <xsl:variable name='to-go-options'>
    <xsl:if test='$session-type = "new-user"'>
      <acis:op>
        <a ref='@affiliations'>affiliations profile</a>
      </acis:op>
    </xsl:if>
    <acis:op>
      <a ref='@research'>research profile</a>
    </acis:op>
    <acis:root/>
  </xsl:variable>
  
  
  
  <!--    t h e   p a g e  -->
  
  <xsl:template match='/data'>
    
    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>Name details</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='the-name-details'/>
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template>
  
</xsl:stylesheet>





