<!--- Document Information -----------------------------------------------------

Title:      DummyObserverCollection.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Collection for 'none' scopes, that keeps nothing, and fires nothing

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/05/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="DummyObserverCollection" hint="Collection for 'none' scopes, that keeps nothing, and fires nothing" extends="AbstractBaseObserverCollection">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="DummyObserverCollection" output="false">
	<cfscript>
		super.init();

		return this;
	</cfscript>
</cffunction>

<cffunction name="addObserver" hint="Adds an observer" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer to be added" type="any" required="Yes">
	<!--- does nothing --->
</cffunction>

<cffunction name="removeObserverByKey" hint="If you have the identity key, you can remove it" access="public" returntype="void" output="false">
	<cfargument name="key" hint="The key to remove" type="any" required="Yes">
	<!--- never going to do a thing --->
</cffunction>

<cffunction name="removeObserver" hint="Removes an observer from the collection" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer to be removed" type="any" required="Yes">
	<!--- Never had them in the first place, so who cares --->
</cffunction>

<cffunction name="fireEvent" hint="Fires off the event to all the Observers" access="public" returntype="void" output="false">
	<cfargument name="event" hint="The event to fire" type="transfer.com.events.TransferEvent" required="Yes">
	<!--- does nothing --->
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->


</cfcomponent>