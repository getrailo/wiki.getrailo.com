<!--- Document Information -----------------------------------------------------

Title:      SQLManager.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Top level configuration manager for SQL objects

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		19/07/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="SQLManager" hint="Top level configuration manager for SQL objects">

<cffunction name="init" hint="Constructor" access="public" returntype="SQLManager" output="false">
	<cfargument name="sqlFactory" hint="the SQL factory implementation" type="transfer.com.sql.SQLFactory" required="Yes" _factoryMethod="getSQLFactory">
	<cfscript>
		var nullableDAO = arguments.sqlFactory.getNullableDAO();

		variables.instance = StructNew();

		setNullable(nullableDAO.getNullable());

		//set dependencies
		arguments.sqlFactory.setSingleton(getNullable());

		setSQLValue(arguments.sqlFactory.getSQLValue());

		setTransferInserter(arguments.sqlFactory.getTransferInserter());

		setTransferUpdater(arguments.sqlFactory.getTransferUpdater());

		setTransferDeleter(arguments.sqlFactory.getTransferDeleter());

		setTransferGateway(arguments.sqlFactory.getTransferGateway());

		setTransferSelecter(arguments.sqlFactory.getTransferSelecter());

		setTransferRefresher(arguments.sqlFactory.getTransferRefresher());

		return this;
	</cfscript>
</cffunction>

<cffunction name="getNullable" access="public" returntype="transfer.com.sql.Nullable" output="false">
	<cfreturn instance.Nullable />
</cffunction>

<cffunction name="create" hint="Inserts the transfer into the DB" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to insert" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="useTransaction" hint="Whether or not to use an internal transaction block" type="boolean" required="true">
	<cfscript>
		getTransferInserter().create(arguments.transfer, arguments.useTransaction);
	</cfscript>
</cffunction>

<cffunction name="update" hint="Updates the Transfer in the DB" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="useTransaction" hint="Whether or not to use an internal transaction block" type="boolean" required="true">
	<cfscript>
		getTransferUpdater().update(arguments.transfer, arguments.useTransaction);
	</cfscript>
</cffunction>

<cffunction name="delete" hint="Deletes a transfer object" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to insert" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="useTransaction" hint="Whether or not to use an internal transaction block" type="boolean" required="true">
	<cfscript>
		return getTransferDeleter().delete(arguments.transfer, arguments.useTransaction);
	</cfscript>
</cffunction>

<cffunction name="select" hint="Creates and runs the query for the TransferObject" access="public" returntype="query" output="false">
	<cfargument name="object" hint="The Object BO" type="transfer.com.object.Object" required="Yes">
	<cfargument name="key" hint="The id key for the data" type="any" required="Yes">
	<cfargument name="lazyLoadName" hint="the name of the lazy load, if there is one, for locking and caching" type="string" required="No">
	<cfscript>
		return getTransferSelecter().select(argumentCollection=arguments);
	</cfscript>
</cffunction>

<cffunction name="list" hint="Lists a series of object values" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="No" default="">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="No" default="true">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="no" default="true">
	<cfscript>
		return getTransferGateway().list(arguments.className,
											arguments.orderProperty,
											arguments.orderASC,
											arguments.useAliases);
	</cfscript>
</cffunction>

<cffunction name="listByProperty" hint="Lists a series of values, filtered by a given value" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to filter by" type="string" required="Yes">
	<cfargument name="propertyValue" hint="The value to filter by (only simple values)" type="any" required="Yes">
	<cfargument name="onlyRetrievePrimaryKey" hint="boolean to whether or not to only retrieve the primary key" type="boolean" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="No" default="">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="No" default="true">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="no" default="true">

	<cfscript>
		return getTransferGateway().listByProperty(arguments.className,
													arguments.propertyName,
													arguments.propertyValue,
													arguments.onlyRetrievePrimaryKey,
													arguments.orderProperty,
													arguments.orderASC,
													arguments.useAliases);
	</cfscript>
</cffunction>

<cffunction name="listByPropertyMap" hint="Lists values, filtered by a Struct of Property : Value properties" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="propertyMap" hint="Struct with keys that match to properties, and values to filter by" type="struct" required="Yes">
	<cfargument name="onlyRetrievePrimaryKey" hint="boolean to whether or not to only retrieve the primary key" type="boolean" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="No" default="">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="No" default="true">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="no" default="true">

	<cfscript>
		return getTransferGateway().listByPropertyMap(arguments.className,
															arguments.propertyMap,
															arguments.onlyRetrievePrimaryKey,
															arguments.orderProperty,
															arguments.orderASC,
															arguments.useAliases);
	</cfscript>
