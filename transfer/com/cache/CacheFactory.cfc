<!--- Document Information -----------------------------------------------------

Title:      CacheFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    The Factory object for creating Cache objects

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/09/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="The Factory object for creating Cache objects" extends="transfer.com.factory.AbstractBaseFactory" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="CacheFactory" output="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="eventManager" type="transfer.com.events.EventManager" required="true" _autocreate="false">
	<cfargument name="cacheConfigManager" hint="The cache config manager" type="transfer.com.cache.CacheConfigManager" required="Yes" _autocreate="false">
	<cfargument name="facadeFactory" hint="The facade factory to access caches" type="transfer.com.facade.FacadeFactory" required="Yes" _autocreate="false">
	<cfargument name="transfer" hint="Need transfer to call discard" type="transfer.com.Transfer" required="Yes" _autocreate="false">
	<cfargument name="transaction" hint="The Transaction service" type="transfer.com.sql.transaction.Transaction" required="Yes"
				_factory="transfer.com.sql.transaction.TransactionManager" _factoryMethod="getTransaction" _autocreate="false">
	<cfscript>
		super.init();

		setSingleton(arguments.objectManager);
		setSingleton(arguments.eventManager);
		setSingleton(arguments.cacheConfigManager);
		setSingleton(arguments.facadeFactory);
		setSingleton(arguments.transfer);
		setSingleton(arguments.transaction);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getSoftReferenceHandler" hint="returns the soft reference hanndler" access="public" returntype="transfer.com.cache.SoftReferenceHandler" output="false">
	<cfreturn getSingleton("transfer.com.cache.SoftReferenceHandler") />
</cffunction>

<cffunction name="getValidateCacheState" hint="returns a validate cache state object" access="public" returntype="transfer.com.cache.ValidateCacheState" output="false">
	<cfreturn getSingleton("transfer.com.cache.ValidateCacheState") />
</cffunction>

<cffunction name="getCacheSynchronise" hint="returns a cache synchronisation object" access="public" returntype="transfer.com.cache.CacheSynchronise" output="false">
	<cfreturn getSingleton("transfer.com.cache.CacheSynchronise") />
</cffunction>

<cffunction name="getTransactionQueue" hint="returns the Transaction Queue service" access="public" returntype="transfer.com.cache.TransactionQueue" output="false">
	<cfreturn getSingleton("transfer.com.cache.TransactionQueue") />
</cffunction>

<cffunction name="getCacheMonitor" hint="returns Cache Monitoring service" access="public" returntype="transfer.com.cache.CacheMonitor" output="false">
	<cfreturn getSingleton("transfer.com.cache.CacheMonitor") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>