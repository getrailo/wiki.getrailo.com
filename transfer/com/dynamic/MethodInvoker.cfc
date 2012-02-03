<!--- Document Information -----------------------------------------------------

Title:      MethodInvoker.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Dynamic invokes a method on a CFC by its name

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		10/08/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="MethodInvoker" hint="Dynamic invokes a method on a CFC by its name">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="MethodInvoker" output="false">
	<cfscript>

		return this;
	</cfscript>
</cffunction>

<cffunction name="invokeMethod" hint="Invokes a method and returns its resiult" access="public" returntype="any" output="false">
	<cfargument name="component" hint="The component to invoke against" type="any" required="Yes">
	<cfargument name="methodName" hint="The name of the method" type="string" required="Yes">
	<cfargument name="args" hint="ArgumentCollection to pass in" type="struct" required="No" default="#StructNew()#">

	<cfset var local = StructNew()>

	<cfinvoke component="#arguments.component#"
				method="#arguments.methodName#"
				argumentcollection="#arguments.args#"
				returnvariable="local.return">

	<cfscript>
		if(StructKeyExists(local, "return"))
		{
			return local.return;
		}

		return 0;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>