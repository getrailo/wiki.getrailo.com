<!--- Document Information -----------------------------------------------------

Title:      Argument.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    A argument for a custom function

Usage:      

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		25/11/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="Argument" hint="A argument for a custom function">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="Argument" output="false">
	<cfscript>
		setName("");
		setType("");
		setRequired(false);
		setDefault("");
					
		return this;
	</cfscript>
</cffunction>

<cffunction name="getName" access="public" returntype="string" output="false">
	<cfreturn instance.Name />
</cffunction>

<cffunction name="getType" access="public" returntype="string" output="false">
	<cfreturn instance.Type />
</cffunction>

<cffunction name="getRequired" access="public" returntype="boolean" output="false">
	<cfreturn instance.Required />
</cffunction>

<cffunction name="getDefault" access="public" returntype="string" output="false">
	<cfreturn instance.Default />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setName(arguments.memento.name);
		setType(arguments.memento.type);
		setRequired(arguments.memento.required);
		setDefault(arguments.memento.default);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setName" access="private" returntype="void" output="false">
	<cfargument name="Name" type="string" required="true">
	<cfset instance.Name = arguments.Name />
</cffunction>

<cffunction name="setType" access="private" returntype="void" output="false">
	<cfargument name="Type" type="string" required="true">
	<cfset instance.Type = arguments.Type />
</cffunction>

<cffunction name="setRequired" access="private" returntype="void" output="false">
	<cfargument name="Required" type="boolean" required="true">
	<cfset instance.Required = arguments.Required />
</cffunction>

<cffunction name="setDefault" access="private" returntype="void" output="false">
	<cfargument name="Default" type="string" required="true">
	<cfset instance.Default = arguments.Default />
</cffunction>

</cfcomponent>