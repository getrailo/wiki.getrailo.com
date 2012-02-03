<!--- Document Information -----------------------------------------------------

Title:      SelectColumn.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Resolves select columns

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		26/02/2007		Created

------------------------------------------------------------------------------->
<cfcomponent name="SelectColumn" hint="Resolves select columns" extends="AbstractBaseWalker" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="evaluateSelectAST" hint="walks the tree, and makes a array of structs that represent the Select SQL and the mapped values" access="public" returntype="array" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="distinctMode" hint="If to make the select distinct or not" type="boolean" required="Yes">
	<cfargument name="selectAST" hint="Storage for the top level, select AST, for asterisks" type="any" required="No" default="">
	<cfargument name="usedColumnAliases" hint="java.util.ArrayList:The column aliases that have already been used" type="any" required="false" default="#createObject('java', 'java.util.ArrayList').init()#">
	<cfscript>
		var child = 0;
		var counter = 0;
		var property = 0;

		//getTqlParser().dumpTree(arguments.tree);

		if(arguments.tree.getType() eq getTQLParser().getNodeType("PROPERTY_IDENTIFIER"))
		{
			property = getProperty().evaluatePropertyIdentifier(arguments.tree.getText(), arguments.aliasMap, arguments.buffer);

			if(NOT arguments.tree.getChildCount() AND arguments.aliasColumns AND property.getColumn() neq property.getName())
			{
				arguments.buffer.append(" as ");
				arguments.buffer.append(property.getName());
				ArrayAppend(arguments.usedColumnAliases, property.getName());
			}
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("FROM"))
		{
			return arguments.evaluation;
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("WHERE"))
		{
			return arguments.evaluation;
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("ORDER"))
		{
			return arguments.evaluation;
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("ASTERISK"))
		{
			arguments.buffer.append(" ");
			evaluateSelectColumnsFromAST(tree=arguments.selectAST,
										evaluation=arguments.evaluation,
										buffer=arguments.buffer,
										aliasColumns=arguments.aliasColumns,
										usedColumnAliases=arguments.usedColumnAliases,
										distinctMode=arguments.distinctMode,
										ignoreSelect=true
										);
		}
		else
		{
			arguments.buffer.append(" ");
			arguments.buffer.append(arguments.tree.getText());

			if(arguments.tree.getType() eq getTQLParser().getNodeType("SELECT"))
			{
				arguments.selectAST = arguments.tree;
				if(arguments.distinctMode)
				{
					arguments.buffer.append(" distinct ");
				}
			}
			else if(arguments.tree.getType() eq getTQLParser().getNodeType("ALIAS"))
			{
				ArrayAppend(arguments.usedColumnAliases, arguments.tree.getText());
			}
		}
		/*
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("AS"))
		{
			//do nothing, we'll ignore it, not all db's like "as"
		}
		*/

		for(; counter lt arguments.tree.getChildCount(); counter = counter + 1)
		{
			child = arguments.tree.getChild(JavaCast("int", counter));

			arguments.evaluation = evaluateSelectAST(child, arguments.aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode, arguments.selectAST, arguments.usedColumnAliases);
		}

		return arguments.evaluation;
	</cfscript>
</cffunction>

<cffunction name="evaluateSelectColumnsFromAST" hint="builds a list of select columns from the fromAST" access="public" returntype="struct" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="distinctMode" hint="If to make the select distinct or not" type="boolean" required="Yes">
	<!--- used a java object, so it is passed by reference --->
	<cfargument name="isFirstColumn" hint="java.lang.Boolean: is it the first column" type="any" required="No" default="#createObject('java', 'java.lang.Boolean').init(JavaCast('boolean', 1))#">
	<cfargument name="usedColumnAliases" hint="java.util.ArrayList:The column aliases that have already been used" type="any" required="false" default="#createObject('java', 'java.util.ArrayList').init()#">
	<cfargument name="ignoreSelect" hint="whether or not to display the select clause" type="boolean" required="No" default="false">
	<cfscript>
		var child = 0;
		var counter = 0;
		var object = 0;
		var property = 0;
		var propertyIterator = 0;
		var table = 0;
		var currentTree = arguments.tree;
		var primaryKey = 0;

		//decision area
		if(currentTree.getType() eq getTQLParser().getNodeType("CLASS_IDENTIFIER"))
		{
			object = getObjectManager().getObject(currentTree.getText());
			propertyIterator = object.getPropertyIterator();

			if(currentTree.getChildCount() eq 2 AND currentTree.getChild(1).getType() eq getTQLParser().getNodeType("ALIAS"))
			{
				table = currentTree.getChild(1).getText();
			}
			else
			{
				table = object.getTable();
			}

			while(propertyIterator.hasNext())
			{
				property = propertyIterator.next();

				appendSelectColumnToBuffer(table, property, buffer, arguments.isFirstColumn, arguments.aliasColumns, arguments.usedColumnAliases);
				arguments.isFirstColumn = false;
			}

			primaryKey = object.getPrimaryKey();

			if(NOT primaryKey.getIsComposite())
			{
				appendSelectColumnToBuffer(table, primaryKey, buffer, arguments.isFirstColumn, arguments.aliasColumns, arguments.usedColumnAliases);
				arguments.isFirstColumn = false;
			}
		}
		else if(NOT arguments.ignoreSelect AND currentTree.getType() eq getTQLParser().getNodeType("FROM"))
		{
			arguments.buffer.append("select ");

				if(arguments.distinctMode)
				{
					arguments.buffer.append(" distinct ");
				}
		}
		else if(currentTree.getType() eq getTQLParser().getNodeType("WHERE"))
		{
			return arguments;
		}

		//traversal
		for(; counter lt currentTree.getChildCount(); counter = counter + 1)
		{
			child = currentTree.getChild(JavaCast("int", counter));

			arguments = evaluateSelectColumnsFromAST(child,
													arguments.evaluation,
													arguments.buffer,
													arguments.aliasColumns,
													arguments.distinctMode,
													arguments.isFirstColumn,
													arguments.usedColumnAliases,
													arguments.ignoreSelect
													);
		}

		return arguments;
	</cfscript>
