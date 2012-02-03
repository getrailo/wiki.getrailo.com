<!--- Document Information -----------------------------------------------------

Title:      Where.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    walks the join expressions

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		13/03/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Walks the join expresion" extends="AbstractBaseWalker" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="evaluateJoinAST" hint="evaluates a join AST" access="public" returntype="array" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="pastClassIdentifierNodes" hint="keeps track of all previous class identifiers" type="any" required="yes">
	<cfargument name="aliasColumns" hint="to alias columns or not" type="boolean" required="Yes">
	<cfargument name="distinctMode" hint="If to make the select distinct or not" type="boolean" required="Yes">
	<cfscript>
		var state = getJoinState(arguments.tree);

		if(state.context eq "auto")
		{
			evaluateInterimAutoJoin(state.object, state.alias, arguments.buffer, arguments.pastClassIdentifierNodes, state.innerJoin, state.outerJoinType);
		}
		else if(state.context eq "composite")
		{
			evaluateInterimCompositeJoin(arguments.tree,
											state.object,
											state.alias,
											arguments.aliasMap,
											arguments.buffer,
											arguments.pastClassIdentifierNodes,
											state.innerjoin,
											state.outerJoinType);
		}

		//draw the join, based on the join state
		if(state.innerJoin)
		{
			arguments.buffer.append(" inner ");
		}
		else
		{
			arguments.buffer.append(" ");
			arguments.buffer.append(state.outerJoinType);
			arguments.buffer.append(" outer ");
		}

		arguments.buffer.append("join ");


		arguments.buffer.append(state.object.getTable());
		if(Len(state.alias))
		{
			arguments.buffer.append(" ");
			arguments.buffer.append(state.alias);
		}

		if(state.context eq "auto")
		{
			arguments.evaluation = evaluateAutoJoin(state.object, state.alias, arguments.evaluation, arguments.buffer, arguments.pastClassIdentifierNodes);
		}
		else if(state.context eq "composite")
		{
			evaluateOnCompositeJoin(arguments.tree, state.object, state.alias, arguments.aliasMap, arguments.buffer, arguments.pastClassIdentifierNodes);
		}
		else if(state.context eq "identifer")
		{
			arguments.evaluation = evaluateIdentifierJoinAST(arguments.tree, arguments.aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
		}

		//push the node of the class on
		ArrayAppend(arguments.pastClassIdentifierNodes, state.classIdentifierNode);

		return arguments.evaluation;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getJoinState" hint="returns a struct with 3 values in it state : [auto|composite|identifier], the object, and the alias (bad cohesian, good performance)" access="private" returntype="struct" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="context" hint="The join context" type="string" required="No" default="auto">
	<cfargument name="object" hint="The object for the join" type="transfer.com.object.Object" required="No">
	<cfargument name="alias" hint="The alias for the object" type="string" required="No" default="">
	<cfargument name="innerJoin" hint="if an inner join" type="boolean" required="No" default="true">
	<cfargument name="outerJoinType" hint="The outer join type, if it exists" type="string" required="No" default="left">
	<cfargument name="classIdentifierNode" hint="The class identifier node to append" type="any" required="No">

	<cfscript>
		var child = 0;
		var counter = 0;
		var localTree = arguments.tree;

		if(localTree.getType() eq getTQLParser().getNodeType("ON_COMPOSITE"))
		{
			arguments.context = "composite";
		}
		else if(localTree.getType() eq getTQLParser().getNodeType("ON_IDENTIFIER"))
		{
			arguments.context = "identifer";
		}
		else if(localTree.getType() eq getTQLParser().getNodeType("CLASS_IDENTIFIER"))
		{
			arguments.object = getObjectManager().getObject(localTree.getText());
			arguments.classIdentifierNode = localTree;
		}
		else if(localTree.getType() eq getTQLParser().getNodeType("ALIAS"))
		{
			arguments.alias = localTree.getText();
		}
		else if(localTree.getType() eq getTQLParser().getNodeType("OUTER"))
		{
			arguments.innerJoin = false;
		}
		else if(localTree.getType() eq getTQLParser().getNodeType("LEFT"))
		{
			arguments.outerJoinType = localTree.getText();
		}
		else if(localTree.getType() eq getTQLParser().getNodeType("RIGHT"))
		{
			arguments.outerJoinType = localTree.getText();
		}

		for(; counter lt localTree.getChildCount(); counter = counter + 1)
		{
			child = localTree.getChild(JavaCast("int", counter));

			arguments.tree = child;

			arguments = getJoinState(argumentCollection=arguments);
		}

		return arguments;
	</cfscript>
</cffunction>

<cffunction name="resolveAlias" hint="if the alias is an empty string, returns the orignal value" access="private" returntype="string" output="false">
	<cfargument name="alias" hint="The alias that is being used" type="string" required="Yes">
	<cfargument name="originalValue" hint="The original value" type="string" required="Yes">
	<cfscript>
		if(Len(arguments.alias))
		{
			return arguments.alias;
		}
		return arguments.originalValue;
	</cfscript>
</cffunction>

<!--- Evaluating --->

<cffunction name="evaluateInterimAutoJoin" hint="evaluates any joining that must be done before joining the actual Object table" access="private" returntype="void" output="false">
	<cfargument name="object" hint="The object to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="alias" hint="The alias" type="string" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="pastClassIdentifierNodes" hint="keeps track of all previous class identifiers" type="any" required="yes">
	<cfargument name="innerJoin" hint="if the join is an inner join" type="boolean" required="Yes">
	<cfargument name="outerJoinType" hint="if the join is an inner join" type="string" required="Yes">
	<cfscript>
		var pastNode = 0;
		var pastObject = 0;
		var pastAlias = 0;

		//we need to do many to many first, to join that interim table
		var iterator = arguments.pastClassIdentifierNodes.iterator();

		while(iterator.hasNext())
		{
			pastNode = iterator.next();
			pastObject = getObjectManager().getObject(pastNode.getText());
			if(pastNode.getChildCount())
			{
				pastAlias = pastNode.getChild(1).getText();
			}
			else
			{
				pastAlias = "";
			}

			//will always be inner join
			resolveManyToManyInterimAutoJoinSQL(pastObject, pastAlias, arguments.object, arguments.alias, arguments.buffer, arguments.innerJoin, arguments.outerJoinType);
		}
	</cfscript>
</cffunction>

<cffunction name="evaluateAutoJoin" hint="evaluates auto joining for a particlar node" access="private" returntype="array" output="false">
	<cfargument name="object" hint="The object to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="alias" hint="The alias" type="string" required="Yes">
	<cfargument name="evaluation" hint="The array of evaluated values" type="array" required="true">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="pastClassIdentifierNodes" hint="keeps track of all previous class identifiers" type="any" required="yes">
	<cfscript>
		var pastNode = 0;
		var pastObject = 0;
		var pastAlias = 0;
		var iterator = arguments.pastClassIdentifierNodes.iterator();
		var on = true;
		while(iterator.hasNext())
		{
			pastNode = iterator.next();
			pastObject = getObjectManager().getObject(pastNode.getText());

			if(pastNode.getChildCount())
			{
				pastAlias = pastNode.getChild(1).getText();
			}
			else
			{
				pastAlias = "";
			}

			on = NOT resolveAutoJoinSQL(pastObject, pastAlias, arguments.object, arguments.alias, arguments.buffer, buildRelationShipCollection(object, pastObject), on);
		}

		return arguments.evaluation;
	</cfscript>
</cffunction>

<cffunction name="evaluateInterimCompositeJoin" hint="evaluate a on composite join" access="private" returntype="struct" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="object" hint="The object to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="alias" hint="The alias" type="string" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="yes">
	<cfargument name="pastClassIdentifierNodes" hint="keeps track of all previous class identifiers" type="any" required="yes">
	<cfargument name="innerJoin" hint="if the join is an inner join" type="boolean" required="Yes">
	<cfargument name="outerJoinType" hint="if the join is an inner join" type="string" required="Yes">
	<cfscript>
		var child = 0;
		var counter = 0;
		var localTree = arguments.tree;
		var objectFrom = 0;
		var class = 0;
		var relationships = 0;
		var aliasFrom = 0;
		var compositeName = 0;
		var listLen = 0;

		//getTQLParser().dumpTree(arguments.tree);

		//decision area
		if(localTree.getType() eq getTQLParser().getNodeType("PROPERTY_IDENTIFIER"))
		{
			listLen = ListLen(localTree.getText(), ".");

			if(listLen eq 1)
			{
				throw("transfer.TQLSyntaxExceptionException",
					"Error with class value '"& localTree.getText() &"' in clause",
					"Class values must resolve to the Class name or the alias. e.g. 'email.Email.emailName'");
			}

			objectFrom = getObject().evaluateObjectIdentifier(localTree.getText(), arguments.aliasMap);
			compositeName = ListGetAt(localTree.getText(), ListLen(localTree.getText(), "."), ".");
			aliasFrom = getObject().evaluateObjectAlias(localTree.getText(), arguments.aliasMap);

			//need a space
			arguments.buffer.append(" ");

			if((object.getClassName() neq objectFrom.getClassName()) OR (arguments.alias neq aliasFrom))
			{
				//build relationship
				resolveCompositeInterimJoinSQL(
												objectFrom=objectFrom,
												aliasFrom=aliasFrom,
												objectTo=arguments.object,
												aliasTo=arguments.alias,
												buffer=arguments.buffer,
												objectFromCompositeName=compositeName,
												innerJoin=arguments.innerJoin,
												outerJoinType=arguments.outerJoinType
												);
			}
			else
			{
				class =  object.getLinkingClassName(compositeName);
				objectFrom = getObjectManager().getObject(class);

				//let's go hunting for the alias, if there is one
				aliasFrom = searchPastIdentifierNodesForAlias(arguments.pastClassIdentifierNodes, class);
				resolveCompositeInterimJoinSQL(
												objectFrom=objectFrom,
												aliasFrom=aliasFrom,
												objectTo=arguments.object,
												aliasTo=arguments.alias,
												buffer=arguments.buffer,
												objectToCompositeName=compositeName,
												innerJoin=arguments.innerJoin,
												outerJoinType=arguments.outerJoinType
												);
			}
		}


		for(; counter lt localTree.getChildCount(); counter = counter + 1)
		{
			child = localTree.getChild(JavaCast("int", counter));
			arguments = evaluateInterimCompositeJoin(child, arguments.object, arguments.alias, arguments.aliasMap, arguments.buffer, arguments.pastClassIdentifierNodes, arguments.innerJoin, arguments.outerJoinType);
		}

		return arguments;
	</cfscript>
</cffunction>

<cffunction name="evaluateOnCompositeJoin" hint="evaluate a on composite join" access="private" returntype="struct" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="object" hint="The object to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="alias" hint="The alias" type="string" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="pastClassIdentifierNodes" hint="keeps track of all previous class identifiers" type="any" required="yes">
	<cfscript>
		var child = 0;
		var counter = 0;
		var localTree = arguments.tree;
		var objectFrom = 0;
		var class = 0;
		var relationships = 0;
		var aliasFrom = 0;
		var compositeName = 0;
		var listLen = 0;

		//decision area
		if(localTree.getType() eq getTQLParser().getNodeType("PROPERTY_IDENTIFIER"))
		{
			listLen = ListLen(localTree.getText(), ".");

			if(listLen eq 1)
			{
					throw("transfer.TQLSyntaxExceptionException",
					"Error with class value '"& localTree.getText() &"' in clause",
					"Class values must resolve to the Class name or the alias. e.g. 'email.Email.emailName'");
			}

			objectFrom = getObject().evaluateObjectIdentifier(localTree.getText(), arguments.aliasMap);
			compositeName = ListGetAt(localTree.getText(), listLen, ".");
			aliasFrom = getObject().evaluateObjectAlias(localTree.getText(), arguments.aliasMap);

			//need a space
			arguments.buffer.append(" ");

			if((object.getClassName() neq objectFrom.getClassName()) OR (arguments.alias neq aliasFrom))
			{
				//build relationship
				resolveCompositeJoinSQL(
										objectFrom=objectFrom,
										aliasFrom=aliasFrom,
										objectTo=arguments.object,
										aliasTo=arguments.alias,
										buffer=arguments.buffer,
										objectFromCompositeName=compositeName);
			}
			else
			{
				class =  object.getLinkingClassName(compositeName);
				objectFrom = getObjectManager().getObject(class);

				//let's go hunting for the alias, if there is one
				aliasFrom = searchPastIdentifierNodesForAlias(arguments.pastClassIdentifierNodes, class);
				resolveCompositeJoinSQL(
										objectFrom=objectFrom,
										aliasFrom=aliasFrom,
										objectTo=arguments.object,
										aliasTo=arguments.alias,
										buffer=arguments.buffer,
										objectToCompositeName=compositeName);
				//resolveCompositeJoinSQL(arguments.object, arguments.alias, objectTo, aliasTo, arguments.buffer, compositeName);
			}
		}
		else if(localTree.getType() eq getTQLParser().getNodeType("ON_COMPOSITE"))
		{
			//do nothing
		}
		else if(localTree.getType() eq getTQLParser().getNodeType("JOIN"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("OUTER"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("LEFT"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("RIGHT"))
		{
			//do nothing
		}
		else if(localTree.getType() eq getTQLParser().getNodeType("CLASS_IDENTIFIER"))
		{
			return arguments;
		}
		else
		{
			arguments.buffer.append(" ");
			arguments.buffer.append(localTree.getText());
		}

		for(; counter lt localTree.getChildCount(); counter = counter + 1)
		{
			child = localTree.getChild(JavaCast("int", counter));
			arguments = evaluateOnCompositeJoin(child, arguments.object, arguments.alias, arguments.aliasMap, arguments.buffer, arguments.pastClassIdentifierNodes);
		}

		return arguments;
	</cfscript>
</cffunction>

<cffunction name="evaluateIdentifierJoinAST" hint="walks the tree, and makes a array of structs that represent the Identifier join SQL and the mapped values" access="private" returntype="array" output="false">
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
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("ON_IDENTIFIER"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("SELECT"))
		{
			return getSelectStatement().evaluateSelectStatement(arguments.tree, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("JOIN"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("OUTER"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("LEFT"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("RIGHT"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("CLASS_IDENTIFIER"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("AS"))
		{
			//do nothing
		}
		else if(arguments.tree.getType() eq getTQLParser().getNodeType("ALIAS"))
		{
			//do nothing
		}
		else
		{
			arguments.buffer.append(" ");
			arguments.buffer.append(arguments.tree.getText());
		}

		for(; counter lt arguments.tree.getChildCount(); counter = counter + 1)
		{
			child = arguments.tree.getChild(JavaCast("int", counter));

			arguments.evaluation = evaluateIdentifierJoinAST(child, arguments.aliasMap, arguments.evaluation, arguments.buffer, arguments.aliasColumns, arguments.distinctMode);
		}

		return arguments.evaluation;
	</cfscript>
</cffunction>

<!--- resolving --->

<cffunction name="resolveManyToManyInterimAutoJoinSQL" hint="Builds the from Auto join SQL for the intermim Many to Many table" access="private" returntype="void" output="false">
	<cfargument name="objectFrom" hint="The object to go from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasFrom" hint="The from alias" type="string" required="Yes">
	<cfargument name="objectTo" hint="The object to go to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasTo" hint="The to alias" type="string" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="Yes">
	<cfargument name="innerJoin" hint="if the join is an inner join" type="boolean" required="Yes">
	<cfargument name="outerJoinType" hint="if the join is an inner join" type="string" required="Yes">
	<cfscript>
		var relationships = arguments.objectFrom.getManyToManyArrayByLink(arguments.objectTo.getClassName());
		var manytomany = 0;
		var iterator = relationships.iterator();

		while(iterator.hasNext())
		{
			manytomany = iterator.next();
			buildManyToManyInterimJoinSQL(arguments.objectFrom,
												arguments.aliasFrom,
												arguments.objectTo,
												arguments.aliasTo,
												arguments.buffer,
												manytomany,
												arguments.innerJoin,
												arguments.outerJoinType);

		}

		relationships = arguments.objectTo.getManyToManyArrayByLink(arguments.objectFrom.getClassName());
		iterator = relationships.iterator();

		while(iterator.hasNext())
		{
			manytomany = iterator.next();
			buildManyToManyInterimJoinSQL(arguments.objectFrom,
												arguments.aliasFrom,
												arguments.objectTo,
												arguments.aliasTo,
												arguments.buffer,
												manytomany,
												arguments.innerJoin,
												arguments.outerJoinType,
												false);

		}
	</cfscript>
</cffunction>

<cffunction name="resolveAutoJoinSQL" hint="resolves the joins found in the relationship collection" access="private" returntype="boolean" output="false">
	<cfargument name="objectFrom" hint="The object to go from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasFrom" hint="The fro alias" type="string" required="Yes">
	<cfargument name="objectTo" hint="The object to go to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasTo" hint="The fro alias" type="string" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="relationships" hint="The relationship collection" type="struct" required="Yes">
	<cfargument name="on" hint="if it's an on statement, or a and statement" type="boolean" required="No" default="true">
	<cfscript>
		var iterator = 0;
		var onetomany = 0;
		var joined = false;
		var join = " ON ";

		//if not an 'on', then must be an 'and'
		if(NOT arguments.on)
		{
			join = " AND ";
		}

		//object from

		//one to many
		iterator = arguments.relationships[arguments.objectFrom.getClassName()].onetomany.iterator();

		while(iterator.hasNext())
		{
			arguments.buffer.append(join);
			if(arguments.on)
			{
				join = " AND ";
				arguments.on = false;
			}

			buildOneToManyJoinSQL(arguments.objectFrom,
									arguments.aliasFrom,
									arguments.objectTo,
									arguments.aliasTo,
									arguments.buffer,
									iterator.next()
									);
			joined = true;
		}


		//many to one
		iterator = arguments.relationships[arguments.objectFrom.getClassName()].manytoone.iterator();
		while(iterator.hasNext())
		{
			arguments.buffer.append(join);
			if(arguments.on)
			{
				join = " AND ";
				arguments.on = false;
			}

			buildManyToOneJoinSQL(arguments.objectFrom,
									arguments.aliasFrom,
									arguments.objectTo,
									arguments.aliasTo,
									arguments.buffer,
									iterator.next()
									);

			joined = true;
		}

		//many to many
		iterator = arguments.relationships[arguments.objectFrom.getClassName()].manytomany.iterator();

		while(iterator.hasNext())
		{
			arguments.buffer.append(join);
			if(arguments.on)
			{
				join = " AND ";
				arguments.on = false;
			}

			buildManyToManyJoinSQL(arguments.objectTo,
									arguments.aliasTo,
									arguments.buffer,
									iterator.next()
									);
			joined = true;
		}

	//object to

		//one to many
		iterator = arguments.relationships[arguments.objectTo.getClassName()].onetomany.iterator();

		while(iterator.hasNext())
		{
			arguments.buffer.append(join);
			if(arguments.on)
			{
				join = " AND ";
				arguments.on = false;
			}

			buildOneToManyJoinSQL(arguments.objectFrom,
									arguments.aliasFrom,
									arguments.objectTo,
									arguments.aliasTo,
									arguments.buffer,
									iterator.next(),
									false
									);
			joined = true;
		}

		//many to one
		iterator = arguments.relationships[arguments.objectTo.getClassName()].manytoone.iterator();
		while(iterator.hasNext())
		{
			arguments.buffer.append(join);
			if(arguments.on)
			{
				join = " AND ";
				arguments.on = false;
			}

			buildManyToOneJoinSQL(arguments.objectFrom,
									arguments.aliasFrom,
									arguments.objectTo,
									arguments.aliasTo,
									arguments.buffer,
									iterator.next(),
									false
									);
			joined = true;
		}

		//many to many
		iterator = arguments.relationships[arguments.objectTo.getClassName()].manytomany.iterator();

		while(iterator.hasNext())
		{
			arguments.buffer.append(join);
			if(arguments.on)
			{
				join = " AND ";
				arguments.on = false;
			}

			buildManyToManyJoinSQL(arguments.objectTo,
									arguments.aliasTo,
									arguments.buffer,
									iterator.next(),
									false
									);
			joined = true;
		}

		return joined;
	</cfscript>
</cffunction>

<cffunction name="resolveCompositeJoinSQL" hint="resolves the joins found in the relationship collection" access="private" returntype="void" output="false">
	<cfargument name="objectFrom" hint="The object to go from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasFrom" hint="The fro alias" type="string" required="Yes">
	<cfargument name="objectTo" hint="The object to go to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasTo" hint="The fro alias" type="string" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="objectFromCompositeName" hint="The object composite name for the from object" type="string" required="No">
	<cfargument name="objectToCompositeName" hint="The object composite name for the to object" type="string" required="No">
	<cfscript>
		var result = 0;

		if(StructKeyExists(arguments, "objectFromCompositeName"))
		{
			result = arguments.objectFrom.getManyToOneArrayByLink(arguments.objectTo.getClassName(), arguments.objectFromCompositeName);

			if(ArrayLen(result))
			{
				buildManyToOneJoinSQL(arguments.objectFrom,
										arguments.aliasFrom,
										arguments.objectTo,
										arguments.aliasTo,
										arguments.buffer,
										result[1]
										);
				return;
			}

			result = arguments.objectFrom.getOneToManyArrayByLink(arguments.objectTo.getClassName(), arguments.objectFromCompositeName);

			if(ArrayLen(result))
			{
				buildOneToManyJoinSQL(arguments.objectFrom,
										arguments.aliasFrom,
										arguments.objectTo,
										arguments.aliasTo,
										arguments.buffer,
										result[1]
										);
				return;
			}

			result = arguments.objectFrom.getManyToManyArrayByLink(arguments.objectTo.getClassName(), arguments.objectFromCompositeName);

			if(ArrayLen(result))
			{
				buildManyToManyJoinSQL(arguments.objectTo,
										arguments.aliasTo,
										arguments.buffer,
										result[1]
										);
				return;
			}

			throw("TQLException",
				"Could not resolve join condition",
				"The composition of '#arguments.objectFromCompositeName#' could not be found on Object '#arguments.objectFrom.getClassName()#'");
		}
		else
		{
			result = arguments.objectTo.getManyToOneArrayByLink(arguments.objectFrom.getClassName(), arguments.objectToCompositeName);

			if(ArrayLen(result))
			{
				buildManyToOneJoinSQL(arguments.objectFrom,
										arguments.aliasFrom,
										arguments.objectTo,
										arguments.aliasTo,
										arguments.buffer,
										result[1],
										false
										);
				return;
			}

			result = arguments.objectTo.getOneToManyArrayByLink(arguments.objectFrom.getClassName(), arguments.objectToCompositeName);

			if(ArrayLen(result))
			{
				buildOneToManyJoinSQL(arguments.objectFrom,
										arguments.aliasFrom,
										arguments.objectTo,
										arguments.aliasTo,
										arguments.buffer,
										result[1],
										false
										);
				return;
			}

			result = arguments.objectTo.getManyToManyArrayByLink(arguments.objectFrom.getClassName(), arguments.objectToCompositeName);

			if(ArrayLen(result))
			{
				buildManyToManyJoinSQL(arguments.objectTo,
										arguments.aliasTo,
										arguments.buffer,
										result[1],
										false
										);
				return;
			}

			throw("TQLException",
				"Could not resolve join condition",
				"The composition of #arguments.objectToCompositeName# could not be found on Object #arguments.objectTo.getClassName()#");
		}
	</cfscript>
</cffunction>

<cffunction name="resolveCompositeInterimJoinSQL" hint="resolves the intermin joins found in the relationship collection" access="private" returntype="void" output="false">
	<cfargument name="objectFrom" hint="The object to go from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasFrom" hint="The fro alias" type="string" required="Yes">
	<cfargument name="objectTo" hint="The object to go to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasTo" hint="The fro alias" type="string" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="innerJoin" hint="if the join is an inner join" type="boolean" required="Yes">
	<cfargument name="outerJoinType" hint="if the join is an inner join" type="string" required="Yes">
	<cfargument name="objectFromCompositeName" hint="The object composite name for the from object" type="string" required="No">
	<cfargument name="objectToCompositeName" hint="The object composite name for the to object" type="string" required="No">
	<cfscript>
		var result = 0;

		if(StructKeyExists(arguments, "objectFromCompositeName"))
		{
			result = arguments.objectFrom.getManyToManyArrayByLink(arguments.objectTo.getClassName(), arguments.objectFromCompositeName);

			if(ArrayLen(result))
			{
				buildManyToManyInterimJoinSQL(arguments.objectFrom,
												arguments.aliasFrom,
												arguments.objectTo,
												arguments.aliasto,
												arguments.buffer,
												result[1],
												arguments.innerJoin,
												arguments.outerJoinType
												);
				return;
			}
		}
		else
		{
			result = arguments.objectTo.getManyToManyArrayByLink(arguments.objectFrom.getClassName(), arguments.objectToCompositeName);

			if(ArrayLen(result))
			{
				buildManyToManyInterimJoinSQL(arguments.objectFrom,
												arguments.aliasFrom,
												arguments.objectTo,
												arguments.aliasto,
												arguments.buffer,
												result[1],
												arguments.innerJoin,
												arguments.outerJoinType,
												false
												);
				return;
			}
		}
	</cfscript>
</cffunction>

<!--- Building --->

<cffunction name="buildRelationShipCollection" hint="Buids the array of relationships that are possible between these two objects" access="private" returntype="struct" output="false">
	<cfargument name="objectFrom" hint="The object to go from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="objectTo" hint="The object to go to" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var relationships = structNew();
		var relationship = StructNew();

		//go one way
		relationship.manytoone = arguments.objectFrom.getManyToOneArrayByLink(arguments.objectTo.getClassName());
		relationship.onetomany = arguments.objectFrom.getOneToManyArrayByLink(arguments.objectTo.getClassName());
		relationship.manytomany = arguments.objectFrom.getManyToManyArrayByLink(arguments.objectTo.getClassName());

		relationships[arguments.objectFrom.getClassName()] = relationship;

		//go the other
		relationship = StructNew();
		relationship.manytoone = arguments.objectTo.getManyToOneArrayByLink(arguments.objectFrom.getClassName());
		relationship.onetomany = arguments.objectTo.getOneToManyArrayByLink(arguments.objectFrom.getClassName());
		relationship.manytomany = arguments.objectTo.getManyToManyArrayByLink(arguments.objectFrom.getClassName());

		relationships[arguments.objectTo.getClassName()] = relationship;

		return relationships;
	</cfscript>
</cffunction>

<cffunction name="buildManyToOneJoinSQL" hint="Builds the from SQL for a Many To One" access="private" returntype="void" output="false">
	<cfargument name="objectFrom" hint="The object to go from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasFrom" hint="The fro alias" type="string" required="Yes">
	<cfargument name="objectTo" hint="The object to go to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasTo" hint="The fro alias" type="string" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="manytoone" hint="The one to many connector" type="transfer.com.object.ManyToOne" required="Yes">
	<cfargument name="resolveFromTo" hint="whether to resolve From -> To, or To -> From" type="boolean" required="No" default="true">
	<cfscript>
		if(resolveFromTo)
		{
			arguments.buffer.append(resolveAlias(aliasFrom, arguments.objectFrom.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.manytoone.getLink().getColumn());
			arguments.buffer.append(" = ");
			arguments.buffer.append(resolveAlias(aliasTo, arguments.objectTo.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.objectTo.getPrimaryKey().getColumn());
		}
		else
		{
			arguments.buffer.append(resolveAlias(aliasFrom, arguments.objectFrom.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.objectFrom.getPrimaryKey().getColumn());
			arguments.buffer.append(" = ");
			arguments.buffer.append(resolveAlias(aliasTo, arguments.objectTo.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.manytoone.getLink().getColumn());
		}
	</cfscript>
</cffunction>

<cffunction name="buildManyToManyInterimJoinSQL" hint="Builds the from SQL for the intermim Many to Many table" access="private" returntype="void" output="false">
	<cfargument name="objectFrom" hint="The object to go from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasFrom" hint="The from alias" type="string" required="Yes">
	<cfargument name="objectTo" hint="The object to go to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasTo" hint="The to alias" type="string" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="manytomany" hint="The one to many connector" type="transfer.com.object.ManyToMany" required="Yes">
	<cfargument name="innerJoin" hint="if the join is an inner join" type="boolean" required="Yes">
	<cfargument name="outerJoinType" hint="if the join is an inner join" type="string" required="Yes">
	<cfargument name="resolveFromTo" hint="whether to resolve From -> To, or To -> From" type="boolean" required="No" default="true">
	<cfscript>
		if(arguments.innerJoin)
		{
			arguments.buffer.append(" inner ");
		}
		else
		{
			arguments.buffer.append(" ");
			arguments.buffer.append(arguments.outerJoinType);
			arguments.buffer.append(" outer ");
		}

		arguments.buffer.append(" join ");
		arguments.buffer.append(arguments.manytomany.getTable());
		arguments.buffer.append(" on ");

		if(arguments.resolveFromTo)
		{
			arguments.buffer.append(resolveAlias(arguments.aliasFrom, arguments.objectFrom.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.objectFrom.getPrimaryKey().getColumn());
			arguments.buffer.append(" = ");
			arguments.buffer.append(arguments.manytomany.getTable());
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.manyToMany.getLinkFrom().getColumn());
		}
		else
		{
			arguments.buffer.append(arguments.manytomany.getTable());
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.manyToMany.getLinkTo().getColumn());
			arguments.buffer.append(" = ");
			arguments.buffer.append(resolveAlias(arguments.aliasFrom, arguments.objectFrom.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.objectFrom.getPrimaryKey().getColumn());
		}
	</cfscript>
</cffunction>

<cffunction name="buildOneToManyJoinSQL" hint="Builds the from SQL for a One to Many" access="private" returntype="void" output="false">
	<cfargument name="objectFrom" hint="The object to go from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasFrom" hint="The fro alias" type="string" required="Yes">
	<cfargument name="objectTo" hint="The object to go to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasTo" hint="The fro alias" type="string" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="oneToMany" hint="The one to many connector" type="transfer.com.object.OneToMany" required="Yes">
	<cfargument name="resolveFromTo" hint="whether to resolve From -> To, or To -> From" type="boolean" required="No" default="true">
	<cfscript>
		if(resolveFromTo)
		{
			arguments.buffer.append(resolveAlias(aliasFrom, arguments.objectFrom.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.objectFrom.getPrimaryKey().getColumn());
			arguments.buffer.append(" = ");
			arguments.buffer.append(resolveAlias(aliasTo, arguments.objectTo.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.onetomany.getLink().getColumn());
		}
		else
		{
			arguments.buffer.append(resolveAlias(aliasFrom, arguments.objectFrom.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.onetomany.getLink().getColumn());
			arguments.buffer.append(" = ");
			arguments.buffer.append(resolveAlias(aliasTo, arguments.objectTo.getTable()));
			arguments.buffer.append(".");
			arguments.buffer.append(arguments.objectTo.getPrimaryKey().getColumn());
		}
	</cfscript>
</cffunction>

<cffunction name="buildManyToManyJoinSQL" hint="Builds the from SQL for the Many to Many join" access="private" returntype="void" output="false">
	<cfargument name="objectFrom" hint="The object to go from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="aliasFrom" hint="The from alias" type="string" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfargument name="manytomany" hint="The one to many connector" type="transfer.com.object.ManyToMany" required="Yes">
	<cfargument name="resolveFromTo" hint="whether to resolve From -> To, or To -> From" type="boolean" required="No" default="true">
	<cfscript>
		arguments.buffer.append(arguments.manytomany.getTable());
		arguments.buffer.append(".");

		if(arguments.resolveFromTo)
		{
			arguments.buffer.append(arguments.manyToMany.getLinkTo().getColumn());
		}
		else
		{
			arguments.buffer.append(arguments.manyToMany.getLinkFrom().getColumn());
		}

		arguments.buffer.append(" = ");
		arguments.buffer.append(resolveAlias(aliasFrom, arguments.objectFrom.getTable()));
		arguments.buffer.append(".");
		arguments.buffer.append(arguments.objectFrom.getPrimaryKey().getColumn());
	</cfscript>
</cffunction>

<cffunction name="searchPastIdentifierNodesForAlias" hint="Travels back up to past nodes, to see if an alias exists. If one doesn't, then return """ access="private" returntype="string" output="false">
	<cfargument name="pastClassIdentifierNodes" hint="keeps track of all previous class identifiers" type="any" required="yes">
	<cfargument name="className" hint="The name of the object class to look for" type="string" required="Yes">
	<cfscript>
		//getTqlParser().dumpTree(pastClassIdentifierNodes[1]);
		var iterator = pastClassIdentifierNodes.iterator();
		var node = 0;

		while(iterator.hasNext())
		{
			node = iterator.next();
			if(node.getText() eq arguments.className)
			{
				if(node.getChildCount())
				{
					return node.getChild(1).getText();
				}
				else
				{
					return "";
				}
			}
		}

		throw("TQLException",
			"Could not resolve class in previously declared From statement",
			"A declaration of class #arguments.className# could not be found in the TQL previous to where it is required.");
	</cfscript>
</cffunction>

</cfcomponent>