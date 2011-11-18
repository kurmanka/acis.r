<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">
  <!-- evcino -->
  <xsl:import href='main.xsl'/>
  <xsl:import href='../../yes-no-choice.xsl'/>
  <xsl:variable name='parents'>
    <acis:par id='research/main'/>
  </xsl:variable>
  <!-- ToK 2008-04-06: was research/autoupdate -->
  <xsl:variable name='current-screen-id'>
    <xsl:text>research/autoupdate</xsl:text>
  </xsl:variable>
  <xsl:template match='/data'>
    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>
        <xsl:text>automatic update preferences</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='content'>
        <h1>
          <xsl:text>Automatic research profile update</xsl:text>
        </h1>
        <acis:form screen='@research/autoupdate' 
                   class='important' 
                   name='f'>              
          <h2>
            <xsl:text>Preferences</xsl:text>
          </h2>
          <xsl:call-template name='fieldset'>                
            <xsl:with-param name='content'>              
              <!-- <p>-->
              <!--   <strong>-->
              <!--     <xsl:text>Q1.</xsl:text>-->
              <!--   </strong> -->
              <!--   <xsl:text>When a document’s record points to your personal record with its short-id (</xsl:text>-->
              <!--   <code class='id'>-->
              <!--     <xsl:value-of select='$record-sid'/>-->
              <!--   </code>-->
              <!--   <xsl:text>), do you want such document to be automatically added to your research profile?</xsl:text>-->
              <!-- </p>                  -->
              <!-- <p class='pad'>-->
              <!--   <xsl:call-template name='yes-no-choice'>-->
              <!--     <xsl:with-param name='param-name'>-->
              <!--       <xsl:text>arpm-add-by-handle</xsl:text>-->
              <!--     </xsl:with-param>-->
              <!--     <xsl:with-param name='default'-->
              <!--                     select='"yes"'/>-->
              <!--   </xsl:call-template>-->
              <!-- </p>              -->
              <!-- <p> -->
              <!-- <strong> -->
              <!-- <xsl:text>Q1.</xsl:text> -->
              <!-- </strong>  -->
              <!-- </p> -->
              <p>
                <xsl:text>We can run a robot which will periodically run automatic search for you.  All results will be reported to you through email.  Do you want such service?</xsl:text>
              </p>                           
              <p class='pad'>
                <xsl:call-template name='yes-no-choice'>
                  <xsl:with-param name='param-name'>
                    <xsl:text>arpm-name-search</xsl:text>
                  </xsl:with-param>
                  <xsl:with-param name='default' 
                                  select='"yes"'/>
                </xsl:call-template>
              </p>                                   
              <!-- <p>-->
              <!--   <strong>-->
              <!--     <xsl:text>Q3.</xsl:text>-->
              <!--   </strong>                 -->
              <!--   <xsl:text>Automatic search uses your </xsl:text>-->
              <!--   <a ref='@name'>name variations</a>-->
              <!--   <xsl:text>. When an exact match of your name variation is found among a document’s authors, do you want us to automatically add the document to your profile?</xsl:text> -->              
              <!-- </p>              -->
              <!-- <p class='pad'>-->
              <!--   <xsl:call-template name='yes-no-choice'>-->
              <!--     <xsl:with-param name='param-name'>-->
              <!--       <xsl:text>arpm-add-by-name</xsl:text>-->
              <!--     </xsl:with-param>-->
              <!--     <xsl:with-param name='default' select='"no"'/>-->
              <!--   </xsl:call-template>-->
              <!-- </p>  -->
              <xsl:call-template name='name-variations-display'/>              
            </xsl:with-param>
          </xsl:call-template>              
          <p>
            <input type='submit'
                   class='important' 
                   value=' SAVE '/>
          </p>          
        </acis:form>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
