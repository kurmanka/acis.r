<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"    
    exclude-result-prefixes="exsl xsl html acis"
    version="1.0">

  <xsl:import href='../page-universal.xsl' />
  <xsl:import href='../forms.xsl'/>

  <!--   u t i l i t y   t e m p l a t e   -->
  <xsl:template name='institution-description'>
    <xsl:param name='full'/>
          <span class='title'>
            <xsl:value-of select='name'/>
          </span>
          <ul class='details'>
            <xsl:if test='name-english/text()'>
              <li>
                <xsl:text>English name: </xsl:text>
                <span class='title'>
                  <xsl:value-of select='name-english/text()'/>
                </span>
              </li>
            </xsl:if>
            <xsl:if test='name_en/text()'>
              <li>
                <xsl:text>English name: </xsl:text>
                <span class='title'>
                  <xsl:value-of select='name_en/text()'/>
                </span>
              </li>
            </xsl:if>
            <xsl:if test='location/text()'>
              <li>
                <xsl:text>located in: </xsl:text>
                <xsl:value-of select='location/text()'/>
              </li>
            </xsl:if>
            <xsl:if test='homepage'>
              <li>
                <a href='{homepage}' title='External link'>
                  <xsl:text>website</xsl:text>
                </a>
              </li>
            </xsl:if>
            <xsl:if test='email/text()'>
              <li>
                <xsl:text>email: </xsl:text>
                <xsl:value-of select='email/text()'/>
              </li>
            </xsl:if>
            <xsl:if test='$full = "yes"'>
              <xsl:if test='not(location/text()) and postal/text()'>
                <li>
                  <xsl:text>postal address: </xsl:text>
                  <xsl:value-of select='postal/text()'/>
                </li>
              </xsl:if>
              <xsl:if test='phone/text()'>
                <li>
                  <xsl:text>phone: </xsl:text>
                  <xsl:value-of select='phone/text()'/>
                </li>
              </xsl:if>
              <xsl:if test='fax/text()'>
                <li>
                  <xsl:text>fax: </xsl:text>
                  <xsl:value-of select='fax/text()'/>
                </li>
              </xsl:if>
              <xsl:if test='submitted-by/text()'>
                <li>
                  <xsl:text>submitted by: </xsl:text>
                  <xsl:value-of select='submitted-by/text()'/>
                </li>
              </xsl:if>
            </xsl:if>
          </ul>
  </xsl:template>

  <xsl:template name='institutions-table-without-shares'>
    <!-- assuming form and table around this template -->
    <xsl:param name='list'/>
    <xsl:param name='full' select='"yes"'/>

    <xsl:for-each select='$list/list-item' xml:space='preserve'>
      <xsl:variable name='alter' xml:space='default'>
        <xsl:if test='(position()) mod 2'>
          <xsl:text> alternate</xsl:text>
        </xsl:if>
      </xsl:variable>      
      <xsl:variable name='rownum' select='position()-1'/>

      <tr class='{$alter}'>
        <td title='Is that your institution?' class='action'>
          <input type='submit'           name='remove{$rownum}'  value='remove' />
          <xsl:if test='id/text()'>
            <input type='hidden'         name='id{$rownum}'      value='{id}'/>
          </xsl:if>
          <xsl:if test='not(id/text())'>
            <input type='hidden'         name='name{$rownum}'    value='{name}'/>
          </xsl:if>
        </td>
        <td class='description'>          
          <xsl:call-template name='institution-description'>
            <xsl:with-param name='full' select='$full'/>
          </xsl:call-template>
        </td>
      </tr>
    </xsl:for-each>
  </xsl:template>



  <xsl:template name='institutions-table-with-shares'>
    <!-- assuming form and table around this template -->
    <xsl:param name='list'/>
    <xsl:param name='full' select='"yes"'/>

<!-- 2011-12-16, iku:

If a form has several submit buttons, and at least one text input
field, it is a problem. User may be entering text into an input field,
and then hit Enter button on his keyboard. That would submit the form
with the first or random submit button activated. As if he has clicked
on it.

