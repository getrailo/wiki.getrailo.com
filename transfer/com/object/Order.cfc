<!--- Document Information -----------------------------------------------------

Title:      Order.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    BO for Ordering within collections

Usage:      

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		26/10/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="Order" hint="Business object that defines a collections ordering">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Order" output="false">
	<cfscript>
		setProperty("");
		setOrder("ASC");
			
		return this;
	</cfscript>
</cffunction>

<cffunction name="getProperty" access="public" returntype="string" output="false">
	<cfreturn instance.Property />
</cffunction>

<cffunction name="getOrder" access="public" returntype="string" output="false">
	<cfreturn instance.Order />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setProperty(arguments.memento.property);
		setOrder(arguments.memento.order);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setProperty" access="private" returntype="void" output="false">
	<cfargument name="Property" type="string" required="true">
	<cfset instance.Property = arguments.Property />
</cffunction>

<cffunction name="setOrder" access="private" returntype="void" output="false">
	<cfargument name="Order" type="string" required="true">
	<cfset instance.Order = arguments.Order />
</cffunction>

</cfcomponent>