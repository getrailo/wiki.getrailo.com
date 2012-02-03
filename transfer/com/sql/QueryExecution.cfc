<!--- Document Information -----------------------------------------------------

Title:      QueryExecution.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    An execution object of a query

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/07/2007		Created

------------------------------------------------------------------------------->
<cfcomponent hint="An execution object of a query" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="QueryExecution" output="false">
	<cfargument name="datasource" hint="the datasource to execute against" type="transfer.com.sql.Datasource" required="Yes">
	<cfscript>
		variables.instance = StructNew();

		clean();
		setDatasource(arguments.datasource);

		return this;
	</cfscript>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setQueryCollection(arguments.memento.query);
	</cfscript>
</cffunction>

<cffunction name="setParam" hint="Sets a mapped parameter" access="public" returntype="void" output="false">
	<cfargument name="name" hint="The name of the mapping" type="string" required="Yes">
	<cfargument name="value" hint="The value of the mapping, required if 'null' is false" type="any" required="false">
	<cfargument name="list" hint="if the mapped value is a list" type="boolean" required="No" default="false">
	<cfargument name="isNull" hint="If the value is actually null" type="boolean" required="No" default="false">
	<cfargument name="operator" hint="if this exists, set the equality operator." type="string" required="No">
	<cfargument name="mapValueReplace" hint="a string to replacce the mapped value with" type="string" required="No">
	<cfscript>
		//no error checking, as if anything goes wrong, we'll get a run time error below.

		StructInsert(getMappedParamCollection(), arguments.name, arguments, true);
	</cfscript>
</cffunction>

<cffunction name="execute" hint="simply executes the query" access="public" returntype="void" output="false">
	<cfscript>
		executeQuery();
	</cfscript>
</cffunction>

<cffunction name="executeQuery" hint="executes the query and returns the last Select query result, if no query available, returns 0" access="public" returntype="any" output="false">
	<cfscript>
		var queryResult = 0;
		var queryValue = 0;
		var queryCollection = getQueryCollection();
		var len = ArrayLen(queryCollection);
		var counter = 0;
		var evaluation = 0;
		var eCounter = 0;
		var eLen = 0;
		var block = 0;
		var param = 0;
		var value = 0;
	</cfscript>
	<cfloop from="1" to="#len#" index="counter">
		<cfset evaluation = queryCollection[counter] />
		<cfquery name="queryValue" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
			<cfset eLen = ArrayLen(evaluation) />
			<cfloop from="1" to="#eLen#" index="eCounter">
				<cfset block = evaluation[eCounter] />
				#PreserveSingleQuotes(block.preSQL)#
				<cfif StructKeyExists(block, "mapParam")>
					<cfset param = getMappedParam(block.mapparam.name) />
					<cfif StructKeyExists(param, "operator")>
						#param.operator#
					</cfif>
					<cfif StructKeyExists(param, "mapValueReplace")>
						#param.mapValueReplace#
					<cfelse>
						<cfset value = 0/>
						<cfif StructKeyExists(param, "value")>
							<cfset value = param.value />
						</cfif>
						<cfif block.mapparam.type eq "date">
							<cfqueryparam value="#value#" cfsqltype="cf_sql_timestamp" list="#param.list#" null="#param.isNull#">
						<cfelseif block.mapparam.type eq "numeric">
							<cfqueryparam value="#value#" cfsqltype="cf_sql_float" list="#param.list#" null="#param.isNull#">
						<cfelseif block.mapparam.type eq "boolean">
							<cfqueryparam value="#value#" cfsqltype="cf_sql_bit" list="#param.list#" null="#param.isNull#">
						<cfelseif block.mapparam.type eq "binary">
							<cfif param.isNull and getDatasource().getDatabaseType() eq "postgresql">
								<!--- postgres throws a weird error otherwise --->
								NULL
							<cfelse>
								<cfqueryparam value="#value#" cfsqltype="cf_sql_blob" list="#param.list#" null="#param.isNull#">
							</cfif>
						<cfelse>
							<cfqueryparam value="#value#" cfsqltype="cf_sql_varchar" list="#param.list#" null="#param.isNull#">
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
		</cfquery>
		<cfif isDefined("queryValue") AND isQuery(queryValue)>
			<cfset queryResult = queryValue />
		</cfif>
	</cfloop>
	<cfreturn queryResult />
</cffunction>

<cffunction name="clean" hint="clean the execution for reuse" access="public" returntype="void" output="false">
	<cfscript>
		setQueryCollection(ArrayNew(1));
		setMappedParamCollection(StructNew());
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getMappedParam" hint="returns a mapped param" access="private" returntype="struct" output="false">
	<cfargument name="name" hint="the name of the mapped param" type="string" required="Yes">
	<cfreturn StructFind(getMappedParamCollection(), arguments.name) />
</cffunction>

<cffunction name="getMappedParamCollection" access="private" returntype="struct" output="false">
	<cfreturn instance.MappedParamCollection />
</cffunction>

<cffunction name="setMappedParamCollection" access="private" returntype="void" output="false">
	<cfargument name="MappedParamCollection" type="struct" required="true">
	<cfset instance.MappedParamCollection = arguments.MappedParamCollection />
</cffunction>

<cffunction name="getQueryCollection" access="private" returntype="array" output="false">
	<cfreturn instance.QueryCollection />
</cffunction>

<cffunction name="setQueryCollection" access="private" returntype="void" output="false">
	<cfargument name="QueryCollection" type="array" required="true">
	<cfset instance.QueryCollection = arguments.QueryCollection />
</cffunction>

<cffunction name="getDatasource" access="private" returntype="Datasource" output="false">
	<cfreturn instance.Datasource />
</cffunction>

<cffunction name="setDatasource" access="private" returntype="void" output="false">
	<cfargument name="Datasource" type="Datasource" required="true">
	<cfset instance.Datasource = arguments.Datasource />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>