<!--- Document Information -----------------------------------------------------

Title:      EqualsWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes the transferEquals function

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		10/08/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="EqualsWriter" hint="Writes the transferEquals function" extends="AbstractBaseWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="EqualsWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeEquals" hint="Writes the transferEquals statement" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var primaryKeyName = arguments.object.getPrimaryKey().getName();

		arguments.buffer.writeCFFunctionOpen("equalsTransfer", "public", "boolean", "If an object is persisted, returns true if they are of the same class and same id. If not, returns true if they are the same object.");
		arguments.buffer.writeCFArgument("transfer", "transfer.com.TransferObject", "The TransferObject to test against", true);
		arguments.buffer.cfscript(true);

		//if is presisted, check the class and the primary key value
		arguments.buffer.writeLine("if(getIsPersisted())");
		arguments.buffer.writeLine("{");
			arguments.buffer.writeLine("if(getClassName() neq arguments.transfer.getClassName())");
			arguments.buffer.writeLine("{");
				arguments.buffer.writeLine("return false;");
			arguments.buffer.writeLine("}");
				arguments.buffer.writeLine("return (get"& primaryKeyName &"() eq arguments.transfer.get" & primaryKeyName & "());");
		arguments.buffer.writeLine("}");
		arguments.buffer.writeLine("else");

		//if not, check if it's the same object
		arguments.buffer.writeLine("{");
		arguments.buffer.writeLine("return sameTransfer(arguments.transfer);");
		arguments.buffer.writeLine("}");
		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<!---
<cffunction name="equalsTransfer" hint="Checks to see if 2 transfer objects are the same" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to check if we are equal" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var system = createObject("java", "java.lang.System");
		return (system.identityHashCode(this) eq system.identityHashCode(arguments.transfer));
	</cfscript>
</cffunction> --->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>