This is why the remove buttons in the form below are so-called
"push-buttons", not submit buttons. <input type='button' ... /> But we
need them to submit the form - i.e. delete the institution, when
clicked.

For this we employ javascript here. We use jQuery to attach the onclick
handler - buttonClick function - to these buttons.

The buttonClick function uses the "spare" input (type=hidden), to pass
the needed value back to the server. And it submits the form.

Initially, I hoped that simple trick of 

    onclick="this.type='submit';" 

would work, but it only works in non-IE browsers. IE wouldn't let you
change the type of input under no conditions (at least, that is how it
looks to me).

All this also means that the form would not work with javascript disabled.

-->


    <acis:script-onload>
      $('input.[type="button"]').click( buttonClick );
    </acis:script-onload>

    <script>
function buttonClick () {
    var f = document.forms[0];
    var name = $(this).attr('name');
    var value = $(this).attr('value');
    $( f.spare ).attr( 'name', name ).attr( 'value', value );
    f.submit();
    return false;
}


//  These are the initial attempts of a quickfix:
/*
    this.type='submit';  // works in Chrome and FF
    $(this).attr('type', 'submit'); // does not work in Chrome, says type can't be changed
    return true;
*/
    </script>

    <noscript>
<p>This form wouldn't work correctly without javascript. Sorry.</p>
    </noscript>

    <input type='hidden' name='spare' value='' />


    <xsl:for-each select='$list/list-item' xml:space='preserve'>
      <xsl:variable name='alter' xml:space='default'>
        <xsl:if test='(position()) mod 2'>
          <xsl:text> alternate</xsl:text>
        </xsl:if>
      </xsl:variable>      
      <xsl:variable name='rownum' select='position()-1'/>


      <tr class='{$alter}'>
        <td title='Is that your institution?' class='action'>
          <input type='button'           name='remove{$rownum}'  value='remove' />
          <xsl:if test='id/text()'>
            <input type='hidden'         name='id{$rownum}'      value='{id}'/>
          </xsl:if>
          <xsl:if test='not(id/text())'>
            <input type='hidden'         name='name{$rownum}'    value='{name}'/>
          </xsl:if>
        </td>
        <td class='description'>          
          <xsl:call-template name='institution-description'>
            <xsl:with-param name='full' select='$full'/>
          </xsl:call-template>
        </td>
        <td class='share' style='text-align:center'>
          <input type='text'             name='share{$rownum}'   value='{share}' size='2'/>
        </td>
      </tr>
    </xsl:for-each>
  </xsl:template>



  <xsl:template name='show-institutions'>
    <xsl:param name='list'/>
    <xsl:param name='mode'/>
    <xsl:param name='full' select='"yes"'/>
    <xsl:for-each select='$list/list-item' xml:space='preserve'>
      <xsl:variable name='alter' xml:space='default'>
        <xsl:if test='(position()+1) mod 2'>
          <xsl:text> alternate</xsl:text>
        </xsl:if>
      </xsl:variable>      
      <acis:form screen='@affiliations'
                 xsl:use-attribute-sets='form' 
                 class='narrow institution{$alter} aff-mode-{$mode}'>        
        <div class='actionButton'
             title='Is that your institution?'>
          <input type='submit' 
                 name='{$mode}'
                 class=''
                 value='{$mode}'/>
          <input type='hidden' 
                 name='id'
                 value='{id}'/>
          <xsl:if test='not(id/text())'>
            <input type='hidden'
                   name='name'
                   value='{name}'/>
          </xsl:if>
        </div>        
        <div class='description'>          
          <span class='title'>
            <xsl:value-of select='name'/>
          </span>
          <ul class='details'>
            <xsl:if test='name-english/text()'>
              <li>
                <xsl:text>English name: </xsl:text>
                <span class='title'>
                  <xsl:value-of select='name-english/text()'/>
                </span>
              </li>
            </xsl:if>
            <xsl:if test='name_en/text()'>
              <li>
                <xsl:text>English name: </xsl:text>
                <span class='title'>
                  <xsl:value-of select='name_en/text()'/>
                </span>
              </li>
            </xsl:if>
            <xsl:if test='location/text()'>
              <li>
                <xsl:text>located in: </xsl:text>
                <xsl:value-of select='location/text()'/>
              </li>
            </xsl:if>
            <xsl:if test='homepage'>
              <li>
                <a href='{homepage}' title='External link'>
                  <xsl:text>website</xsl:text>
                </a>
              </li>
            </xsl:if>
            <xsl:if test='email/text()'>
              <li>
                <xsl:text>email: </xsl:text>
                <xsl:value-of select='email/text()'/>
              </li>
            </xsl:if>
            <xsl:if test='$full = "yes"'>
              <xsl:if test='not(location/text()) and postal/text()'>
                <li>
                  <xsl:text>postal address: </xsl:text>
                  <xsl:value-of select='postal/text()'/>
                </li>
              </xsl:if>
              <xsl:if test='phone/text()'>
                <li>
                  <xsl:text>phone: </xsl:text>
                  <xsl:value-of select='phone/text()'/>
                </li>
              </xsl:if>
              <xsl:if test='fax/text()'>
                <li>
                  <xsl:text>fax: </xsl:text>
                  <xsl:value-of select='fax/text()'/>
                </li>
              </xsl:if>
              <xsl:if test='submitted-by/text()'>
                <li>
                  <xsl:text>submitted by: </xsl:text>
                  <xsl:value-of select='submitted-by/text()'/>
                </li>
              </xsl:if>
            </xsl:if>
            <!-- XXX not all fields show here -->            
          </ul>
        </div>
      </acis:form>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name='submit-invitation'>
    <h2 id='submit'>
      <xsl:text>Cannot find your institution?</xsl:text>
    </h2>    
    <p style='margin-bottom: 2em;'>
      <a ref='@new-institution'>
        <xsl:text>Submit a new institution record</xsl:text>
      </a>
      <xsl:text> to </xsl:text>
      <acis:phrase ref='affiliations-submit-to'/>
    </p>    
  </xsl:template>
  <xsl:variable name='to-go-options'>
    <acis:op>
      <a ref='@affiliations'>
        <xsl:text>back to affiliations</xsl:text>
      </a>
    </acis:op>
    <acis:root/>
  </xsl:variable>
  <xsl:variable name='next-registration-step'>
    <a ref='@research'>
      <xsl:text>next registration step: research</xsl:text>
    </a>
  </xsl:variable>

  <xsl:template name='additional-page-navigation'>
    <xsl:call-template name='link-filter'>
      <xsl:with-param name='content'>        
        <xsl:text>
        </xsl:text>    
        <p class='menu submenu'>
          <span class='head here'>            
            <xsl:text>&#160;</xsl:text>            
            <xsl:choose>
              <xsl:when test='$current-screen-id = "affiliations"'>                
                <b>
                  <xsl:text>Affiliations:</xsl:text>
                </b>                
              </xsl:when>
              <xsl:otherwise>                
                <a ref='@affiliations'>
                  <xsl:text>Affiliations:</xsl:text>
                </a>                
              </xsl:otherwise>
            </xsl:choose>            
            <xsl:text>&#160;</xsl:text>
          </span>          
          <span class='body'>            
            <acis:hl screen='affiliations/search'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@affiliations/search'>
                <xsl:text>search</xsl:text>
              </a>
              <xsl:text>&#160;</xsl:text>
            </acis:hl>            
            <acis:hl screen='new-institution'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@new-institution'> 
                <xsl:text>submit&#160;institution</xsl:text>
              </a>
              <xsl:text>&#160;</xsl:text>
            </acis:hl>          
          </span>          
        </p>
        <xsl:text> 
        </xsl:text>        
      </xsl:with-param>
    </xsl:call-template>    
  </xsl:template>  

</xsl:stylesheet>