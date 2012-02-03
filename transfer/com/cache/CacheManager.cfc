<!--- Document Information -----------------------------------------------------

Title:      CacheManager.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Manages data persistance

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		19/07/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="CacheManager" hint="Manages data persistance">

<cfscript>
	instance = StructNew();
	//instance.sys = createObject("java", "java.lang.System");
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="CacheManager" output="false">
	<cfargument name="cacheFactory" hint="the cache factory" type="transfer.com.cache.CacheFactory" required="Yes" _factoryMethod="getCacheFactory">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="cacheConfigManager" hint="The cache config manager" type="transfer.com.cache.CacheConfigManager" required="Yes" _autocreate="false">
	<cfargument name="facadeFactory" hint="The facade factory to access caches" type="transfer.com.facade.FacadeFactory" required="Yes" _autocreate="false">
	<cfargument name="javaLoader" hint="The JavaLoader for loading the caching objects" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		setObjectManager(arguments.objectManager);
		setMethodInvoker(arguments.cacheFactory.getMethodInvoker());
		setCacheConfigManager(arguments.cacheConfigManager);
		setFacadeFactory(arguments.facadeFactory);
		setJavaLoader(arguments.javaLoader);

		//append this circular dependency
		arguments.cacheFactory.setSingleton(this);

		setSoftReferenceHandler(arguments.cacheFactory.getSoftReferenceHandler());
		setValidateCacheState(arguments.cacheFactory.getValidateCacheState());
		setCacheSynchronise(arguments.cacheFactory.getCacheSynchronise());
		setTransactionQueue(arguments.cacheFactory.getTransactionQueue());
		setCacheMonitor(arguments.cacheFactory.getCacheMonitor());

		return this;
	</cfscript>
</cffunction>

<cffunction name="register" hint="Registers the TransferObject for caching with a soft reference, returns java.lang.ref.SoftReference" access="public" returntype="any" output="false">
	<cfargument name="transfer" hint="The transfer object to be registered" type="transfer.com.TransferObject" required="Yes">
	<cfreturn getSoftReferenceHandler().register(arguments.transfer) />
</cffunction>

<cffunction name="add" hint="Adds a Transfer Object to the Pool" access="public" returntype="void" output="false">
	<cfargument name="softRef" hint="java.lang.ref.SoftReference: The soft ref to the transfer object to be stored" type="any" required="Yes">
	<cfscript>
		var local = StructNew();
		var object = 0;
		var key = 0;
		var cache = 0;
		var className = 0;
		local.transfer = arguments.softRef.get();

		getSoftReferenceHandler().reap();

		if(StructKeyExists(local, "transfer"))
		{
			className = local.transfer.getClassName();

			object = getObjectManager().getObject(className);
			cache = retrieveCache(className);
			key = JavaCast("string", getMethodInvoker().invokeMethod(local.transfer, "get" & object.getPrimaryKey().getName()));

			cache.add(className, key, softRef);
		}
	</cfscript>
</cffunction>

<cffunction name="have" hint="Checks if the Transfer is persistent in this" access="public" returntype="boolean" output="false">
	<cfargument name="class" hint="The name of the class" type="string" required="Yes">
	<cfargument name="key" hint="The key for the id of the data" type="string" required="Yes">
	<cfscript>
		var cache = retrieveCache(arguments.class);
		arguments.key = JavaCast("string", arguments.key);

		return cache.has(arguments.class, arguments.key);
	</cfscript>
</cffunction>

<cffunction name="get" hint="gets a TransferObject from the pool" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="class" hint="The name of the class" type="string" required="Yes">
	<cfargument name="key" hint="The key for the id of the data" type="string" required="Yes">
	<cfscript>
		var cache = retrieveCache(arguments.class);
		var transfer = 0;

		getSoftReferenceHandler().reap();

		arguments.key = JavaCast("string", arguments.key);

		return cache.get(arguments.class, arguments.key);
	</cfscript>
</cffunction>

