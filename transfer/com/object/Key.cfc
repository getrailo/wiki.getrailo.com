<!--- Document Information -----------------------------------------------------

Title:      Key.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    BO for a key in a collection

Usage:      

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		02/08/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="Key" hint="BO for a Key in a Collection">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="Key" output="false">
	<cfscript>
		setProperty("");
		
		return this;
	</cfscript>
</cffunction>

<cffunction name="getProperty" access="public" returntype="string" output="false">
	<cfreturn instance.Property />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setProperty(arguments.memento.property);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setProperty" access="private" returntype="void" output="false">
	<cfargument name="Property" type="string" required="true">
	<cfset instance.Property = arguments.Property />
</cffunction>

</cfcomponent>