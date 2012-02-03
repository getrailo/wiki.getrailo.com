<!--- Document Information -----------------------------------------------------

Title:      AbstractBaseComposition.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Abstract Base Comosition Object

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		03/07/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="AbstractBaseComposition" hint="Abstract Base Comosition Object">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="private" returntype="void" output="false">
	<cfargument name="object" hint="the parent obect" type="transfer.com.object.Object" required="Yes">
	<cfargument name="objectManager" hint="The object manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		setObjectManager(arguments.objectManager);
		setObject(arguments.object);

		setName("");
		setIsLazy(false);
		setIsNullable(false);
	</cfscript>
</cffunction>

<cffunction name="getName" access="public" returntype="string" output="false">
	<cfreturn instance.Name />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setName(arguments.memento.name);
		setIsLazy(arguments.memento.lazy);
		setIsNullable(arguments.memento.nullable);
		setIsProxied(arguments.memento.proxied);
	</cfscript>
</cffunction>

<cffunction name="getIsLazy" access="public" returntype="string" output="false">
	<cfreturn instance.IsLazy />
</cffunction>

<cffunction name="getIsNullable" access="public" returntype="boolean" output="false">
	<cfreturn instance.IsNullable />
</cffunction>

<cffunction name="setIsLazy" access="public" returntype="void" output="false">
	<cfargument name="IsLazy" type="string" required="true">
	<cfset instance.IsLazy = arguments.IsLazy />
</cffunction>

<cffunction name="getIsProxied" access="public" returntype="boolean" output="false">
	<cfreturn instance.isProxied />
</cffunction>

<cffunction name="validate" hint="does nothing, should be overwritten" access="public" returntype="void" output="false">

</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setName" access="private" returntype="void" output="false">
	<cfargument name="Name" type="string" required="true">
	<cfset instance.Name = arguments.Name />
</cffunction>

<cffunction name="setIsNullable" access="private" returntype="void" output="false">
	<cfargument name="IsNullable" type="boolean" required="true">
	<cfset instance.IsNullable = arguments.IsNullable />
</cffunction>

<cffunction name="getObject" access="private" returntype="transfer.com.object.Object" output="false">
	<cfreturn instance.Object />
</cffunction>

<cffunction name="setObject" access="private" returntype="void" output="false">
	<cfargument name="Object" type="transfer.com.object.Object" required="true">
	<cfset instance.Object = arguments.Object />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="setIsProxied" access="private" returntype="void" output="false">
	<cfargument name="isProxied" type="boolean" required="true">
	<cfset instance.isProxied = arguments.isProxied />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>