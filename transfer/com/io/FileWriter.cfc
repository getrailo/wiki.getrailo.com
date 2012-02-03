<!--- Document Information -----------------------------------------------------

Title:      FileWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes files

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		05/04/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="FileWriter" hint="A FileWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="FileWriter" output="false">
	<cfargument name="path" hint="Absolute path to the file" type="string" required="Yes">
	<cfscript>
		setPath(arguments.path);

		return this;
	</cfscript>
</cffunction>

<cffunction name="append" hint="Appends the text to the given file" access="public" returntype="void" output="false">
	<cfargument name="string" hint="The string to append" type="string" required="Yes">

	<cffile action="append" file="#getPath()#" output="#arguments.string#">
</cffunction>

<cffunction name="write" hint="The string to write to the file" access="public" returntype="void" output="false">
	<cfargument name="string" hint="The string to write" type="string" required="Yes">

	<cffile action="write" file="#getPath()#" output="#arguments.string#">
</cffunction>

<cffunction name="delete" hint="delete the file after you are done" access="public" returntype="void" output="false">

	<cffile action="delete" file="#getPath()#">
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getPath" access="public" returntype="string" output="false">
	<cfreturn instance.Path />
</cffunction>

<cffunction name="setPath" access="private" returntype="void" output="false">
	<cfargument name="Path" type="string" required="true">
	<cfset instance.Path = arguments.Path />
</cffunction>

</cfcomponent>