<!--- Document Information -----------------------------------------------------

Title:      QueryCache.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    A cache for query objects

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		19/07/2007		Created

------------------------------------------------------------------------------->
<cfcomponent hint="A cache for query objects" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="QueryCache" output="false">
	<cfscript>
		variables.instance = StructNew();

		setCache(StructNew());

		return this;
	</cfscript>
</cffunction>

<cffunction name="addQuery" hint="add a query to the cache" access="public" returntype="void" output="false">
	<cfargument name="key" hint="the key to store the query under" type="string" required="Yes">
	<cfargument name="query" hint="the query object" type="transfer.com.sql.Query" required="Yes">
	<cfscript>
		StructInsert(getCache(), arguments.key, arguments.query, true);
	</cfscript>
</cffunction>

<cffunction name="getQuery" hint="gets a Query object from the cache" access="public" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="key" hint="the key the query is stored under" type="string" required="Yes">
	<cfreturn StructFind(getCache(), arguments.key) />
</cffunction>

<cffunction name="hasQuery" hint="if the cache has the query" access="public" returntype="boolean" output="false">
	<cfargument name="key" hint="the key the query is stored under" type="string" required="Yes">
	<cfreturn StructKeyExists(getCache(), arguments.key) />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getCache" access="private" returntype="struct" output="false">
	<cfreturn instance.Cache />
</cffunction>

<cffunction name="setCache" access="private" returntype="void" output="false">
	<cfargument name="Cache" type="struct" required="true">
	<cfset instance.Cache = arguments.Cache />
</cffunction>

</cfcomponent>