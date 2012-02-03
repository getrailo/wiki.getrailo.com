<cfcomponent name="TQLManager" hint="Top level manage for TQL calls">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TQLManager" output="false">
	<cfargument name="datasource" hint="The datasource BO" type="transfer.com.sql.Datasource" required="Yes" _autocreate="false">
	<cfargument name="objectManager" hint="The object manager to query" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="javaLoader" hint="The Java loader for loading Java classes" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		var tqlParser = createObject("component", "transfer.com.tql.TQLParser").init(arguments.javaLoader);

		setQueryPool(createObject("component", "transfer.com.tql.collections.QueryPool").init(arguments.javaLoader));
		setSelectStatement(createObject("component", "transfer.com.tql.SelectStatement").init(tqlParser, arguments.objectManager, arguments.datasource));
		return this;
	</cfscript>
</cffunction>

<cffunction name="createQuery" hint="creates a query object for TQL interpretation" access="public" returntype="transfer.com.tql.Query" output="false">
	<cfargument name="tql" hint="The Transfer Query Language query" type="string" required="Yes">
	<cfreturn getQueryPool().getQuery(arguments.tql) />
</cffunction>

<cffunction name="evaluateQuery" hint="Evaluates the query and returns a result" access="public" returntype="query" output="false">
	<cfargument name="query" hint="The query to evaluate" type="transfer.com.tql.Query" required="Yes">
	<cfargument name="onlyRetrievePrimaryKey" hint="Only retrieve primary keys on FROM statement" type="boolean" required="No" default="false">
	<cfargument name="className" hint="The class to retrieve the primary key from" type="string" required="No">
	<cfscript>
		var result = getSelectStatement().selectStatement(argumentCollection=arguments);

		getQueryPool().recycle(query);

		return result;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getSelectStatement" access="private" returntype="SelectStatement" output="false">
	<cfreturn instance.SelectStatement />
</cffunction>

<cffunction name="setSelectStatement" access="private" returntype="void" output="false">
	<cfargument name="SelectStatement" type="SelectStatement" required="true">
	<cfset instance.SelectStatement = arguments.SelectStatement />
</cffunction>

<cffunction name="getQueryPool" access="private" returntype="transfer.com.tql.collections.QueryPool" output="false">
	<cfreturn instance.QueryPool />
</cffunction>

<cffunction name="setQueryPool" access="private" returntype="void" output="false">
	<cfargument name="QueryPool" type="transfer.com.tql.collections.QueryPool" required="true">
	<cfset instance.QueryPool = arguments.QueryPool />
</cffunction>

</cfcomponent>