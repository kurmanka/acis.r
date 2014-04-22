<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">  

  <!--   This file is part of the ACIS presentation template set.   -->


  <xsl:import href='../page.xsl'/>


  <xsl:template name='adm-menu'>

    <p style='text-align: center'>*  *  *</p>

    <p><a ref='adm'>admin tools</a></p>
    <ul>
      <li><a ref='adm/events/'>events</a>: 
          <a ref='adm/events/recent'>recent</a>, <a ref='adm/events/pref'>preferences</a>
      </li>
      <li><a ref='adm/search/person'>search for personal records</a> or 
          <a ref='adm/search'>documents, etc.</a>
      </li>
      <li><a ref='adm/sessions'>sessions list</a></li>
      <li><a ref='adm/get'>RePEc-Index data</a></li>
      <li><a ref='adm/sql'>sql console</a></li><!-- XXX dangerous! -->
      <li><a ref='adm/logs'>logs</a></li>
      
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

<dt><code><a ref='adm/search/person'>/adm/search/person</a></code>
</dt>

<dd id='adm-search-person'>
Search for personal records by email or short-id.</dd>


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

<dt><code><a ref='adm/logs'>/adm/logs</a></code></dt>

<dd id='adm-logs'> Read the tail of system's logs.</dd>


</dl>


      </xsl:with-param>

    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>

