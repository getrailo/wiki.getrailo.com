<!--- Document Information -----------------------------------------------------

Title:      AbstractBaseWalker.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Abstract base for a walker

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		27/02/2007		Created

------------------------------------------------------------------------------->
<cfcomponent name="AbstractBaseWalker" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="AbstractBaseWalker" output="false">
	<cfargument name="tqlParser" hint="The tqlParser to generate the AST for the TQL" type="transfer.com.tql.TQLParser" required="Yes">
	<cfargument name="objectManager" hint="The object manager to query" type="transfer.com.object.ObjectManager" required="Yes">
	<cfargument name="property" hint="property walker" type="transfer.com.tql.walkers.Property" required="no">
	<cfargument name="object" hint="Object walker" type="transfer.com.tql.walkers.Object" required="no">
	<cfargument name="join" hint="join walker" type="transfer.com.tql.walkers.Join" required="No">
	<cfargument name="selectStatement" hint="Select statement for sub selects" type="transfer.com.tql.SelectStatement" required="No">
	<cfscript>
		variables.instance = StructNew();

		setTQLParser(arguments.tqlParser);
		setObjectManager(arguments.objectManager);

		if(structkeyExists(arguments, "property"))
		{
			setProperty(arguments.property);
		}

		if(structKeyExists(arguments, "selectStatement"))
		{
			setSelectStatement(arguments.selectStatement);
		}

		if(structkeyExists(arguments, "object"))
		{
			setObject(arguments.object);
		}

		if(structkeyExists(arguments, "join"))
		{
			setJoin(arguments.join);
		}

		return this;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getTQLParser" access="private" returntype="transfer.com.tql.TQLParser" output="false">
	<cfreturn instance.TQLParser />
</cffunction>

<cffunction name="setTQLParser" access="private" returntype="void" output="false">
	<cfargument name="TQLParser" type="transfer.com.tql.TQLParser" required="true">
	<cfset instance.TQLParser = arguments.TQLParser />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getProperty" access="private" returntype="transfer.com.tql.walkers.Property" output="false">
	<cfreturn instance.Property />
</cffunction>

<cffunction name="setProperty" access="private" returntype="void" output="false">
	<cfargument name="Property" type="transfer.com.tql.walkers.Property" required="true">
	<cfset instance.Property = arguments.Property />
</cffunction>

<cffunction name="getObject" access="private" returntype="transfer.com.tql.walkers.Object" output="false">
	<cfreturn instance.Object />
</cffunction>

<cffunction name="setObject" access="private" returntype="void" output="false">
	<cfargument name="Object" type="transfer.com.tql.walkers.Object" required="true">
	<cfset instance.Object = arguments.Object />
</cffunction>

<cffunction name="getJoin" access="private" returntype="transfer.com.tql.walkers.Join" output="false">
	<cfreturn instance.Join />
</cffunction>

<cffunction name="setJoin" access="private" returntype="void" output="false">
	<cfargument name="Join" type="transfer.com.tql.walkers.Join" required="true">
	<cfset instance.Join = arguments.Join />
</cffunction>

<cffunction name="getSelectStatement" access="private" returntype="transfer.com.tql.SelectStatement" output="false">
	<cfreturn instance.SelectStatement />
</cffunction>

<cffunction name="setSelectStatement" access="private" returntype="void" output="false">
	<cfargument name="SelectStatement" type="transfer.com.tql.SelectStatement" required="true">
	<cfset instance.SelectStatement = arguments.SelectStatement />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>