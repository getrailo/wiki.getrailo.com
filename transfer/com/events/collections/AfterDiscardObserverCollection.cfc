<!--- Document Information -----------------------------------------------------

Title:      AfterDiscardObserverCollection.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Collection of Observers for before a Update

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		18/06/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="AfterDiscardObserverCollection" hint="Collection of Observers for before a Discard" extends="AbstractBaseObserverCollection">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="AfterDiscardObserverCollection" output="false">
	<cfscript>
		super.init();

		return this;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="fireActionMethod" hint="virtual: fires the action method" access="private" returntype="void" output="false">
	<cfargument name="adapter" hint="the adapter to fire against" type="transfer.com.events.adapter.AbstractBaseEventActionAdapter" required="Yes">
	<cfargument name="event" hint="The event object to fire" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		if(NOT arguments.adapter.actionAfterDiscardTransferEvent(arguments.event))
		{
			//if we come across an adapter that is empty, dump it.
			removeObserverByKey(arguments.adapter.getKey());
		}
	</cfscript>
</cffunction>

</cfcomponent>