<!--- Document Information -----------------------------------------------------

Title:      Query.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Object for maintining SQL query state

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/07/2007		Created

------------------------------------------------------------------------------->
<cfcomponent displayname="Query" hint="Object for maintaining a SQL query state" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="queryExecPool" hint="the query execution pool" type="transfer.com.sql.collections.QueryExecutionPool" required="Yes">
	<cfscript>
		variables.instance = StructNew();

		setQueryCollection(createArrayList());
		setSQLBuffer(createObject("java", "java.lang.StringBuffer").init());
		setQueryExecutionPool(arguments.queryExecPool);

		return this;
	</cfscript>
</cffunction>

<cffunction name="start" hint="Start a new query" access="public" returntype="void" output="false">
	<cfscript>

		if(NOT ArrayIsEmpty(getQueryCollection()))
		{
			stop();
		}

		populateNextQuery();
	</cfscript>
</cffunction>

<cffunction name="appendSQL" hint="append some sql" access="public" returntype="void" output="false">
	<cfargument name="sql" hint="" type="string" required="Yes">
	<cfscript>
		getSQLBuffer().append(sql);
	</cfscript>
</cffunction>

<cffunction name="mapParam" hint="maps a parameter" access="public" returntype="void" output="false">
	<cfargument name="name" hint="the name of the parameter" type="string" required="Yes">
	<cfargument name="type" hint="the type of the param, string, numeric, GUID, UUID, boolean, date" type="string" required="Yes">
	<cfscript>
		var evaluationBlock = getCurrentEvaluationBlock();
		evaluationBlock.mapParam = arguments;

		stop();

		populateNextEvaluation();
	</cfscript>
</cffunction>

<cffunction name="stop" hint="stop building your query execution" access="public" returntype="void" output="false">
	<cfscript>
		var evaluationBlock = 0;
		evaluationBlock = getCurrentEvaluationBlock();
		evaluationBlock.preSQL = getSQLBuffer().toString();

		getSQLBuffer().setLength(0);
	</cfscript>
</cffunction>

<cffunction name="createExecution" hint="create a query execution for this query" access="public" returntype="transfer.com.sql.QueryExecution" output="false">
	<cfscript>
		return getQueryExecutionPool().getQueryExecution(getQueryCollection());
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getCurrentEvaluationBlock" hint="gets the latest eval block" access="public" returntype="struct" output="false">
	<cfscript>
		var queryCollection = getQueryCollection();
		var evaluation = queryCollection[ArrayLen(queryCollection)];

		return evaluation[ArrayLen(evaluation)];
	</cfscript>
</cffunction>

<cffunction name="populateNextQuery" hint="sets up the next query block" access="private" returntype="void" output="false">
	<cfscript>
		var evaluation = createArrayList();
		ArrayAppend(evaluation, StructNew());
		ArrayAppend(getQueryCollection(), evaluation);
	</cfscript>
</cffunction>

<cffunction name="populateNextEvaluation" hint="populates the next evaluation" access="private" returntype="void" output="false">
	<cfscript>
		var queryCollection = getQueryCollection();
		var evaluation = queryCollection[ArrayLen(queryCollection)];

		ArrayAppend(evaluation, structNew());
	</cfscript>
</cffunction>

<cffunction name="createArrayList" hint="use arraylists, as we want to pass by reference" access="private" returntype="array" output="false">
	<cfscript>
		/*
		var Collections = createObject("java", "java.util.Collections");
		return Collections.synchronizedList(createObject("java", "java.util.ArrayList").init());
		*/
		return createObject("java", "java.util.ArrayList").init();
	</cfscript>
</cffunction>

<cffunction name="getSQLBuffer" access="private" returntype="any" output="false">
	<cfreturn instance.SQLBuffer />
</cffunction>

<cffunction name="setSQLBuffer" access="private" returntype="void" output="false">
	<cfargument name="SQLBuffer" type="any" required="true">
	<cfset instance.SQLBuffer = arguments.SQLBuffer />
</cffunction>

<cffunction name="getQueryCollection" access="private" returntype="array" output="false">
	<cfreturn instance.QueryCollection />
</cffunction>

<cffunction name="setQueryCollection" access="private" returntype="void" output="false">
	<cfargument name="QueryCollection" type="array" required="true">
	<cfset instance.QueryCollection = arguments.QueryCollection />
</cffunction>

<cffunction name="getQueryExecutionPool" access="private" returntype="transfer.com.sql.collections.QueryExecutionPool" output="false">
	<cfreturn instance.QueryExecutionPool />
</cffunction>

<cffunction name="setQueryExecutionPool" access="private" returntype="void" output="false">
	<cfargument name="QueryExecutionPool" type="transfer.com.sql.collections.QueryExecutionPool" required="true">
	<cfset instance.QueryExecutionPool = arguments.QueryExecutionPool />
</cffunction>

</cfcomponent>