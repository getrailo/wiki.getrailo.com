<!--- Document Information -----------------------------------------------------

Title:      OrderBy.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    walks through order by sections

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		27/02/2007		Created

------------------------------------------------------------------------------->
<cfcomponent name="OrderBy" hint="Order by evaluations" extends="AbstractBaseWalker" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="evaluateOrderByAST" hint="walks the tree, and makes a array of structs that represent the Order By SQL and the mapped values" access="public" returntype="array" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfscript>
		var child = 0;
		var counter = 0;
		var property = 0;

		if(arguments.tree.getType() eq getTQLParser().getNodeType("PROPERTY_IDENTIFIER"))
		{
			property = getProperty().evaluatePropertyIdentifier(arguments.tree.getText(), arguments.aliasMap, arguments.buffer);
		}
		else
		{
			arguments.buffer.append(" ");
			arguments.buffer.append(arguments.tree.getText());
		}

		for(; counter lt arguments.tree.getChildCount(); counter = counter + 1)
		{
			child = arguments.tree.getChild(JavaCast("int", counter));

			arguments.evaluation = evaluateOrderByAST(child, arguments.aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns);
		}

		return arguments.evaluation;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>