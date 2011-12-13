<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"    
    exclude-result-prefixes="exsl xsl html acis"
    version="1.0">


  <xsl:template name='table-resources-for-addition'>
    <xsl:param name='list'/>
    <xsl:param name='role'/>
    <xsl:param name='status'/>
    <xsl:param name='mode'/>
    <xsl:param name='from' select='"0"'/>
    <xsl:param name='to'   select='"1024"'/> <!-- XXX max items per list -->
    

    <tr class='here'>
      <th width='6%'>add</th>
      <th class='desc'>item description</th>
    </tr>


    
    <xsl:for-each select='$list/list-item[id and title 
                  and (@pos &gt;= $from) 
                  and (@pos &lt;= $to) ]'>
      <xsl:variable name="sid" select='generate-id(.)'/>
      <xsl:variable name="id" select='id'/>

      <xsl:variable name='role' xml:space='default'>
        <xsl:choose>
          <xsl:when test='role/text()'>
            <xsl:value-of select='role/text()'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='$role'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <xsl:variable name='alternate'
         ><xsl:if test='position() mod 2' 
         > alternate</xsl:if
      ></xsl:variable>

      <xsl:variable name='checked' xml:space='default'>
        <xsl:choose>
          <xsl:when test='status'>
            <xsl:value-of select='status/text() = "1"'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='$status/text() = "1"'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
          

      <xsl:text>
      </xsl:text>
      
      <tr class='resource{$alternate}' id='row_{$sid}'>
        <xsl:if test='$checked = "true"'>
          <xsl:attribute name='class'
>resource<xsl:value-of select='$alternate'/> select</xsl:attribute>
        </xsl:if>
        <td class='checkbutton' width='6%' valign='top' >

          <input type='checkbox' name='add_{$sid}' id='add_{$sid}' 
                 value='1'>
            <xsl:if test='$checked = "true"'>
              <xsl:attribute name='checked'/>
            </xsl:if>
          </input>
            
          <xsl:text>
          </xsl:text>
      
          <input type='hidden' name='id_{$sid}' value='{$id}'/>

          <xsl:text>
          </xsl:text>

        </td>

      <xsl:text>
      </xsl:text>
      

        <td class='description'>
      <xsl:text>
      </xsl:text>
      
          <xsl:call-template name='present-resource'>
            <xsl:with-param name='resource' select='.'/>
            <xsl:with-param name='for' select='concat( "add_", $sid )' />
          </xsl:call-template>
          <br />

      <xsl:text>
      </xsl:text>
      

        <xsl:variable name='object-type' select='type/text()'/>
        <xsl:variable name="config-this-type" 
                      select='$config-object-types/*[name()=$object-type]'/>
        
        <!-- now what is left is the role or the role choice -->


        <xsl:if test='string-length( $role )'>
          <small title='your role in creation of that work'
            ><span class='assumed_role'
            >With role: <span class='role' id='assumed_{$sid}'><xsl:value-of
          select='$role'/></span></span></small>

      <xsl:text>
      </xsl:text>
      
        <xsl:choose xml:space='default'>
          <xsl:when test='count( $config-this-type/roles/list-item ) = 1
                    and ( $config-this-type/roles/list-item[text()=$role] )'>

            <input type='hidden' name='role_{$sid}' value='{$role}'/>

          </xsl:when>
          <xsl:otherwise>

          <xsl:text> </xsl:text>
          <small id='button_{$sid}'
            >(<a href=
'javascript:hide("button_{$sid}");hide("assumed_{$sid}");show("role_{$sid}");'
            class='change_role_button int'
            no-form-check='1'
            title='choose another role'
            >choose</a>)<!-- XXX: shouln't i replace it with an image? -->
          </small>

      <xsl:text>
      </xsl:text>

          <select 
            name='role_{$sid}' id='role_{$sid}' size='1' 
            style='display:none' class='to_be_hidden'
            onchange='javascript:document.getElementById("add_{$sid}").checked=true;'
            >
            <xsl:if test='not( $config-this-type/roles/list-item[text()=$role] )'>
              <xsl:message>Role '<xsl:value-of select='$role'/>' is not 
              a known role for <xsl:value-of select='type'/> type of objects.</xsl:message>
              <option value='{$role}' selected='1'
              ><xsl:value-of select='$role'/></option>
              <!-- XXX: I18N dependency on configuration -->
            </xsl:if>

            <xsl:for-each select="$config-this-type/roles/list-item">
              <xsl:text>
              </xsl:text>
              <option label='{text()}' value='{text()}'
                ><xsl:if test="text() = $role"
                ><xsl:attribute name='selected' /></xsl:if
                ><xsl:value-of select='text()'
                /><!-- XXX: should be replaced with presenter-specific labels 
                --></option>
            </xsl:for-each>
          </select>

          </xsl:otherwise>
          </xsl:choose>

        </xsl:if>


        <xsl:if test='not( string-length( $role ) )'>
        <!-- no predefined role for this object or nothing to chose from -->

          <xsl:choose xml:space='default'>

            <xsl:when test='count( $config-this-type/roles/list-item ) &gt; 1'>
              <!-- there is something to chose from -->

          <small title='your role in creation of that work'
            ><span class='assumed_role'
            >With role: 

          <select name='role_{$sid}' size='1'>
            <xsl:for-each select="$config-this-type/roles/list-item">
              <option label='{text()}' value='{text()}'
                      ><xsl:if test='@pos="0"'><xsl:attribute
                      name='selected'/></xsl:if
                      ><xsl:value-of select='text()'
              /><!-- XXX: I18N should be replaced with presenter-specific labels 
              --></option>
            </xsl:for-each>
          </select>
          </span>
                </small>

          </xsl:when><xsl:otherwise>
          <!-- only one role exists for this object type, or none at all -->

          <xsl:variable name='role2' xml:space='default'>
            <xsl:choose>
              <xsl:when test='count( $config-this-type/roles/list-item ) = 1'>
                <xsl:value-of
                 select='$config-this-type/roles/list-item/text()'/>
              </xsl:when>
              <xsl:otherwise>undefined</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <small title='your role in creation of that work'
                       ><span class='assumed_role'
                       >With role: <span class='role' id='assumed_{$sid}'
          ><xsl:value-of select='$role2'/></span></span></small>

      <xsl:text>
      </xsl:text>
      
          <input type='hidden' name='role_{$sid}' value='{$role2}'/>

          </xsl:otherwise></xsl:choose>

        </xsl:if>

      <xsl:text>
      </xsl:text>
      
    </td>
    </tr>

      <xsl:text>
      </xsl:text>
      

    </xsl:for-each>
  </xsl:template>




   
</xsl:stylesheet>

