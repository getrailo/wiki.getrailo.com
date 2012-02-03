<!--- Document Information -----------------------------------------------------

Title:      Condition.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Conditional processing on an collection

Usage:      

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		11/07/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="Condition" hint="Conditional processing on an collection">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Condition" output="false">
	<cfscript>
		setWhere("");
		setProperty("");
		setValue("");
		
		return this;			
	</cfscript>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setWhere(arguments.memento.where);
		setProperty(arguments.memento.property);
		setValue(arguments.memento.value);
	</cfscript>
</cffunction>

<cffunction name="getWhere" access="public" returntype="string" output="false">
	<cfreturn instance.Where />
</cffunction>

<cffunction name="hasWhere" hint="Has a where statement" access="public" returntype="boolean" output="false">
	<cfreturn len(getWhere())>
</cffunction>

<cffunction name="getProperty" access="public" returntype="string" output="false">
	<cfreturn instance.Property />
</cffunction>

<cffunction name="hasProperty" hint="Has a property" access="public" returntype="boolean" output="false">
	<cfreturn len(getProperty())>
</cffunction>

<cffunction name="getValue" access="public" returntype="string" output="false">
	<cfreturn instance.Value />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setProperty" access="private" returntype="void" output="false">
	<cfargument name="Property" type="string" required="true">
	<cfset instance.Property = arguments.Property />
</cffunction>

<cffunction name="setValue" access="private" returntype="void" output="false">
	<cfargument name="Value" type="string" required="true">
	<cfset instance.Value = arguments.Value />
</cffunction>



<cffunction name="setWhere" access="private" returntype="void" output="false">
	<cfargument name="Where" type="string" required="true">
	<cfset instance.Where = arguments.Where />
</cffunction>



</cfcomponent>