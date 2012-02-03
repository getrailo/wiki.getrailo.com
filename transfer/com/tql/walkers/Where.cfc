<!--- Document Information -----------------------------------------------------

Title:      Where.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Walks the where expresion

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		27/02/2007		Created

------------------------------------------------------------------------------->
<cfcomponent hint="Walks the where expresion" extends="AbstractBaseWalker" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="evaluateWhereAST" hint="walks the tree, and makes a array of structs that represent the Where SQL and the mapped values" access="public" returntype="array" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="distinctMode" hint="If to make the select distinct or not" type="boolean" required="Yes">
	<cfscript>
		var child = 0;
		var counter = 0;
		var data = 0;

		if(arguments.tree.getType() eq getTQLParser().getNodeType("PROPERTY_IDENTIFIER"))
		{
			getProperty().evaluatePropertyIdentifier(arguments.tree.getText(), arguments.aliasMap, arguments.buffer);
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("MAPPED_PARAM"))
		{
			data = StructNew();
			data.preSQL = arguments.buffer.toString();
			data.mappedParam = replace(arguments.tree.getText(), ":", "");

			arguments.buffer.setLength(0);

			ArrayAppend(arguments.evaluation, data);
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("SELECT"))
		{
			return getSelectStatement().evaluateSelectStatement(arguments.tree, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
		}
		else
		{
			arguments.buffer.append(" ");
			arguments.buffer.append(arguments.tree.getText());
		}

		for(; counter lt arguments.tree.getChildCount(); counter = counter + 1)
		{
			child = arguments.tree.getChild(JavaCast("int", counter));

			arguments.evaluation = evaluateWhereAST(child, arguments.aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
		}

		return arguments.evaluation;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>