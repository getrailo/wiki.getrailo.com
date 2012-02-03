<!--- Document Information -----------------------------------------------------

Title:      FileReader.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    File Reader

Usage:      

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/05/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="FileReader" displayname="File Reader" hint="Reads Files">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="FileReader" output="false">
	<cfargument name="path" hint="Absolute path to the file" type="string" required="Yes">
	<cfscript>
		var content = 0;
		setPath(arguments.path);
	</cfscript>
	<cffile action="read" file="#getPath()#" variable="content">
	<cfscript>		
		setContent(content);
		return this;		
	</cfscript>
</cffunction>

<cffunction name="getPath" access="public" returntype="string" output="false">
	<cfreturn instance.Path />
</cffunction>

<cffunction name="getContent" access="public" returntype="string" output="false">
	<cfreturn instance.Content />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->


<cffunction name="setPath" access="private" returntype="void" output="false">
	<cfargument name="Path" type="string" required="true">
	<cfset instance.Path = arguments.Path />
</cffunction>



<cffunction name="setContent" access="private" returntype="void" output="false">
	<cfargument name="Content" type="string" required="true">
	<cfset instance.Content = arguments.Content />
</cffunction>

</cfcomponent>