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

<cffunction name="evaluatePropertyIdentifier" hint="Resolves the property identifier in the buffer, and then retuns the Property (kinda bad cohesian, but I'm struggling to work around it)" access="public" returntype="transfer.com.object.Property" output="false">
	<cfargument name="text" hint="The text from the tree node" type="string" required="Yes">
	<cfargument name="aliasMap" hint="The from map" type="struct" required="Yes">
	<cfargument name="buffer" hint="java.lang.StringBuffer for preSQL building" type="any" required="true">
	<cfscript>
		var listLen = ListLen(arguments.text, ".");
		var propertyName = 0;
		var className = 0;
		var object = 0;
		var property = 0;

		if(listLen eq 0)
		{
			throw("TQLException",
				"Error with property value '"& arguments.text &"' in clause",
				"Property values must resolve to the Class name or the alias. e.g. 'email.Email.emailName'");
		}

		propertyName = ListGetAt(arguments.text, listLen, ".");
		className = Left(arguments.text, Len(arguments.text) - (Len(propertyName) + 1));

		arguments.buffer.append(" ");

		if(StructKeyExists(arguments.aliasMap, className))
		{
			object = aliasMap[className];
			arguments.buffer.append(className);
		}
		else
		{
			object = getObjectManager().getObject(className);
			arguments.buffer.append(object.getTable());
		}

		arguments.buffer.append(".");
		property = object.getPropertyByName(propertyName);
		arguments.buffer.append(property.getColumn());

		return property;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->


</cfcomponent>