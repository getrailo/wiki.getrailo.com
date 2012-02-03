<!--- Document Information -----------------------------------------------------

Title:      CustomFunctionWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes the custom functions

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		05/04/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="CustomFunctionWriter" hint="Writes the custom functions" extends="AbstractBaseWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="CustomFunctionWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeCustomFunctions" hint="Writes the custom functions" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var iterator = arguments.object.getFunctionIterator();
		var customFunction = 0;
		var argIterator = 0;
		var argument = 0;

		while(iterator.hasNext())
		{
			customFunction = iterator.next();

			arguments.buffer.writeCFFunctionOpen(customFunction.getName(), customFunction.getAccess(), customFunction.getReturnType(), "Custom function");

			argIterator = customFunction.getArgumentIterator();

			while(argIterator.hasNext())
			{
				argument = argIterator.next();
				arguments.buffer.writeCFArgument(argument.getName(), argument.getType(), "", argument.getRequired(), argument.getDefault());
			}
			arguments.buffer.writeLine(Trim(customFunction.getBody()));
			arguments.buffer.writeCFFunctionClose();
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>