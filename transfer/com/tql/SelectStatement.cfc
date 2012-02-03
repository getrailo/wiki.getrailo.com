<!--- Document Information -----------------------------------------------------

Title:      SelectStatement.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Evaluates TQL select statements

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		26/02/2007		Created

------------------------------------------------------------------------------->
<cfcomponent name="SelectStatement" hint="Evaluates select statements">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="SelectStatement" output="false">
	<cfargument name="tqlParser" hint="The tqlParser to generate the AST for the TQL" type="TQLParser" required="Yes">
	<cfargument name="objectManager" hint="The object manager to query" type="transfer.com.object.ObjectManager" required="Yes">
	<cfargument name="datasource" hint="The datasource BO" type="transfer.com.sql.Datasource" required="Yes">
	<cfscript>
		var object = 0;
		var join = 0;
		var property = 0;

		setTQLParser(arguments.tqlParser);
		setObjectManager(arguments.objectManager);
		setDatasource(datasource);
		setEvaluationCache(createObject("component", "transfer.com.tql.collections.EvaluationCache").init());

		object = createObject("component", "transfer.com.tql.walkers.Object").init(getTQLParser(), getObjectManager());

		property = createObject("component", "transfer.com.tql.walkers.Property").init(getTQLParser(), getObjectManager());

		join = createObject("component", "transfer.com.tql.walkers.Join").init(tqlParser=getTQLParser(),
																				objectManager=getObjectManager(),
																				property=property,
																				object=object
																				);

		setSelectColumn(createObject("component", "transfer.com.tql.walkers.SelectColumn").init(tqlParser=getTQLParser(),
																								objectManager=getObjectManager(),
																								property=property));

		setFrom(createObject("component", "transfer.com.tql.walkers.From").init(tqlParser=getTQLParser(),
																				objectManager=getObjectManager(),
																				property=property,
																				object=object,
																				join=join));

		setOrderBy(createObject("component", "transfer.com.tql.walkers.OrderBy").init(tqlParser=getTQLParser(),
																						objectManager=getObjectManager(),
																						property=property));

		setWhere(createObject("component", "transfer.com.tql.walkers.Where").init(tqlParser=getTQLParser(),
																					objectManager=getObjectManager(),
																					property=property,
																					selectStatement=this));

		return this;
	</cfscript>
</cffunction>

<cffunction name="selectStatement" hint="returns a query from a TQL Select statement" access="public" returntype="query" output="false">
	<cfargument name="query" hint="The TQL query object" type="transfer.com.tql.Query" required="Yes">
	<cfargument name="onlyRetrievePrimaryKey" hint="Only retrieve primary keys on FROM statement" type="boolean" required="Yes">
	<cfargument name="className" hint="The class to retrieve the primary key from" type="string" required="No" default="">
	<cfscript>
		var ast = 0;
		var buffer = createObject("java", "java.lang.StringBuffer").init();
		//use an evaluation, so CF doesn't copy by value every 2nd step
		var evaluation = createObject("java", "java.util.ArrayList").init();
		var data = StructNew();

		if(arguments.query.getCacheEvaluation() AND getEvaluationCache().has(arguments.query))
		{
			evaluation = getEvaluationCache().get(arguments.query);

			//if not evaluation, returns an empty array
			if(NOT ArrayIsEmpty(evaluation))
			{
				return executeEvaluation(arguments.query, evaluation);
			}
		}

		ast = getTQLParser().selectStatement(arguments.query.getTQL());

		evaluation = evaluateSelectStatement(ast,
											evaluation,
											buffer,
											arguments.query.getAliasColumns(),
											arguments.query.getDistinctMode(),
											arguments.onlyRetrievePrimaryKey,
											arguments.className);

		//append the last buffer value to the evaluation, as we know we've hit the end of the nodes
		data.preSQL = buffer.toString();

		ArrayAppend(evaluation, data);

		if(arguments.query.getCacheEvaluation())
		{
			getEvaluationCache().add(arguments.query, evaluation);
		}

		return executeEvaluation(arguments.query, evaluation);
	</cfscript>
</cffunction>

