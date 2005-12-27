<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">  

  <!--   This file is part of the ACIS presentation template set.   -->


  <xsl:import href='../page.xsl'/>


  <xsl:template name='adm-menu'>

    <p style='text-align: center'>*  *  *</p>

    <p><a ref='adm'>adm/</a></p>
    <ul>

      <li><a ref='adm/sql'>sql</a></li>
      <li><a ref='adm/events/'>events/</a>

        <ul>
          <li><a ref='adm/events/recent'>recent</a></li>
          <li><a ref='adm/events/pref'>pref</a></li>
<!--
          <li><a ref='adm/events/raw'>raw</a></li>
-->
        </ul>
   
      </li>
      <li><a ref='adm/search'>search</a></li>
      <li><a ref='adm/get'>get</a></li>
      <li><a ref='adm/sessions'>sessions</a></li>
      
<!--
      <li><a ref='adm/'>/adm/</a></li>
      
      <li><a ref='adm/'>/adm/</a></li>
-->
      
    </ul>
  </xsl:template>


  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>adm/</xsl:with-param>
      
      <xsl:with-param name='content'>

<h1>Administrative screens</h1>

<dl>

<dt><a ref='adm/sql'><code>/adm/sql</code></a></dt>

<dd> Enter and execute any SQL query on behalf of the ACIS' Mysql user
and with <code>acis-db-name</code> as the default database.</dd>



<dt><code><a ref='adm/events'>/adm/events</a></code>
</dt>

<dd id='adm-events'>
Browse the events database, the database version of the
log of what happened in ACIS over time.
</dd>


<dt><code><a ref='adm/search'>/adm/search</a></code>
</dt>

<dd id='adm-search'>
Check the most important ACIS' database tables.  Search for documents,
for personal records or for users.</dd>


<dt><code><a ref='adm/get'>/adm/get</a></code></dt>

<dd id='adm-get'> Access the update daemon's database of metadata
records and their history.
</dd>




<dt><code><a
ref='adm/sessions'>/adm/sessions</a></code> 
</dt>

<dd id='adm-sessions'>
Browse all currently open sessions, their type and user name, and how
old the session is.  Look inside any of the current sessions.
</dd>


</dl>


      </xsl:with-param>

    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>

