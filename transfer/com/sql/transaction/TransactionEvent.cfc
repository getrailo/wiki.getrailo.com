<!--- Document Information -----------------------------------------------------

Title:      TransactionEvent.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Transaction Event

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		22/02/2008		Created

------------------------------------------------------------------------------->
<cfcomponent hint="A Transaction Event" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransactionEvent" output="false">
	<cfscript>
		variables.instance = StructNew();

		return this;
	</cfscript>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setObject(arguments.memento.object);
		setMethod(arguments.memento.method);
		setArgs(arguments.memento.args);
	</cfscript>
</cffunction>

<cffunction name="getObject" access="public" returntype="any" output="false">
	<cfreturn instance.object />
</cffunction>

<cffunction name="getMethod" access="public" returntype="string" output="false">
	<cfreturn instance.method />
</cffunction>

<cffunction name="getArgs" access="public" returntype="struct" output="false">
	<cfreturn instance.args />
</cffunction>

<cffunction name="getAction" access="public" returntype="string" output="false">
	<cfreturn instance.action />
</cffunction>

<cffunction name="clean" hint="clean off the state of the object" access="public" returntype="void" output="false">
	<cfset variables.instance = StructNew() />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setAction" access="package" returntype="void" output="false">
	<cfargument name="action" type="string" required="true">
	<cfset instance.action = arguments.action />
</cffunction>

<cffunction name="setObject" access="private" returntype="void" output="false">
	<cfargument name="object" type="any" required="true">
	<cfset instance.object = arguments.object />
</cffunction>

<cffunction name="setMethod" access="private" returntype="void" output="false">
	<cfargument name="method" type="string" required="true">
	<cfset instance.method = arguments.method />
</cffunction>

<cffunction name="setArgs" access="private" returntype="void" output="false">
	<cfargument name="args" type="struct" required="true">
	<cfset instance.args = arguments.args />
</cffunction>

</cfcomponent>