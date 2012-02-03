<!--- Document Information -----------------------------------------------------

Title:      Scope.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Represents a scope type in the cache config

Usage:      

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		15/05/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="Scope" hint="Represents a scope type in the cache config">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Scope" output="false">
	<cfscript>
	
		return this;
	</cfscript>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setType(arguments.memento.type);
		setKey(arguments.memento.key);
	</cfscript>
</cffunction>

<cffunction name="getKey" access="public" returntype="string" output="false">
	<cfreturn instance.Key />
</cffunction>

<cffunction name="getType" access="public" returntype="string" output="false">
	<cfreturn instance.Type />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setKey" access="private" returntype="void" output="false">
	<cfargument name="Key" type="string" required="true">
	<cfset instance.Key = arguments.Key />
</cffunction>

<cffunction name="setType" access="private" returntype="void" output="false">
	<cfargument name="Type" type="string" required="true">
	<cfset instance.Type = arguments.Type />
</cffunction>

</cfcomponent>