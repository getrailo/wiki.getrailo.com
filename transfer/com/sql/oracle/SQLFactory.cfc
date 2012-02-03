<!--- Document Information -----------------------------------------------------

Title:      SQLFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    The SQL Factory for mySQL

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/09/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="The SQL Factory for mySQL" extends="transfer.com.sql.SQLFactory" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="getTransferInserter" hint="returns the transfer inserted" access="public" returntype="transfer.com.sql.TransferInserter" output="false">
	<cfreturn getSingleton("transfer.com.sql.oracle.TransferInserter") />
</cffunction>

<cffunction name="getTransferSelecter" hint="returns the transfer inserted" access="public" returntype="transfer.com.sql.TransferSelecter" output="false">
	<cfreturn getSingleton("transfer.com.sql.oracle.TransferSelecter") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>