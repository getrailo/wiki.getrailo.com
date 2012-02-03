<!--- Document Information -----------------------------------------------------

Title:      Property.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Resolves property values

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		26/02/2007		Created

------------------------------------------------------------------------------->

<cfcomponent name="Property" hint="walks property values" extends="AbstractBaseWalker" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="evaluateObjectIdentifier" hint="Resolves the object identifier and returns the object" access="public" returntype="transfer.com.object.Object" output="false">
	<cfargument name="text" hint="The text from the tree node" type="string" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfscript>
		var listLen = ListLen(arguments.text, ".");
		var className = 0;
		var object = 0;
		var propertyName = 0;

		if(listLen eq 1)
		{
			throw("transfer.TQLSyntaxException",
				"Error with class value '"& arguments.text &"' in clause",
				"Class values must resolve to the Class name or the alias. e.g. 'email.Email.emailName'");
		}

		propertyName = ListGetAt(arguments.text, listLen, ".");
		className = Left(arguments.text, Len(arguments.text) - (Len(propertyName) + 1));

		if(StructKeyExists(arguments.aliasMap, className))
		{
			object = aliasMap[className];
		}
		else
		{
			object = getObjectManager().getObject(className);
		}

		return object;
	</cfscript>
</cffunction>

<cffunction name="evaluateObjectAlias" hint="evaluates the alias from a Object identifier. returns '' if none" access="public" returntype="string" output="false">
	<cfargument name="text" hint="The text from the tree node" type="string" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfscript>
		var listLen = ListLen(arguments.text, ".");
		var className = 0;
		var object = 0;
		var propertyName = 0;

		if(listLen eq 1)
		{
			throw("transfer.TQLSyntaxException",
				"Error with class value '"& arguments.text &"' in clause",
				"Class values must resolve to the Class name or the alias. e.g. 'email.Email.emailName'");
		}

		propertyName = ListGetAt(arguments.text, listLen, ".");
		className = Left(arguments.text, Len(arguments.text) - (Len(propertyName) + 1));

		if(StructKeyExists(arguments.aliasMap, className))
		{
			return className;
		}

		return "";
	</cfscript>

</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->


</cfcomponent>