<!--- Document Information -----------------------------------------------------

Title:      TransferObjectPool.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    A pool for Transfer Objects

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		20/02/2007		Created

------------------------------------------------------------------------------->
<cfcomponent name="TransferObjectPool" hint="A pool for TransferObjects" extends="transfer.com.collections.AbstractBaseSemiSoftRefObjectPool">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="TransferObjectPool" output="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		//10 hard referenced items
		super.init(10, arguments.javaLoader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getTransferObject" hint="Gives you a TransferObject" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfscript>
		return pop();
	</cfscript>
</cffunction>

<cffunction name="recycleTransferObject" hint="Returns a pathway TransferObject to the queue for reuse" access="public" returntype="void" output="false">
	<cfargument name="TransferObject" hint="TransferObject to be returned" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		push(arguments.TransferObject);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getNewObject" hint="virtual method: returns the new CFC to repopulate the pool" access="private" returntype="any" output="false">
	<cfreturn createObject("component", "transfer.com.TransferObject") />
</cffunction>

</cfcomponent>