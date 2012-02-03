<!--- Document Information -----------------------------------------------------

Title:      TransferEvent.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Transfer Event

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		05/07/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="TransferEvent" hint="Transfer Event">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="TransferEvent" output="false">
	<cfscript>

		return this;
	</cfscript>
</cffunction>

<cffunction name="getTransferObject" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfreturn instance.TransferObject />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object via a memento" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="The memento to set the date by" type="struct" required="Yes">

	<cfscript>
		setTransferObject(arguments.memento.transferObject);
	</cfscript>
</cffunction>

<cffunction name="clean" hint="cleans off the event" access="public" returntype="string" output="false">
	<cfscript>
		StructDelete(instance, "transferObject");
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setTransferObject" access="private" returntype="void" output="false">
	<cfargument name="TransferObject" type="transfer.com.TransferObject" required="true">
	<cfset instance.TransferObject = arguments.TransferObject />
</cffunction>


</cfcomponent>