</cffunction>

<cffunction name="hasInsertRefresh" hint="Check to see if it requires a run of the refresh query" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		return getTransferRefresher().hasInsertRefresh(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="getInsertRefreshQuery" hint="Returns the refresh query for an insert" access="public" returntype="query" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		return getTransferRefresher().getInsertRefreshQuery(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="hasUpdateRefresh" hint="Check to see if it requires a run of the refresh query" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		return getTransferRefresher().hasUpdateRefresh(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="getUpdateRefreshQuery" hint="Returns the refresh query for an insert" access="public" returntype="query" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		return getTransferRefresher().getUpdateRefreshQuery(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="getPropertyColumnValue" hint="Returns the column value, but returns the default null value for the item if it is NULL" access="public" returntype="any" output="false">
	<cfargument name="query" hint="The query we are looking at" type="query" required="Yes">
	<cfargument name="object" hint="The property to get the value for" type="transfer.com.object.Object" required="Yes">
	<cfargument name="property" hint="The property to get the value for" type="transfer.com.object.Property" required="Yes">
	<cfscript>
		return getSQLValue().getPropertyColumnValue(argumentCollection=arguments);
	</cfscript>
</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->



<cffunction name="setNullable" access="private" returntype="void" output="false">
	<cfargument name="Nullable" type="transfer.com.sql.Nullable" required="true">
	<cfset instance.Nullable = arguments.Nullable />
</cffunction>

<cffunction name="getTransferUpdater" access="private" returntype="transfer.com.sql.TransferUpdater" output="false">
	<cfreturn instance.TransferUpdater />
</cffunction>

<cffunction name="setTransferUpdater" access="private" returntype="void" output="false">
	<cfargument name="TransferUpdater" type="transfer.com.sql.TransferUpdater" required="true">
	<cfset instance.TransferUpdater = arguments.TransferUpdater />
</cffunction>

<cffunction name="getTransferInserter" access="private" returntype="transfer.com.sql.TransferInserter" output="false">
	<cfreturn instance.TransferInserter />
</cffunction>

<cffunction name="setTransferInserter" access="private" returntype="void" output="false">
	<cfargument name="TransferInserter" type="transfer.com.sql.TransferInserter" required="true">
	<cfset instance.TransferInserter = arguments.TransferInserter />
</cffunction>

<cffunction name="getTransferDeleter" access="private" returntype="transfer.com.sql.TransferDeleter" output="false">
	<cfreturn instance.TransferDeleter />
</cffunction>

<cffunction name="setTransferDeleter" access="private" returntype="void" output="false">
	<cfargument name="TransferDeleter" type="transfer.com.sql.TransferDeleter" required="true">
	<cfset instance.TransferDeleter = arguments.TransferDeleter />
</cffunction>

<cffunction name="getTransferSelecter" access="private" returntype="transfer.com.sql.TransferSelecter" output="false">
	<cfreturn instance.TransferSelecter />
</cffunction>

<cffunction name="setTransferSelecter" access="private" returntype="void" output="false">
	<cfargument name="TransferSelecter" type="transfer.com.sql.TransferSelecter" required="true">
	<cfset instance.TransferSelecter = arguments.TransferSelecter />
</cffunction>

<cffunction name="getTransferGateway" access="private" returntype="transfer.com.sql.TransferGateway" output="false">
	<cfreturn instance.TransferGateway />
</cffunction>

<cffunction name="setTransferGateway" access="private" returntype="void" output="false">
	<cfargument name="TransferGateway" type="transfer.com.sql.TransferGateway" required="true">
	<cfset instance.TransferGateway = arguments.TransferGateway />
</cffunction>

<cffunction name="getTransferRefresher" access="private" returntype="transfer.com.sql.TransferRefresher" output="false">
	<cfreturn instance.TransferRefresher />
</cffunction>

<cffunction name="setTransferRefresher" access="private" returntype="void" output="false">
	<cfargument name="TransferRefresher" type="transfer.com.sql.TransferRefresher" required="true">
	<cfset instance.TransferRefresher = arguments.TransferRefresher />
</cffunction>

<cffunction name="getSQLValue" access="private" returntype="transfer.com.sql.SQLValue" output="false">
	<cfreturn instance.sqlValue />
</cffunction>

<cffunction name="setSQLValue" access="private" returntype="void" output="false">
	<cfargument name="sqlValue" type="transfer.com.sql.SQLValue" required="true">
	<cfset instance.sqlValue = arguments.sqlValue />
</cffunction>



</cfcomponent>