<!--- Document Information -----------------------------------------------------

Title:      SQLFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    the factory for SQL related objects

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/09/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="The Factory for SQL related objects" extends="transfer.com.factory.AbstractBaseFactory" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="SQLFactory" output="false">
	<cfargument name="datasource" hint="The datasource BO" type="transfer.com.sql.Datasource" required="Yes" _autocreate="false">
	<cfargument name="xmlFileReader" hint="The file path to the config file" type="transfer.com.io.XMLFileReader" required="Yes" _autocreate="false">
	<cfargument name="objectManager" hint="The object manager to query" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="utility" hint="The utility class" type="transfer.com.util.Utility" required="Yes" _autocreate="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfargument name="transactionManager" type="transfer.com.sql.transaction.TransactionManager" required="true" _autocreate="false">
	<cfscript>
		super.init();

		setSingleton(arguments.datasource, "transfer.com.sql.Datasource");
		setSingleton(arguments.transactionManager.getTransaction());
		setSingleton(arguments.xmlFileReader);
		setSingleton(arguments.objectManager);
		setSingleton(arguments.utility);
		setSingleton(arguments.javaLoader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getNullableDAO" hint="returns the nullable DAO" access="public" returntype="transfer.com.sql.NullableDAO" output="false">
	<cfreturn getSingleton("transfer.com.sql.NullableDAO") />
</cffunction>

<cffunction name="getSQLValue" hint="returns the SQL Value Resolver" access="public" returntype="transfer.com.sql.SQLValue" output="false">
	<cfreturn getSingleton("transfer.com.sql.SQLValue") />
</cffunction>

<cffunction name="getTransferInserter" hint="returns the transfer inserted" access="public" returntype="transfer.com.sql.TransferInserter" output="false">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="getTransferUpdater" hint="returns the transfer updater" access="public" returntype="transfer.com.sql.TransferUpdater" output="false">
	<cfreturn getSingleton("transfer.com.sql.TransferUpdater") />
</cffunction>

<cffunction name="getTransferDeleter" hint="get the transfer deleter" access="public" returntype="transfer.com.sql.TransferDeleter" output="false">
	<cfreturn getSingleton("transfer.com.sql.TransferDeleter") />
</cffunction>

<cffunction name="getTransferGateway" hint="returns the transfer gateway" access="public" returntype="transfer.com.sql.TransferGateway" output="false">
	<cfreturn getSingleton("transfer.com.sql.TransferGateway") />
</cffunction>

<cffunction name="getTransferSelecter" hint="returns the transfer inserted" access="public" returntype="transfer.com.sql.TransferSelecter" output="false">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="getTransferRefresher" hint="returns the transfer refresher" access="public" returntype="transfer.com.sql.TransferRefresher" output="false">
	<cfreturn getSingleton("transfer.com.sql.TransferRefresher") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>