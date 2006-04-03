<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='main.xsl' />
  <xsl:import href='../../widgets.xsl' />
  

  <xsl:variable name='parents'>
    <par id='research/main'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>research/refused</xsl:variable>


  <xsl:variable name='refused-count' 
                select='count( $refused/list-item )'/>

  <xsl:variable name='chunk-size' select='"12"'/>

  <xsl:variable name='paging'   select='$refused-count &gt; 15'/>
  <xsl:variable name='page'     select='$request-subscreen'/>
  <xsl:variable name='page-all' select='$page="all"'/>


  <xsl:template name='table-resources-for-review'>
    <xsl:param name='list'/>

    <tr class='here'>

      <th width='6%'>delete</th>
      <th class='desc'> item description</th>

    </tr>
    
    <xsl:for-each select='$list/list-item[id and title]' xml:space='preserve'>
      <xsl:variable name="nid" select='generate-id(.)'/>
      <xsl:variable name="id" select='id'/>

      <xsl:variable name='alternate'><xsl:if test='position() mod 2'> alternate</xsl:if></xsl:variable>
      <tr class='resource{$alternate}' id='row_{$nid}'>
        
        <td class='checkbutton' width='6%' valign='top'>
          
          <span class='checkbutton'>

            <input type='checkbox' name='unrefuse_{$nid}' id='unrefuse_{$nid}' 
                     onblur_after='item_checkbox_blur("row_{$nid}",this);'
                     onfocus_after='if(item_label_click){{this.blur();}};item_label_click=false;'
                     value='1'
                     xml:space='default'
               ><xsl:if test='contains( $user-agent,"Gecko/" )'>
                <xsl:attribute name='onchange'
                >item_checkbox_changed("row_<xsl:value-of select='$nid'/>",this);</xsl:attribute>
                <xsl:attribute name='onblur_after'/>
              </xsl:if>
            </input>

            <xsl:text>
            </xsl:text>

            <input type='hidden' name='id_{$nid}' value='{$id}'/>
          </span>

        </td>

        <td class='description'>

          <xsl:call-template name='present-resource' xml:space='default'>
            <xsl:with-param name='resource' select='.'/>
            <xsl:with-param name='for' select='concat( "unrefuse_", $nid )' />
            <xsl:with-param name='label-onclick'
                            >item_label_click=true;</xsl:with-param>
          </xsl:call-template>
    </td>
    </tr>

    </xsl:for-each>
  </xsl:template>



  <xsl:template name='refused-list-all'>

        <form screen='@research/refused' 
              xsl:use-attribute-sets='form'>

          <xsl:choose>
          <xsl:when test='$refused-count &gt; 1'>
            <p>Here are the <xsl:value-of select='$refused-count'/>
            items, that you have refused some time in the past:</p>
          </xsl:when>
          <xsl:when test='$refused-count = 1'>
            <p>Here is the item, that you have refused some
            time in the past:</p>
          </xsl:when>
          </xsl:choose>
          
          <table class='resources'>
            <xsl:call-template name='table-resources-for-review'>
              <xsl:with-param name='list' select='$refused'/>
            </xsl:call-template>
          </table>
          
          <p>
            <input type='submit'
	           id='submitB'
                   name='continue'
                   class='important'
                   value='REMOVE CHECKED ITEMS FROM THE LIST' 
                   />
          </p>

        </form>

  </xsl:template>

                      


  <xsl:template name='research-refused'>


    <h1>Refused research items</h1>

    <xsl:comment> subscreen <xsl:value-of select='$request-subscreen'/> </xsl:comment>

    <xsl:call-template name='show-status'/>

    <xsl:choose>
      <xsl:when test='$paging and $page-all'>
      
         <xsl:call-template name='tabset'>
            <xsl:with-param name='id' select='"tabs"'/>
            <xsl:with-param name='tabs'>
               <tab selected='1'> all&#160;at&#160;once </tab>
               <tab> <a ref='@research/refused'> 12&#160;per&#160;page </a> </tab>
            </xsl:with-param>
            <xsl:with-param name='content'>
 
              <xsl:call-template name='refused-list-all'/>

            </xsl:with-param>
         </xsl:call-template>

      </xsl:when>

      <xsl:when test='$paging and not($page-all)'>

         <xsl:call-template name='tabset'>
            <xsl:with-param name='id' select='"tabs"'/>
            <xsl:with-param name='tabs'>
              <tab> <a ref='@research/refused/all'>all&#160;at&#160;once</a> </tab>
              <tab selected='1'> 12&#160;per&#160;page </tab>
            </xsl:with-param>
            <xsl:with-param name='content'>
 
               <p>the list</p>

            </xsl:with-param>
         </xsl:call-template>

      </xsl:when>

      <xsl:when test='$refused/list-item'>

        <xsl:call-template name='refused-list-all'/>

      </xsl:when>
    
      <xsl:otherwise> 

        <p>At this moment, there are no refused research
        items in your profile.</p>

      </xsl:otherwise>
  
    </xsl:choose>
    


  </xsl:template>





  <!--   n o w   t h e   p a g e   t e m p l a t e    -->

  
  <xsl:template match='/data'>

    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>refused items</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='research-refused'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

    

</xsl:stylesheet>