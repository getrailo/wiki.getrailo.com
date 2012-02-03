<!--- Document Information -----------------------------------------------------

Title:      Factory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    this is the global Factory for Transfer factories, and top level managers

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/09/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="this is the global Factory for Transfer factories, and top level managers" extends="transfer.com.factory.AbstractBaseFactory" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Factory" output="false">
	<cfscript>
		super.init();

		return this;
	</cfscript>
</cffunction>

<cffunction name="getFacadeFactory" hint="" access="public" returntype="transfer.com.facade.FacadeFactory" output="false">
	<cfreturn getSingleton("transfer.com.facade.FacadeFactory") />
</cffunction>

<cffunction name="getJavaLoader" hint="get the javaloader" access="public" returntype="transfer.com.util.JavaLoader" output="false">
	<cfreturn getSingleton("transfer.com.util.JavaLoader") />
</cffunction>

<cffunction name="getCacheConfigManager" hint="returns the cache config manager" access="public" returntype="transfer.com.cache.CacheConfigManager" output="false">
	<cfreturn getSingleton("transfer.com.cache.CacheConfigManager") />
</cffunction>

<cffunction name="getUtility" hint="returns the Utility class" access="public" returntype="transfer.com.util.Utility" output="false">
	<cfreturn getSingleton("transfer.com.util.Utility") />
</cffunction>

<cffunction name="getDataSource" access="public" hint="Returns the datasource bean" returntype="transfer.com.sql.Datasource" output="false">
	<cfreturn getSingleton("transfer.com.sql.Datasource") />
</cffunction>

<cffunction name="getMethodInjector" hint="returns the method injector class" access="public" returntype="transfer.com.dynamic.MethodInjector" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.MethodInjector") />
</cffunction>

<cffunction name="getObjectManager" hint="returns the object manager" access="public" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn getSingleton("transfer.com.object.ObjectManager") />
</cffunction>

<cffunction name="getSQLManager" hint="gets the SQL Manager" access="public" returntype="transfer.com.sql.SQLManager" output="false">
	<cfreturn getSingleton("transfer.com.sql.SQLManager") />
</cffunction>

<cffunction name="getTQLManager" hint="returns the TQL Manager" access="public" returntype="transfer.com.tql.TQLManager" output="false">
	<cfreturn getSingleton("transfer.com.tql.TQLManager") />
</cffunction>

<cffunction name="getDynamicManager" hint="returns the dynamic Manager" access="public" returntype="transfer.com.dynamic.DynamicManager" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.DynamicManager") />
</cffunction>

<cffunction name="getCacheManager" hint="returns the cache manager" access="public" returntype="transfer.com.cache.CacheManager" output="false">
	<cfreturn getSingleton("transfer.com.cache.CacheManager") />
</cffunction>

<cffunction name="getEventManager" hint="returns the event manager" access="public" returntype="transfer.com.events.EventManager" output="false">
	<cfreturn getSingleton("transfer.com.events.EventManager") />
</cffunction>

<cffunction name="getTransactionManager" hint="returns the Transaction manager" access="public" returntype="transfer.com.sql.transaction.TransactionManager" output="false">
	<cfreturn getSingleton("transfer.com.sql.transaction.TransactionManager") />
</cffunction>

<!--- Child factories --->

<cffunction name="getDatasourceFactory" hint="get the datasource factory" access="public" returntype="transfer.com.sql.DatasourceFactory" output="false">
	<cfif getCFMLVersion().getVersion() eq "cf8">
		<cfreturn getSingleton("transfer.com.sql.cf8.DatasourceFactory") />
	</cfif>
	<cfreturn getSingleton("transfer.com.sql.DatasourceFactory") />
</cffunction>

<cffunction name="getCacheFactory" hint="returns the cache factory" access="public" returntype="transfer.com.cache.CacheFactory" output="false">
	<cfif getCFMLVersion().getVersion() eq "cf8">
		<cfreturn getSingleton("transfer.com.cache.cf8.CacheFactory") />
	</cfif>
	<cfreturn getSingleton("transfer.com.cache.CacheFactory") />
</cffunction>

<cffunction name="getSQLFactory" hint="returns the sql factory" access="public" returntype="transfer.com.sql.SQLFactory" output="false">
	<cfscript>
		return getSingleton("transfer.com.sql.#getDatasource().getDatabaseType()#.SQLFactory");
	</cfscript>
</cffunction>

<cffunction name="getDynamicFactory" hint="returns the Dynamic factory" access="public" returntype="transfer.com.dynamic.DynamicFactory" output="false">
	<cfif getCFMLVersion().getVersion() eq "cf8">
		<cfreturn getSingleton("transfer.com.dynamic.cf8.DynamicFactory") />
	</cfif>
	<cfreturn getSingleton("transfer.com.dynamic.DynamicFactory") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getCFMLVersion" access="private" returntype="transfer.com.factory.CFMLVersion" output="false">
	<cfreturn getSingleton("transfer.com.factory.CFMLVersion") />
</cffunction>

</cfcomponent>