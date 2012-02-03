<!--- Document Information -----------------------------------------------------

Title:      QueryExecutionPool.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Pool for Query Executions

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		18/07/2007		Created

------------------------------------------------------------------------------->
<cfcomponent hint="Pool for Query Executions" extends="transfer.com.collections.AbstractBaseSemiSoftRefObjectPool" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="QueryExecutionPool" output="false">
	<cfargument name="datasource" hint="the datasource to execute against" type="transfer.com.sql.Datasource" required="Yes" _autocreate="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		//10 hard referenced items
		setDatasource(arguments.datasource);

		super.init(10, arguments.javaLoader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getQueryExecution" hint="Gives you a Query Execution" access="public" returntype="transfer.com.sql.QueryExecution" output="false">
	<cfargument name="queryEvaluation" hint="the evaluation of a query" type="array" required="Yes">
	<cfscript>
		var execution = 0;
		var memento = StructNew();

		execution = pop();

		memento.query = arguments.queryEvaluation;
		execution.setMemento(memento);

		return execution;
	</cfscript>
</cffunction>

<cffunction name="recycle" hint="recycles the event back in" access="public" returntype="void" output="false">
	<cfargument name="execution" hint="query execution to be recycled" type="transfer.com.sql.QueryExecution" required="Yes">
	<cfscript>
		arguments.execution.clean();
		push(arguments.execution);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getNewObject" hint="virtual method: returns the new CFC to repopulate the pool" access="private" returntype="transfer.com.sql.QueryExecution" output="false">
	<cfreturn createObject("component", "transfer.com.sql.QueryExecution").init(getDatasource()) />
</cffunction>

<cffunction name="getDatasource" access="private" returntype="transfer.com.sql.Datasource" output="false">
	<cfreturn instance.Datasource />
</cffunction>

<cffunction name="setDatasource" access="private" returntype="void" output="false">
	<cfargument name="Datasource" type="transfer.com.sql.Datasource" required="true">
	<cfset instance.Datasource = arguments.Datasource />
</cffunction>

</cfcomponent>