<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='main.xsl' />
  

  <xsl:variable name='parents'>
    <par id='research/main'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>research/identified</xsl:variable>


  <!--    v a r i a b l e s    -->

  <xsl:variable name='current'       select='$contributions/accepted'/>

  <xsl:variable name='config-object-types' select='$contributions/config/types'/> 



  <xsl:template name='table-resources-for-editing'>
    <xsl:param name='list'/>

    <tr class='here'>

      <th width='6%'>delete</th>
      <th class='desc'> item description </th>

    </tr>
    
    <xsl:for-each select='$list/list-item[id and title]' xml:space='preserve'>
      <xsl:variable name="sid" select='generate-id(.)'/>
      <xsl:variable name="id" select='id'/>
      <xsl:variable name='role' select='role/text()'/>

      <xsl:variable name='alternate'><xsl:if test='position() mod 2'> alternate</xsl:if></xsl:variable>
      <tr class='resource{$alternate}' id='row_{$sid}'>
        
        <td class='checkbutton' width='6%' valign='top'>
          
          <span class='checkbutton'>

            <xsl:if test='string-length( $role )' xml:space='default'>

              <input type='checkbox' name='remove_{$sid}' id='remove_{$sid}' 
                     onblur_after='item_checkbox_blur("row_{$sid}",this);'
                   onfocus_after='if(item_label_click){{this.blur();}};item_label_click=false;'
                     value='1'>
                <xsl:if test='contains( $user-agent, "Gecko/" )'>
                  <xsl:attribute name='onchange'>item_checkbox_changed("row_<xsl:value-of select='$sid'/>",this);</xsl:attribute>
                  <xsl:attribute name='onblur_after'/>
                </xsl:if>
              </input>

              <xsl:text>
              </xsl:text>

            </xsl:if>
            <input type='hidden' name='id_{$sid}' value='{$id}'/>
          </span>


        <xsl:variable name="config-this-type" 
                      select='$config-object-types/*[name()=current()/type]'/>

        <xsl:choose xml:space='default'>
          <xsl:when test='count( $config-this-type/roles/list-item ) > 1'>

          <span class='role' title='your role in creation of that work'
          >

          <select name='role_{$sid}' id='role_{$sid}' size='1'
	    onchange='javascript:getRef("submitB").value="REMOVE CHECKED ITEMS / SAVE CHANGES"'>
            <xsl:if test='not( $config-this-type/roles/list-item[text()=$role] )'>
              <xsl:message>Role '<xsl:value-of select='$role'/>' is not a known role for <xsl:value-of select='type'/> type of objects.</xsl:message>
              <option value='{$role}' selected='1'><xsl:value-of select='$role'/></option>
            </xsl:if>
            <xsl:for-each select="$config-this-type/roles/list-item">
              <option label='{text()}' value='{text()}'
                ><xsl:if test="text() = $role"
                ><xsl:attribute name='selected'>2</xsl:attribute></xsl:if
                ><xsl:value-of select='text()'
                /><!-- XXX: I18N should be replaced with presenter-specific labels 
                --></option>
            </xsl:for-each>
          </select>
        </span>

          </xsl:when>
          <xsl:when test='role/text() = $default-role'/>
          <xsl:otherwise xml:space='default'>

            <br/>
            
            <span class='role' title='your role in creation of that work'
                  >(<xsl:value-of select='$role'/>)</span>

          </xsl:otherwise>
        </xsl:choose>



        </td>

        <td class='description'>

          <xsl:call-template name='present-resource' xml:space='default'>
            <xsl:with-param name='resource' select='.'/>
            <xsl:with-param name='for' select='concat( "remove_", $sid )' />
            <xsl:with-param name='label-onclick'
                            >item_label_click=true;</xsl:with-param>
          </xsl:call-template>

    </td>
    </tr>

    </xsl:for-each>
  </xsl:template>





  <xsl:template name='research-identified'>


    <h1>Research profile: your identified works</h1>

    <xsl:call-template name='show-status'/>

    <xsl:variable name='current-count' 
                  select='count( $current/list-item )'/>

    <xsl:choose>
      <xsl:when test='$current/list-item'>

        <form screen='@research/identified' 
              xsl:use-attribute-sets='form'>

          <xsl:choose>
          <xsl:when test='$current-count &gt; 1'>
            <p>Here are the <xsl:value-of select='$current-count'/>
            works, that you claim you have authored:</p>
          </xsl:when>
          <xsl:when test='count( $current/list-item ) = 1'>
            <p>Here is the work, that you claim you have authored:</p>
          </xsl:when>
          </xsl:choose>
          
          <table class='resources'>
            <xsl:call-template name='table-resources-for-editing'>
              <xsl:with-param name='list' select='$current'/>
            </xsl:call-template>
          </table>
          
          <p>

            <input type='hidden' name='mode' value='edit'/>
            <input type='submit'
	           id='submitB'
                   name='continue'
                   class='important'
                   value='REMOVE CHECKED ITEMS' 
                   />
          </p>

          <phrase ref='research-identified-after-save-changes-button'/>


        </form>
      </xsl:when>
    
      <xsl:otherwise>
        <p>At this moment, there are no works in your research profile.</p>
      </xsl:otherwise>
  
    </xsl:choose>
    


  </xsl:template>




  <!--   n o w   t h e   p a g e   t e m p l a t e    -->

  
  <xsl:template match='/data'>

    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>your works</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='research-identified'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

    

</xsl:stylesheet>