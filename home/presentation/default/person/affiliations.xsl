<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='../page-universal.xsl' />

  <xsl:import href='affiliations-common.xsl' />
  <xsl:import href='affiliations-search.xsl'/>


  <xsl:variable name='parents'/>

  <xsl:variable name='current-screen-id'>affiliations</xsl:variable>


  <!--    v a r i a b l e s    -->

  <xsl:variable name='affiliations' select='$response-data/affiliations'/>
  <xsl:variable name='search'       select='$response-data/institution-search'/> 
  <xsl:variable name='found-items'  select='$search/results'/> 
  <xsl:variable name='search-what'  select='$form-values/search-what/text()'/> 




  <!--  main affiliations screen template -->

  <xsl:template name='the-affiliations'>


    <h1>Affiliations</h1>


    <xsl:call-template name='show-status'><xsl:with-param name='fields-spec-uri' 
    select='"fields-institution.xml"'/></xsl:call-template>

<!--

    <div class='onThisPage supNav' >
      <p>On this page:</p>

      <ul>

        <li><a href='#currentList' class='int'
        >your affiliations</a>         
        <xsl:if test='not( $affiliations/list-item )'>
          (empty)
        </xsl:if>
        </li>

        <li><a href='#searchForm' class='int'>institutions search form</a></li>

        <li><a href='#submit' class='int'
        >a link to submit a new institution record</a></li>

        <xsl:choose xml:space='default'>
          <xsl:when test='$session-type ="new-user"'>

            <li><a href='#continue' class='int'
            >continue registration link</a></li>
            
          </xsl:when>
        </xsl:choose>
        
      </ul>
    </div>

-->

    <div id='currentList'>
      <h2>Your affiliations</h2>
      
      <xsl:if test='$affiliations/list-item'>
        <div class='institutions'>
          <xsl:call-template name='show-institutions' xml:space='default'>
            <xsl:with-param name='list' select='$affiliations'/>
            <xsl:with-param name='mode' select='"remove"'/>
          </xsl:call-template>
        </div>

        <phrase ref='affiliations-listing-prolog'/>

      </xsl:if>

      <xsl:if test='not( $affiliations/list-item )'>
        <p>You are not associated with any organization (yet).</p>
      </xsl:if>
    </div>    
    
    
    <xsl:if test='$response-data/processed and $session-type="new-user"'>
      <form class='narrow'>
        <p>
          <xsl:call-template name='continue-button'/>
          if you are done with affiliations.
        </p>
      </form>
      <xsl:text>
</xsl:text>
    </xsl:if>


    
    <h2 id='searchForm'>Search institutions</h2>

    <xsl:call-template name='search-form'/>

    <xsl:call-template name='submit-invitation'/>

<!--    
    <h1 style='margin-top: 2em;'>Where do you want to go now?</h1>
        
    <ul id='continue'>
    
      <xsl:choose xml:space='default'>
        <xsl:when test='$session-type = "new-user"'>
          
          <li><a ref='@research'>next registration step</a></li>
        
        </xsl:when>
        <xsl:otherwise>
          
          <li><a ref='@menu' >profile menu</a></li>
          
        </xsl:otherwise>
      </xsl:choose>
    
    </ul>
-->

  </xsl:template>


  <xsl:variable name='to-go-options'>
    <root/>
  </xsl:variable>



  <!--   n o w   t h e   p a g e   t e m p l a t e    -->
  
  <xsl:template match='/data'>
    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>affiliations profile</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='the-affiliations'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

    
</xsl:stylesheet>