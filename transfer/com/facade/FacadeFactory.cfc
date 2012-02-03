<!--- Document Information -----------------------------------------------------

Title:      FacadeFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Factory for getting Scope Facades

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		16/05/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="FacadeFactory" hint="The Factory for getting facades" extends="transfer.com.factory.AbstractBaseFactory">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="FacadeFactory" output="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="cacheConfigManager" hint="The Cache config Manager" type="transfer.com.cache.CacheConfigManager" required="Yes" _autocreate="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		var count = 0;
		var concPackage = "edu.emory.mathcs.backport.java.util.concurrent.";

		//for static properties
		var TimeUnit = arguments.javaLoader.create("#concPackage#TimeUnit");
		var threadPool = 0;

		super.init();

		setSingleton(arguments.javaloader);
		setSingleton(arguments.cacheConfigManager);

		//setup a thread pool
		count = arguments.objectManager.getCachedClassCount();

		//if it's 0, we don't need it, and it throws an error
		if(count)
		{

			threadPool = arguments.javaLoader.create("#concPackage#ThreadPoolExecutor").init(JavaCast("int", 0),
																					JavaCast("int", count),
																					JavaCast("long", 60), //60 seconds timeout
																					TimeUnit.SECONDS,
																					arguments.javaloader.create("#concPackage#SynchronousQueue").init(),
																					//silently discard if we hit our limits.
																					//use the $ sign for the inner class name
																					arguments.javaloader.create("#concPackage#ThreadPoolExecutor$DiscardPolicy").init()
																					);

			setThreadPool(threadPool);
		}
		else
		{
			//put something in there for autowiring
			setThreadPool(0);
		}

		return this;
	</cfscript>
</cffunction>

<cffunction name="configure" hint="configure for di loops" access="public" returntype="void" output="false">
	<cfargument name="eventManager" type="transfer.com.events.EventManager" required="true">
	<cfargument name="cacheManager" hint="the cache manager" type="transfer.com.cache.CacheManager" required="Yes">
	<cfscript>
		var map = StructNew();
		var cacheConfigManager = getCacheConfigManager();


		setSingleton(arguments.eventManager);
		setSingleton(arguments.cacheManager);

		//build the lookup
		map.instance = getInstanceFacade();
		map.application = getApplicationFacade();
		map.session = getSessionFacade();
		map.transaction = getSessionFacade();
		map.request = getRequestFacade();
		map.none = getNoneFacade();
		map.server = getServerFacade();

		setFacadeMap(map);

		//setup keys
		getInstanceFacade().configure(cacheConfigManager.getScope("instance").getKey());
		getApplicationFacade().configure(cacheConfigManager.getScope("application").getKey());
		getRequestFacade().configure(cacheConfigManager.getScope("request").getKey());
		getServerFacade().configure(cacheConfigManager.getScope("server").getKey());
		getSessionFacade().configure(cacheConfigManager.getScope("session").getKey());
		getNoneFacade().configure(cacheConfigManager.getScope("none").getKey());
	</cfscript>
</cffunction>

<cffunction name="getApplicationFacade" access="public" returntype="ApplicationFacade" output="false">
	<cfreturn getSingleton("transfer.com.facade.ApplicationFacade") />
</cffunction>

<cffunction name="getInstanceFacade" access="public" returntype="InstanceFacade" output="false">
	<cfreturn getSingleton("transfer.com.facade.InstanceFacade") />
</cffunction>

<cffunction name="getRequestFacade" access="public" returntype="RequestFacade" output="false">
	<cfreturn getSingleton("transfer.com.facade.RequestFacade") />
</cffunction>

<cffunction name="getServerFacade" access="public" returntype="ServerFacade" output="false">
	<cfreturn getSingleton("transfer.com.facade.ServerFacade") />
</cffunction>

<cffunction name="getSessionFacade" access="public" returntype="SessionFacade" output="false">
	<cfreturn getSingleton("transfer.com.facade.SessionFacade") />
</cffunction>

<cffunction name="getNoneFacade" access="public" returntype="NoneFacade" output="false">
	<cfreturn getSingleton("transfer.com.facade.NoneFacade") />
</cffunction>

<cffunction name="getFacadeByScope" hint="Returns the right facade depending on what scope you enter" access="public" returntype="AbstractBaseFacade" output="false">
	<cfargument name="scope" hint="The scope you need a facade for" type="string" required="Yes">
	<cfscript>
		return StructFind(getFacadeMap(), arguments.scope);
	</cfscript>
</cffunction>

<cffunction name="getThreadPool" access="public" returntype="any" output="false">
	<cfreturn instance.threadPool />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getFacadeMap" access="private" returntype="struct" output="false">
	<cfreturn instance.facadeMap />
</cffunction>

<cffunction name="setFacadeMap" access="private" returntype="void" output="false">
	<cfargument name="facadeMap" type="struct" required="true">
	<cfset instance.facadeMap = arguments.facadeMap />
</cffunction>

<cffunction name="setThreadPool" access="private" returntype="void" output="false">
	<cfargument name="threadPool" type="any" required="true">
	<cfset instance.threadPool = arguments.threadPool />
</cffunction>

<cffunction name="getCacheConfigManager" access="private" returntype="transfer.com.cache.CacheConfigManager" output="false">
	<cfreturn getSingleton("transfer.com.cache.CacheConfigManager") />
</cffunction>

</cfcomponent>