</cffunction>

<cffunction name="evaluateSelectColumnPrimaryKey" hint="evaluates a single column that is the primary key of the class" access="public" returntype="void" output="false">
	<cfargument name="className" hint="The class to retrieve the primary key from" type="string" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="distinctMode" hint="If to make the select distinct or not" type="boolean" required="Yes">evaluateSelectColumnPrimaryKey
	<cfscript>
		var object = getObjectManager().getObject(arguments.className);
		var tableName = 0;
		var keyIterator = StructKeyArray(arguments.aliasMap).iterator();
		var key = 0;
		var aliasFound = false;
		var primaryKey = object.getPrimaryKey();

		arguments.buffer.append("select ");

		if(arguments.distinctMode)
		{
			arguments.buffer.append("distinct ");
		}

		tableName = object.getTable();

		while(keyIterator.hasNext() AND NOT aliasFound)
		{
			key = keyIterator.next();
			if(arguments.aliasMap[key].getClassName() eq object.getClassName())
			{
				//found an alias
				tableName = key;
				break;
			}
		}

		if(primaryKey.getIsComposite())
		{
			writeCompositeKeyColumnsToSelectColumn(arguments.buffer, primaryKey);
		}
		else
		{
			arguments.buffer.append(tableName);
			arguments.buffer.append(".");
			arguments.buffer.append(object.getPrimaryKey().getColumn());

			if(arguments.aliasColumns)
			{
				arguments.buffer.append(" as ");
				arguments.buffer.append(object.getPrimaryKey().getName());
			}
		}
	</cfscript>
</cffunction>

<cffunction name="writeCompositeKeyColumnsToSelectColumn" hint="writes all the composite keys to the select columns" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="primaryKey" hint="the composite primary key" type="transfer.com.object.CompositeKey" required="Yes">
	<cfscript>
		var property = 0;
		var parentOneToMany = 0;
		var manyToOne = 0;
		var iterator = arguments.primaryKey.getPropertyIterator();
		var isFirst = true;

		while(iterator.hasNext())
		{
			property = iterator.next();
			if(NOT isFirst)
			{
				buffer.append(", ");
			}
			isFirst = false;

			//we know this is only for read() ops, so no need to alias
			arguments.buffer.append(property.getColumn());
		}

		iterator = arguments.primaryKey.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			if(NOT isFirst)
			{
				buffer.append(", ");
			}
			isFirst = false;

			//we know this is only for read() ops, so no need to alias
			arguments.buffer.append(manytoone.getLink().getColumn());
		}

		iterator = arguments.primaryKey.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();
			if(NOT isFirst)
			{
				buffer.append(", ");
			}
			isFirst = false;

			//we know this is only for read() ops, so no need to alias
			arguments.buffer.append(parentOneToMany.getLink().getColumn());
		}
	</cfscript>
</cffunction>


<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="appendSelectColumnToBuffer" hint="appends the neccessary column values to the buffer for a property" access="private" returntype="void" output="false">
	<cfargument name="tableName" hint="the name of the table" type="string" required="Yes">
	<cfargument name="property" hint="the property to build the select from" type="transfer.com.object.Property" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="isFirstColumn" hint="If its the first column or not" type="boolean" required="Yes">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="usedColumnAliases" hint="java.util.ArrayList:The column aliases that have already been used" type="any" required="true">
	<cfscript>
		var alias = 0;
		var counter = 1;
		if(NOT arguments.isFirstColumn)
		{
			arguments.buffer.append(", ");
		}

		arguments.buffer.append(arguments.tableName);
		arguments.buffer.append(".");
		arguments.buffer.append(arguments.property.getColumn());

		if(arguments.aliasColumns AND arguments.property.getName() neq arguments.property.getColumn())
		{
			arguments.buffer.append(" as ");

			alias = arguments.property.getName();

			while(arguments.usedColumnAliases.contains(alias))
			{
				alias = arguments.property.getName() & "_" & counter;
				counter = counter + 1;
			}

			arguments.buffer.append(alias);

			ArrayAppend(arguments.usedColumnAliases, alias);
		}
	</cfscript>
</cffunction>

</cfcomponent>