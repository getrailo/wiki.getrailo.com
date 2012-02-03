<!--- Document Information -----------------------------------------------------

Title:      AbstractBaseEventActionAdapter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Abstact base class for event adapters

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		20/02/2007		Created

------------------------------------------------------------------------------->
<cfcomponent name="AbstractBaseEventActionAdapter" hint="An abstract base adapter that allows for the event menthods to be fired on it" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="private" returntype="void" output="false">
	<cfscript>
		variables.instance = StructNew();
		setSystem(createObject("java", "java.lang.System"));
	</cfscript>
</cffunction>

<cffunction name="equalsAdapted" hint="returns if the object passed in is the same instance as the adapted" access="public" returntype="boolean" output="false">
	<cfargument name="object" hint="The object to check against" type="any" required="Yes">
	<cfreturn getSystem().identityHashCode(arguments.object) eq getSystem().identityHashCode(getAdapted())>
</cffunction>

<cffunction name="getAdapted" hint="returns the object that is adapted" access="public" returntype="any" output="false">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="getKey" hint="returns a unique identifier key for the object contained for this adapter. Used for observer storage" access="public" returntype="any" output="false">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="actionBeforeCreateTransferEvent" hint="virtual: Actions a event before a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="actionAfterCreateTransferEvent" hint="virtual: Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="actionBeforeUpdateTransferEvent" hint="virtual: Actions a event Before a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="actionAfterUpdateTransferEvent" hint="virtual: Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="actionBeforeDeleteTransferEvent" hint="virtual: Actions a event Before a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="actionAfterDeleteTransferEvent" hint="virtual: Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="actionAfterDiscardTransferEvent" hint="virtual: Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="actionAfterNewTransferEvent" hint="virtual: Actions a event after a New() happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getSystem" access="private" returntype="any" output="false">
	<cfreturn instance.System />
</cffunction>

<cffunction name="setSystem" access="private" returntype="void" output="false">
	<cfargument name="System" type="any" required="true">
	<cfset instance.System = arguments.System />
</cffunction>

</cfcomponent>