<cffunction name="discard" hint="removes a transfer from the cache" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to be stored" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var class = arguments.transfer.getClassName();
		var object = getObjectManager().getObject(class);
		var key = JavaCast("string", getMethodInvoker().invokeMethod(arguments.transfer, "get" & object.getPrimaryKey().getName()));
		var cache = retrieveCache(class);
	</cfscript>

	<cfif cache.has(class, key)>
		<cflock name="transfer.discard.#class#.#key#" throwontimeout="true" timeout="60">
		<cfscript>
			if(cache.has(class, key))
			{
				cache.discard(class, key);
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfscript>
		getSoftReferenceHandler().reap();
	</cfscript>
</cffunction>

<cffunction name="discardAll" hint="discards everything from the cache" access="public" returntype="void" output="false">
	<cfscript>
		getSoftReferenceHandler().clearAllReferences();
		getSoftReferenceHandler().reap();
	</cfscript>
</cffunction>

<cffunction name="isTransactionScoped" hint="Is this transaction scoped or not" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to be stored" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var scope = getCacheConfigManager().getCacheConfig().getConfig(arguments.transfer.getClassName()).getScope();

		return (scope eq "transaction");
	</cfscript>
</cffunction>

<cffunction name="synchronise" hint="syncronises the data, and returns the cached TransferObject if there is one, otherwise returns the original TransferObject" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="transfer" hint="The transfer object to syncronise" type="transfer.com.TransferObject" required="Yes">
	<cfreturn getCacheSynchronise().synchronise(arguments.transfer) />
</cffunction>

<cffunction name="validateIsCached" hint="validates if a TransferObject is the same one as in cache" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to syncronise" type="transfer.com.TransferObject" required="Yes">
	<cfreturn getValidateCacheState().validateIsCached(arguments.transfer) />
</cffunction>

<cffunction name="appendTransactionQueue" hint="append a Transfer Objects to the transaction queue" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="the transfer object to append" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		getTransactionQueue().append(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="removeTransactionQueue" hint="append a Transfer Objects to the transaction queue" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="the transfer object to append" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		getTransactionQueue().remove(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="getCacheMonitor" access="public" returntype="CacheMonitor" output="false">
	<cfreturn instance.CacheMonitor />
</cffunction>

<cffunction name="hit" hint="add an extra count to this cache's value being found successfully" access="public" returntype="void" output="false">
	<cfargument name="className" hint="the className being hit" type="string" required="Yes">
	<cfscript>
		getCacheMonitor().hit(argumentCollection=arguments);
	</cfscript>
</cffunction>

<cffunction name="miss" hint="add an extra count to this cache's value not being found" access="public" returntype="void" output="false">
	<cfargument name="className" hint="the className being missed" type="string" required="Yes">
	<cfscript>
		getCacheMonitor().miss(argumentCollection=arguments);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="retrieveCache" hint="Returns a com.compoundtheory.objectcache.CacheManager" access="private" returntype="any" output="false">
	<cfargument name="class" hint="The name of the class" type="string" required="Yes">
	<cfscript>
		var scope = getCacheConfigManager().getCacheConfig().getConfig(arguments.class).getScope();

		var facade = getFacadeFactory().getFacadeByScope(scope);

		return facade.getCacheManager();
	</cfscript>
</cffunction>

<cffunction name="getSoftReferenceHandler" access="private" returntype="transfer.com.cache.SoftReferenceHandler" output="false">
	<cfreturn instance.SoftReferenceHandler />
</cffunction>

<cffunction name="setSoftReferenceHandler" access="private" returntype="void" output="false">
	<cfargument name="SoftReferenceHandler" type="transfer.com.cache.SoftReferenceHandler" required="true">
	<cfset instance.SoftReferenceHandler = arguments.SoftReferenceHandler />
</cffunction>

<cffunction name="getCacheConfigManager" access="private" returntype="transfer.com.cache.CacheConfigManager" output="false">
	<cfreturn instance.CacheConfigManager />
</cffunction>

<cffunction name="setCacheConfigManager" access="private" returntype="void" output="false">
	<cfargument name="CacheConfigManager" type="transfer.com.cache.CacheConfigManager" required="true">
	<cfset instance.CacheConfigManager = arguments.CacheConfigManager />
</cffunction>

<cffunction name="getFacadeFactory" access="private" returntype="transfer.com.facade.FacadeFactory" output="false">
	<cfreturn instance.FacadeFactory />
</cffunction>

<cffunction name="setFacadeFactory" access="private" returntype="void" output="false">
	<cfargument name="FacadeFactory" type="transfer.com.facade.FacadeFactory" required="true">
	<cfset instance.FacadeFactory = arguments.FacadeFactory />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getMethodInvoker" access="private" returntype="transfer.com.dynamic.MethodInvoker" output="false">
	<cfreturn instance.MethodInvoker />
</cffunction>

<cffunction name="setMethodInvoker" access="private" returntype="void" output="false">
	<cfargument name="MethodInvoker" type="transfer.com.dynamic.MethodInvoker" required="true">
	<cfset instance.MethodInvoker = arguments.MethodInvoker />
</cffunction>

<cffunction name="getJavaLoader" access="private" returntype="transfer.com.util.JavaLoader" output="false">
	<cfreturn instance.JavaLoader />
</cffunction>

<cffunction name="setJavaLoader" access="private" returntype="void" output="false">
	<cfargument name="JavaLoader" type="transfer.com.util.JavaLoader" required="true">
	<cfset instance.JavaLoader = arguments.JavaLoader />
</cffunction>

<cffunction name="getCacheSynchronise" access="private" returntype="transfer.com.cache.CacheSynchronise" output="false">
	<cfreturn instance.CacheSynchronise />
</cffunction>

<cffunction name="setCacheSynchronise" access="private" returntype="void" output="false">
	<cfargument name="CacheSynchronise" type="transfer.com.cache.CacheSynchronise" required="true">
	<cfset instance.CacheSynchronise = arguments.CacheSynchronise />
</cffunction>

<cffunction name="getValidateCacheState" access="private" returntype="transfer.com.cache.ValidateCacheState" output="false">
	<cfreturn instance.ValidateCacheState />
</cffunction>

<cffunction name="setValidateCacheState" access="private" returntype="void" output="false">
	<cfargument name="ValidateCacheState" type="transfer.com.cache.ValidateCacheState" required="true">
	<cfset instance.ValidateCacheState = arguments.ValidateCacheState />
</cffunction>

<cffunction name="getTransactionQueue" access="private" returntype="TransactionQueue" output="false">
	<cfreturn instance.transactionQueue />
</cffunction>

<cffunction name="setTransactionQueue" access="private" returntype="void" output="false">
	<cfargument name="transactionQueue" type="TransactionQueue" required="true">
	<cfset instance.transactionQueue = arguments.transactionQueue />
</cffunction>

<cffunction name="setCacheMonitor" access="private" returntype="void" output="false">
	<cfargument name="CacheMonitor" type="CacheMonitor" required="true">
	<cfset instance.CacheMonitor = arguments.CacheMonitor />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>