<cffunction name="evaluateSelectStatement" hint="Evaluates all sorts of select statements" access="public" returntype="array" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="distinctMode" hint="If to make the select distinct or not" type="boolean" required="Yes">
	<cfargument name="onlyRetrievePrimaryKey" hint="Only retrieve primary keys on FROM statement" type="boolean" required="false" default="false">
	<cfargument name="className" hint="The class to retrieve the primary key from" type="string" required="No" default="">
	<cfscript>
		var aliasMap = 0;

		if(arguments.tree.getType() eq getTQLParser().getNodeType("FROM")) //starts with 'from'
		{
			aliasMap = evaluateAliasMapFromAST(arguments.tree);

			if(NOT arguments.onlyRetrievePrimaryKey)
			{
				getSelectColumn().evaluateSelectColumnsFromAST(arguments.tree, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
			}
			else
			{
				getSelectColumn().evaluateSelectColumnPrimaryKey(arguments.className, aliasMap, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
			}

			arguments.evaluation = getFrom().evaluateFromAST(arguments.tree,
													aliasMap,
													arguments.evaluation,
													arguments.buffer,
													arguments.aliasColumns,
													arguments.distinctMode);

			arguments.evaluation = evaluateTopLevelAST(arguments.tree, aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("SELECT"))
		{
			aliasMap = evaluateAliasMapFromAST(arguments.tree);
			arguments.evaluation = getSelectColumn().evaluateSelectAST(arguments.tree, aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
			arguments.evaluation = evaluateTopLevelAST(arguments.tree, aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
		}
		else //dump it, 'cause I dunno what to do with it yet
		{
			getTQLParser().dumpTree(arguments.tree);
		}

		return arguments.evaluation;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<cffunction name="executeEvaluation" hint="execute the evaluations query structure" access="private" returntype="query" output="false">
	<cfargument name="query" hint="The TQL query object" type="transfer.com.tql.Query" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfset var qTQLQuery = 0 />
	<cfset var iterator = arguments.evaluation.iterator() />
	<cfset var block = 0 />
	<cfset var param = 0>
	<cfset var value = 0>

	<cfquery name="qTQLQuery" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
		<cfloop condition="#iterator.hasNext()#">
			<cfset block = iterator.next() />
			#block.preSQL#
			<cfif structKeyExists(block, "mappedParam")>
				<cfscript>
					param = query.getParam(block.mappedParam);
					if(StructKeyExists(param, "value"))
					{
						value = param.value;
					}
				</cfscript>
				<cfswitch expression="#param.type#">
					<cfcase value="date">
						<cfqueryparam value="#value#" cfsqltype="cf_sql_timestamp" list="#param.list#" null="#param.isNull#">
					</cfcase>
					<cfcase value="numeric">
						<cfqueryparam value="#value#" cfsqltype="cf_sql_float" list="#param.list#" null="#param.isNull#">
					</cfcase>
					<cfcase value="boolean">
						<cfqueryparam value="#value#" cfsqltype="cf_sql_bit" list="#param.list#" null="#param.isNull#">
					</cfcase>
					<cfdefaultcase>
						<cfqueryparam value="#value#" cfsqltype="cf_sql_varchar" list="#param.list#" null="#param.isNull#">
					</cfdefaultcase>
				</cfswitch>
			</cfif>
		</cfloop>
	</cfquery>
	<cfreturn qTQLQuery />
</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="evaluateTopLevelAST" hint="Loops around the AST resolving the top level" access="private" returntype="array" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="distinctMode" hint="If to make the select distinct or not" type="boolean" required="Yes">
	<cfscript>
		var child = 0;
		var counter = 0;

		for(; counter lt arguments.tree.getChildCount(); counter = counter + 1)
		{
			child = arguments.tree.getChild(JavaCast("int", counter));

			if(child.getType() eq getTQLParser().getNodeType("FROM"))
			{
				arguments.evaluation = getFrom().evaluateFromAST(child,
																	arguments.aliasMap,
																	arguments.evaluation,
																	arguments.buffer,
																	arguments.aliasColumns,
																	arguments.distinctMode);
			}
			else if(child.getType() eq getTQLParser().getNodeType("WHERE"))
			{
				arguments.evaluation = getWhere().evaluateWhereAST(child, arguments.aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
			}
			else if(child.getType() eq getTQLParser().getNodeType("ORDER"))
			{
				arguments.evaluation = getOrderBy().evaluateOrderByAST(child, arguments.aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns);
			}
		}

		return arguments.evaluation;
	</cfscript>
</cffunction>

<cffunction name="evaluateAliasMapFromAST" hint="walks the tree, and makes a struct of the aliases back to the Objects" access="private" returntype="struct" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="aliasMap" hint="The array of from evaluated values" type="struct" required="false" default="#StructNew()#">
	<cfscript>
		var child = 0;
		var counter = 0;
		var object = 0;

		//decisions
		if(
			(arguments.tree.getType() eq getTQLParser().getNodeType("CLASS_IDENTIFIER"))
			AND
			(arguments.tree.getChildCount() eq 2)
			AND
			(arguments.tree.getChild(1).getType() eq getTQLParser().getNodeType("ALIAS"))
			)
		{
			object = getObjectManager().getObject(arguments.tree.getText());

			arguments.aliasMap[arguments.tree.getChild(1).getText()] = object;
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("AS"))
		{
			return arguments.aliasMap; //ignore
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("ALIAS"))
		{
			return arguments.aliasMap; //ignore
		}

		for(; counter lt arguments.tree.getChildCount(); counter = counter + 1)
		{
			child = arguments.tree.getChild(JavaCast("int", counter));

			arguments.aliasMap = evaluateAliasMapFromAST(child, arguments.aliasMap);
		}

		return arguments.aliasMap;
	</cfscript>
</cffunction>

<cffunction name="getTQLParser" access="private" returntype="TQLParser" output="false">
	<cfreturn instance.TQLParser />
</cffunction>

<cffunction name="setTQLParser" access="private" returntype="void" output="false">
	<cfargument name="TQLParser" type="TQLParser" required="true">
	<cfset instance.TQLParser = arguments.TQLParser />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getDatasource" access="private" returntype="transfer.com.sql.Datasource" output="false">
	<cfreturn instance.Datasource />
</cffunction>

<cffunction name="setDatasource" access="private" returntype="void" output="false">
	<cfargument name="Datasource" type="transfer.com.sql.Datasource" required="true">
	<cfset instance.Datasource = arguments.Datasource />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

<cffunction name="getSelectColumn" access="private" returntype="transfer.com.tql.walkers.SelectColumn" output="false">
	<cfreturn instance.SelectColumn />
</cffunction>

<cffunction name="setSelectColumn" access="private" returntype="void" output="false">
	<cfargument name="SelectColumn" type="transfer.com.tql.walkers.SelectColumn" required="true">
	<cfset instance.SelectColumn = arguments.SelectColumn />
</cffunction>

<cffunction name="getFrom" access="private" returntype="transfer.com.tql.walkers.From" output="false">
	<cfreturn instance.From />
</cffunction>

<cffunction name="setFrom" access="private" returntype="void" output="false">
	<cfargument name="From" type="transfer.com.tql.walkers.From" required="true">
	<cfset instance.From = arguments.From />
</cffunction>

<cffunction name="getOrderBy" access="private" returntype="transfer.com.tql.walkers.OrderBy" output="false">
	<cfreturn instance.OrderBy />
</cffunction>

<cffunction name="setOrderBy" access="private" returntype="void" output="false">
	<cfargument name="OrderBy" type="transfer.com.tql.walkers.OrderBy" required="true">
	<cfset instance.OrderBy = arguments.OrderBy />
</cffunction>

<cffunction name="getWhere" access="private" returntype="transfer.com.tql.walkers.Where" output="false">
	<cfreturn instance.Where />
</cffunction>

<cffunction name="setWhere" access="private" returntype="void" output="false">
	<cfargument name="Where" type="transfer.com.tql.walkers.Where" required="true">
	<cfset instance.Where = arguments.Where />
</cffunction>

<cffunction name="getEvaluationCache" access="private" returntype="transfer.com.tql.collections.EvaluationCache" output="false">
	<cfreturn instance.EvaluationCache />
</cffunction>

<cffunction name="setEvaluationCache" access="private" returntype="void" output="false">
	<cfargument name="EvaluationCache" type="transfer.com.tql.collections.EvaluationCache" required="true">
	<cfset instance.EvaluationCache = arguments.EvaluationCache />
</cffunction>

</cfcomponent>