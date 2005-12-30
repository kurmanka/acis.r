<!--   This file is part of the ACIS presentation template-set.   -->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">  


  <xsl:import href='main.xsl'/>

  <xsl:variable name='parents'>
    <par id='research/main'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>research/autoupdate</xsl:variable>


  <xsl:template name='yes-no-choice' xmlns='http://x'> <!-- a form widget -->
    <xsl:param name='param-name'/>
    <xsl:param name='default'/>

<i><input type='radio' name='{$param-name}' id='{$param-name}-y' value='1'
>
<xsl:if test='$default = "yes"'>
  <xsl:attribute name='checked'/>
</xsl:if>
</input>
<xsl:text>&#160;</xsl:text>
<label for='{$param-name}-y'>Yes, please.</label><br/>
<input type='radio' name='{$param-name}' id='{$param-name}-n'
       value='0'
>
  <xsl:if test='$default = "no"'>
    <xsl:attribute name='checked'/>
  </xsl:if>
</input>
 
<xsl:text>&#160;</xsl:text>
<label for='{$param-name}-n'>No, thanks.</label>
</i>

  </xsl:template>


  <xsl:template match='/data'>
    <xsl:call-template name='research-page'>

      <xsl:with-param name='title'>automatic update preferences</xsl:with-param>

      <xsl:with-param name='content'>

<!--
        <xsl:call-template name='research-profile-navigation'/>
-->
<!--
  <h1>Research profile preferences</h1>
-->

<h1>Automatic research profile update</h1>


     <xsl:call-template name='fieldset'>
       <xsl:with-param name='content' xmlns='http://x'>

<form screen='@research/autoupdate'
      class='important' name='f'> 

  <h2>Preferences</h2>

  <p><strong>Q1.</strong> 
  When a document's record points to your
  personal record with its short-id ("<code class='id' ><xsl:value-of
  select='$record-sid'/></code>"), do you want such document to be
  automatically added to your research profile?</p>


  <p class='pad'>
    <xsl:call-template name='yes-no-choice'>
      <xsl:with-param name='param-name'>arpm-add-by-handle</xsl:with-param>
      <xsl:with-param name='default' select='"yes"'/>
    </xsl:call-template>
  </p>

  <p><strong>Q2.</strong> We can run a robot which will periodically
  run automatic search for you.  All results will be reported to you
  through email.  Do you want such service?</p>


  <p class='pad'>
    <xsl:call-template name='yes-no-choice'>
      <xsl:with-param name='param-name'>arpm-name-search</xsl:with-param>
      <xsl:with-param name='default' select='"yes"'/>
    </xsl:call-template>
  </p>


  <p><strong>Q3.</strong> 

  Automatic search uses your <a ref='@name'>name variations</a>.  When
  an exact match of your name variation is found among a document's
  authors, do you want us to automatically add the document to your
  profile?</p>

  <p class='pad'>
    <xsl:call-template name='yes-no-choice'>
      <xsl:with-param name='param-name'>arpm-add-by-name</xsl:with-param>
      <xsl:with-param name='default' select='"no"'/>
    </xsl:call-template>
  </p>



<xsl:call-template name='name-variations-display'/>


<p><input type='submit' class='important' value=' SAVE '/></p>

</form>       

     </xsl:with-param>
</xsl:call-template>


      </xsl:with-param>

    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>