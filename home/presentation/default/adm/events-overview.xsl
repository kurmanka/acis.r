<!--   This file is part of the ACIS presentation template-set.   -->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    xmlns:date="http://exslt.org/dates-and-times"
    exclude-result-prefixes="exsl xml html acis #default"
  version="1.0">  


  <xsl:import href='../page.xsl'/>
  <xsl:import href='index.xsl'/>


  <xsl:variable name='for' select='//for/text()'/>

  <xsl:variable name='for-year'  select='substring($for,1,4)'/>
  <xsl:variable name='for-month' select='substring($for,6,2)'/>

  <xsl:variable name='month-name' 
                select='date:month-name(concat("--",$for-month,"--"))'/>


<xsl:template name='month-item'>
  <xsl:param name='year'/>
  <xsl:param name='node'/>
  <xsl:variable name='month-num' select='$node/@key'/>
  
  <xsl:variable name='month-name' 
                select='date:month-name(concat("--",$month-num,"--"))'/>
  
  <a ref='adm/events/{$year}-{$month-num}'>
  <xsl:value-of select='substring($month-name,1,3)'/>
  </a>

</xsl:template>

<xsl:variable name='decades'>
  <acis:ten>
    <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/>
  </acis:ten>
  <acis:ten>
    <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/>
  </acis:ten>
  <acis:ten>
    <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/>
  </acis:ten>
  <acis:ten>
    <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/> <acis:d/>
  </acis:ten>
</xsl:variable>


<xsl:template name='month-detailed'>
  <xsl:param name='year'/>
  <xsl:param name='node'/>
  <xsl:variable name='month-num' select='@key'/>

  <table class='month'> 
    
    <xsl:for-each select='exsl:node-set($decades)/acis:ten'>
      <tr>
        <xsl:for-each select='acis:d'>
          <xsl:variable name='number' select='count(preceding::acis:d)+1'/>
          <td>
            <xsl:if test='$node/hash-item[@key=$number]'>
              <xsl:variable name='day' select='$node/hash-item[@key=$number]'/>
              <a ref='adm/events/{$year}-{$month-num}-{$day/@key}'>
                <xsl:value-of select='$number'/>
              </a>
            </xsl:if>
          </td>
        </xsl:for-each>
      </tr>
    </xsl:for-each>

  </table>              

</xsl:template>

  <xsl:variable name='years' select='//years'/>

  <xsl:template name='show-year'>
    <xsl:param name='node'/>

    <xsl:for-each select='$node'>

      <xsl:variable name='year' select='@key'/>
      <h2><xsl:value-of select='$year'/></h2>

<xsl:choose>
  <xsl:when test='count(hash-item/hash-item)'>
    <!-- need a per-day view of a month -->
    <xsl:variable name='month' select='hash-item[hash-item]'/>

    <xsl:for-each select='$month'>
      <h3><xsl:value-of select='$month-name'/></h3>

      <xsl:call-template name='month-detailed'>
        <xsl:with-param name='year' select='$year'/>
        <xsl:with-param name='node' select='.'/>
      </xsl:call-template>

      <!-- XX links to a previous and next months? -->

    </xsl:for-each>

  </xsl:when>
  <xsl:otherwise>
    <!-- brief view, just monthly links -->

<p>Months: <big>
    <xsl:for-each select='hash-item'>
      <xsl:call-template name='month-item'>
        <xsl:with-param name='year' select='$year'/>
        <xsl:with-param name='node' select='.'/>    
      </xsl:call-template>
      <xsl:text> </xsl:text>
    </xsl:for-each>
</big>
</p>

  </xsl:otherwise>
</xsl:choose>
      
    </xsl:for-each>
    
  </xsl:template>


<xsl:variable name='for-day'/>

<xsl:template name='crumbs'>

<xsl:if test='$for-year'>
  <p class='breadCrumb'
     ><a ref='adm/events'>Years</a>
  <xsl:if test='$for-month'>
    <xsl:text> </xsl:text>
    <xsl:call-template name='connector'/>
    <xsl:text> </xsl:text>

    <a ref='adm/events/{$for-year}'
    ><xsl:value-of select='$for-year'/></a>

     <xsl:if test='$for-day'>
       <xsl:text> </xsl:text>
       <xsl:call-template name='connector'/>
       <xsl:text> </xsl:text>

       <a ref='adm/events/{$for-year}-{$for-month}'
       ><xsl:value-of select='$month-name'/></a>

     </xsl:if>
  </xsl:if> 
  <xsl:text> </xsl:text>
  <xsl:call-template name='connector'/>
  </p>
</xsl:if>

</xsl:template>


<xsl:template name='show-events-form'>

  <p><span> </span></p>

  <hr/>

  <p><span> </span></p>

  <acis:form screen='adm/events/show'>

    <p>Show me events for period:</p>

    <p><label for='startdate'>from </label>
    <input 
     class='digit'
     type='text' name='startdate' id='startdate' size='10'
     value='YYYY-MM-DD'
     />
     <xsl:text> </xsl:text>
     <label for='enddate'>till </label>
     <input type='text' name='enddate' id='enddate' size='10'
            class='digit'
            value='now'
            /><!-- value='{substring(date:date-time(),1,10)}' -->
    </p>    

    <table>

      <th colspan='2'>Options <small>(your <a ref='adm/events/pref'>preferences</a> will also work)</small></th>
      
      <tr>
        <td class='label'><label for='hidemagic'>Hide magic sessions?</label></td>
        <td><input type='checkbox' name='hidemagic' id='hidemagic' value='1'/> </td>
      </tr>

      <tr>
        <td class='label'><label for='onlyresearch'>Only research?</label></td>
        <td><input type='checkbox' name='onlyresearch' id='onlyresearch' value='1'/> </td>
      </tr>

      <tr>
        <td/>
        <td>
    <p><input type='submit' value='SHOW' id='submit' class='important'/></p>
        </td>
      </tr>
    </table>

<acis:script-onload>
getRef("startdate").onfocus=function () {
 this.onfocus=null;
 if ( this.value == "YYYY-MM-DD" ) {
   this.value='';
 }
}
</acis:script-onload>

<p>...or see <a ref='/adm/events/recent'>recent</a> events.</p>

  </acis:form>

</xsl:template>



  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>events <xsl:value-of
      select='$for'/></xsl:with-param>
      
      <xsl:with-param name='content'>

<xsl:call-template name='crumbs'/>

<xsl:for-each select='$years/hash-item'>

  <xsl:if test='not($for-year) or @key=$for-year'>
    <xsl:call-template name='show-year'>
      <xsl:with-param name='node' select='.'/>
    </xsl:call-template>
  </xsl:if>

</xsl:for-each>

<xsl:call-template name='show-events-form'/>

<xsl:call-template name='adm-menu'/>


      
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>



</xsl:stylesheet>