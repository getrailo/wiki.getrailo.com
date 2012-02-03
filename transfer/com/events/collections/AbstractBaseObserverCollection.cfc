<!--- Document Information -----------------------------------------------------

Title:      AbstractBaseObserverCollection.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Abstract Base Class for Observer collections

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		06/10/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="AbstractBaseObserverCollection" hint="Abstract Base Class for Observer collections" extends="transfer.com.collections.AbstractBaseObservable">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="addObserver" hint="Adds an observer" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer to be added" type="transfer.com.events.adapter.AbstractBaseEventActionAdapter" required="Yes">
	<cfscript>
		super.addObserver(arguments.observer, arguments.observer.getKey());
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>