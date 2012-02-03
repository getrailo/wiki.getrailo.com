<!--- Document Information -----------------------------------------------------

Title:      TransactionManager.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Facade for Transaction management

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		19/02/2008		Created

------------------------------------------------------------------------------->
<cfcomponent hint="Facade for Transaction management" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransactionManager" output="false">
	<cfargument name="transactionFactory" hint="the transaction factory" type="transfer.com.sql.transaction.TransactionFactory" required="Yes">
	<cfscript>
		setTransaction(arguments.transactionFactory.getTransaction());

		return this;
	</cfscript>
</cffunction>

<cffunction name="getTransaction" access="public" returntype="Transaction" output="false">
	<cfreturn instance.Transaction />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setTransaction" access="private" returntype="void" output="false">
	<cfargument name="Transaction" type="Transaction" required="true">
	<cfset instance.Transaction = arguments.Transaction />
</cffunction>

</cfcomponent>