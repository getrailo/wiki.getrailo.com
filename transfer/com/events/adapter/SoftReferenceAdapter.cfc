<!--- Document Information -----------------------------------------------------

Title:      SoftReferenceAdapter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    a soft reference event adapter

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		20/02/2007		Created

------------------------------------------------------------------------------->
<cfcomponent hint="An adapter that uses a soft reference, and if the reference has been cleared, it ignores it" extends="transfer.com.events.adapter.AbstractBaseEventActionAdapter" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="SoftReferenceAdapter" output="false">
	<cfargument name="softRef" hint="java.lang.ref.SoftReference: The soft reference to hold" type="any" required="Yes">
	<cfscript>
		super.init();

		setSoftReference(arguments.softRef);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getKey" hint="returns a unique identifier key for the object contained for this adapter. returns the softReference object, as it is unique" access="public" returntype="any" output="false">
	<cfreturn getSoftReference() />
</cffunction>

<cffunction name="getAdapted" hint="returns the object that is adapted from the soft reference. Could be null." access="public" returntype="any" output="false">
	<cfreturn getSoftReference().get()/>
</cffunction>

<cffunction name="actionBeforeCreateTransferEvent" hint="Actions a event before a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		var local = StructNew();
		local.object = getSoftReference().get();

		if(StructKeyExists(local, "object"))
		{
			local.object.actionBeforeCreateTransferEvent(arguments.event);
			return true;
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="actionAfterCreateTransferEvent" hint="Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		var local = StructNew();
		local.object = getSoftReference().get();

		if(StructKeyExists(local, "object") AND local.object.getIsLoaded())
		{
			local.object.actionAfterCreateTransferEvent(arguments.event);
			return true;
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="actionBeforeUpdateTransferEvent" hint="Actions a event Before a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		var local = StructNew();
		local.object = getSoftReference().get();

		if(StructKeyExists(local, "object") AND local.object.getIsLoaded())
		{
			local.object.actionBeforeUpdateTransferEvent(arguments.event);
			return true;
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="actionAfterUpdateTransferEvent" hint="Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		var local = StructNew();
		local.object = getSoftReference().get();

		if(StructKeyExists(local, "object") AND local.object.getIsLoaded())
		{
			local.object.actionAfterUpdateTransferEvent(arguments.event);
			return true;
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="actionBeforeDeleteTransferEvent" hint="Actions a event Before a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		var local = StructNew();
		local.object = getSoftReference().get();

		if(StructKeyExists(local, "object") AND local.object.getIsLoaded())
		{
			local.object.actionBeforeDeleteTransferEvent(arguments.event);
			return true;
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="actionAfterDeleteTransferEvent" hint="Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		var local = StructNew();
		local.object = getSoftReference().get();

		if(StructKeyExists(local, "object") AND local.object.getIsLoaded())
		{
			local.object.actionAfterDeleteTransferEvent(arguments.event);
			return true;
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="actionAfterDiscardTransferEvent" hint="Actions a event After a create happens" access="public" returntype="boolean" output="false">
	<cfargument name="event" hint="The event object" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		var local = StructNew();
		local.object = getSoftReference().get();

		if(StructKeyExists(local, "object") AND local.object.getIsLoaded())
		{
			local.object.actionAfterDiscardTransferEvent(arguments.event);
			return true;
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="clean" hint="Clean the adapter" access="public" returntype="void" output="false">
	<cfscript>
		StructDelete(instance, "softReference");
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getSoftReference" access="private" returntype="any" output="false">
	<cfreturn instance.SoftReference />
</cffunction>

<cffunction name="setSoftReference" access="private" returntype="void" output="false">
	<cfargument name="SoftReference" type="any" required="true">
	<cfset instance.SoftReference = arguments.SoftReference />
</cffunction>

</cfcomponent>