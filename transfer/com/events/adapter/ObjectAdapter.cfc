<!--- Document Information -----------------------------------------------------

Title:      ObjectAdapter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    an object event adapter

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		20/02/2007		Created

------------------------------------------------------------------------------->
<cfcomponent name="ObjectAdapter" hint="An adapter that just calles the action methods on the underlying object" extends="transfer.com.events.adapter.AbstractBaseEventActionAdapter" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="ObjectAdapter" output="false">
	<cfargument name="object" hint="The object to adapt to" type="any" required="Yes">
	<cfscript>
		super.init();
		setObject(arguments.object);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getAdapted" hint="returns the object that is adapted" access="public" returntype="any" output="false">
	<cfreturn getObject()/>
</cffunction>

<cffunction name="getKey" hint="returns a unique identifier key for the object contained for this adapter. Returns the Java system ident for the object, as this is a hard reference"
			access="public" returntype="any" output="false">
	<cfreturn getSystem().identityHashCode(getAdapted()) />
</cffunction>

<cffunction name="actionBeforeCreateTransferEvent" hint="Actions a event before a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfset getObject().actionBeforeCreateTransferEvent(arguments.event) />
	<cfreturn true />
</cffunction>

<cffunction name="actionAfterCreateTransferEvent" hint="Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfset getObject().actionAfterCreateTransferEvent(arguments.event) />
	<cfreturn true />
</cffunction>

<cffunction name="actionBeforeUpdateTransferEvent" hint="Actions a event Before a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfset getObject().actionBeforeUpdateTransferEvent(arguments.event) />
	<cfreturn true />
</cffunction>

<cffunction name="actionAfterUpdateTransferEvent" hint="Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfset getObject().actionAfterUpdateTransferEvent(arguments.event) />
	<cfreturn true />
</cffunction>

<cffunction name="actionBeforeDeleteTransferEvent" hint="Actions a event Before a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfset getObject().actionBeforeDeleteTransferEvent(arguments.event) />
	<cfreturn true />
</cffunction>

<cffunction name="actionAfterDeleteTransferEvent" hint="Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfset getObject().actionAfterDeleteTransferEvent(arguments.event) />
	<cfreturn true />
</cffunction>

<cffunction name="actionAfterDiscardTransferEvent" hint="Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfset getObject().actionAfterDiscardTransferEvent(arguments.event) />
	<cfreturn true />
</cffunction>

<cffunction name="actionAfterNewTransferEvent" hint="Actions a event after a New() happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfset getObject().actionAfterNewTransferEvent(arguments.event) />
	<cfreturn true />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getObject" access="private" returntype="any" output="false">
	<cfreturn instance.Object />
</cffunction>

<cffunction name="setObject" access="private" returntype="void" output="false">
	<cfargument name="Object" type="any" required="true">
	<cfset instance.Object = arguments.Object />
</cffunction>

</cfcomponent>