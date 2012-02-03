<!--- Document Information -----------------------------------------------------

Title:      From.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Evaluates the from part of select statements

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		26/02/2007		Created

------------------------------------------------------------------------------->

<cfcomponent name="From" hint="Evaluates the from part of select statements" extends="AbstractBaseWalker" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="evaluateFromAST" hint="walks the tree, and makes a array of structs that represent the FROM SQL and the mapped values" access="public" returntype="array" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<!--- use a linked list, as it's better for perforance, and because it passed by reference --->
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="distinctMode" hint="If to make the select distinct or not" type="boolean" required="Yes">
	<cfargument name="pastClassIdentifierNodes" hint="java.util.LinkedList:keeps track of all previous class identifiers" type="any" required="no" default="#createObject('java', 'java.util.LinkedList').init()#">
	<cfscript>
		var child = 0;
		var counter = 0;
		var object = 0;

		//decision area
		if(arguments.tree.getType() eq getTQLParser().getNodeType("CLASS_IDENTIFIER"))
		{
			object = getObjectManager().getObject(arguments.tree.getText());
			arguments.buffer.append(" ");
			arguments.buffer.append(object.getTable());

			ArrayAppend(arguments.pastClassIdentifierNodes, arguments.tree);
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("JOIN"))
		{
			return evaluateFromJoinAST(arguments.tree,
										arguments.aliasMap,
										arguments.evaluation,
										arguments.buffer,
										arguments.pastClassIdentifierNodes,
										arguments.aliasColumns,
										arguments.distinctMode
										);
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("WHERE"))
		{
			return arguments.evaluation;
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("ORDER"))
		{
			return arguments.evaluation;
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("AS"))
		{
			/*
			Oracle doesn't like the 'as' on the table alias :oP
			Stupid Oracle.
			*/
			return arguments.evaluation;
		}
		else
		{
			arguments.buffer.append(" ");
			arguments.buffer.append(arguments.tree.getText());
		}

		for(; counter lt arguments.tree.getChildCount(); counter = counter + 1)
		{
			child = arguments.tree.getChild(JavaCast("int", counter));
			arguments.evaluation = evaluateFromAST(child,
													arguments.aliasMap,
													arguments.evaluation,
													arguments.buffer,
													arguments.aliasColumns,
													arguments.distinctMode,
													arguments.pastClassIdentifierNodes);
		}

		return arguments.evaluation;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="evaluateFromJoinAST" hint="walks the subtree tree, and makes the join SQL" access="private" returntype="array" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="pastClassIdentifierNodes" hint="keeps track of all previous class identifiers" type="any" required="yes">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="distinctMode" hint="If to make the select distinct or not" type="boolean" required="Yes">
	<cfscript>
		var child = 0;
		var counter = 0;
		var object = 0;
		var alias = 0;
		var iterator = 0;
		var pastNode = 0;
		var pastObject = 0;
		var pastAlias = 0;

		//decision area
		if(arguments.tree.getType() eq getTQLParser().getNodeType("CLASS_IDENTIFIER"))
		{
			return evaluateFromAST(arguments.tree, arguments.aliasMap, arguments.evaluation, arguments.buffer, arguments.pastClassIdentifierNodes);
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("JOIN"))
		{
			return getJoin().evaluateJoinAST(arguments.tree,
											arguments.aliasMap,
											arguments.evaluation,
											arguments.buffer,
											arguments.pastClassIdentifierNodes,
											arguments.aliasColumns,
											arguments.distinctMode
											);
		}

		for(; counter lt arguments.tree.getChildCount(); counter = counter + 1)
		{
			child = arguments.tree.getChild(JavaCast("int", counter));

			arguments.evaluation = evaluateFromJoinAST(child,
														arguments.aliasMap,
														arguments.evaluation,
														arguments.buffer,
														arguments.pastClassIdentifierNodes,
														arguments.aliasColumns,
														arguments.distinctMode
														);
		}

		return arguments.evaluation;
	</cfscript>
</cffunction>


</cfcomponent>