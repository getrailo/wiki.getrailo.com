<!--- Document Information -----------------------------------------------------

Title:      QueryCache.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    A query caching mechanism

Usage:      

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		19/10/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="QueryCache" hint="A query caching mechanism">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="QueryCache" output="false">
	<cfscript>
		setQueryCollection(StructNew());
		setExpireyCollection(StructNew());
		
		return this;
	</cfscript>
</cffunction>

<cffunction name="cacheQuery" hint="Caches a given query" access="public" returntype="void" output="false">
	<cfargument name="query" hint="The query to cache" type="query" required="Yes">
	<cfargument name="key" hint="The unique key to store the query under" type="string" required="Yes">
	<cfargument name="expireDateTime" hint="The date-time that the query should expire, default of 'never'" type="date" required="No" default="#DateAdd('y', 10, Now())#">
	<cfscript>
		getQueryCollection().put(arguments.key, arguments.query);
		getExpireyCollection().put(arguments.key, arguments.expireDateTime);
	</cfscript>	
</cffunction>

<cffunction name="checkQuery" hint="Returns true if the query exists, and hasn't expired" access="public" returntype="boolean" output="false">
	<cfargument name="key" hint="The unique key to store the query under" type="string" required="Yes">
	<cfscript>
		return (StructKeyExists(getQueryCollection(), arguments.key) AND getExpireyCollection().get(arguments.key).after(Now()));
	</cfscript>
</cffunction>

<cffunction name="getQuery" hint="Retrieves a query from the cache" access="public" returntype="query" output="false">
	<cfargument name="key" hint="The unique key the query is stored under" type="string" required="Yes">
	<cfscript>
		return getQueryCollection().get(arguments.key);
	</cfscript>
</cffunction>

<cffunction name="removeQuery" hint="removes a query from the cache" access="public" returntype="void" output="false">
	<cfargument name="key" hint="The unique key the query is stored under" type="string" required="Yes">
	<cfscript>
		StructDelete(getQueryCollection(), arguments.key);
		StructDelete(getExpireyCollection(), arguments.key);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getQueryCollection" access="private" returntype="struct" output="false">
	<cfreturn instance.QueryCollection />
</cffunction>

<cffunction name="setQueryCollection" access="private" returntype="void" output="false">
	<cfargument name="QueryCollection" type="struct" required="true">
	<cfset instance.QueryCollection = arguments.QueryCollection />
</cffunction>

<cffunction name="getExpireyCollection" access="private" returntype="struct" output="false">
	<cfreturn instance.ExpireyCollection />
</cffunction>

<cffunction name="setExpireyCollection" access="private" returntype="void" output="false">
	<cfargument name="ExpireyCollection" type="struct" required="true">
	<cfset instance.ExpireyCollection = arguments.ExpireyCollection />
</cffunction>

</cfcomponent>