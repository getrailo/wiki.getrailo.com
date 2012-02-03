<!--- Document Information -----------------------------------------------------

Title:      CacheMonitor.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    The cache monitor class for introspection and statistics on caching

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		14/07/2008		Created

------------------------------------------------------------------------------->

<cfcomponent hint="The cache monitor class for introspection and statistics on caching" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="CacheMonitor" output="false">
	<cfargument name="facadeFactory" hint="The facade factory to access caches" type="transfer.com.facade.FacadeFactory" required="Yes" _autocreate="false">
	<cfargument name="cacheConfigManager" hint="The cache config manager" type="transfer.com.cache.CacheConfigManager" required="Yes" _autocreate="false">
	<cfscript>
		setFacadeFactory(arguments.facadeFactory);
		setCacheConfigManager(arguments.cacheConfigManager);

		resetHitsAndMisses();
		resetEvictions();

		return this;
	</cfscript>
</cffunction>

<cffunction name="getCachedClasses" hint="returns all the cached classes" access="public" returntype="array" output="false">
	<cfscript>
		var args = StructNew();
		args.classArray = createObject("java", "java.util.ArrayList").init();

		eachCacheManager(executeGetCachedClasses, args);

		return args.classArray;
	</cfscript>
</cffunction>

<cffunction name="getCacheSettings" hint="gets the cache settings for a class, as a struct" access="public" returntype="struct" output="false">
	<cfargument name="className" hint="the name of the class" type="string" required="Yes">
	<cfscript>
		var result = StructNew();
		var config = getCacheConfigManager().getCacheConfig().getConfig(arguments.className);

		result.scope = config.getScope();
		result.maxobjects = config.getMaxObjects();
		result.maxminutespersisted = config.getSecondsPersisted() / 60;
		result.accessedminutestimeout = config.getSecondsAccessedTimeout() / 60;

		if(result.maxobjects eq config.UNLIMITED_OBJECTS)
		{
			result.maxobjects = "unlimited";
		}

		if(result.maxminutespersisted eq config.UNLIMITED_SECONDS)
		{
			result.maxminutespersisted = "unlimited";
		}

		if(result.accessedminutestimeout eq config.NONE_TIMEOUT)
		{
			result.accessedminutestimeout = "unlimited";
		}

		return result;
	</cfscript>
</cffunction>

<cffunction name="getEstimatedSize" hint="A fast lookup of how many items in the cache, simply by checking its size, which may not be exactly accurate" access="public" returntype="numeric" output="false">
	<cfargument name="className" hint="the name of the class" type="string" required="Yes">
	<cfscript>
		var config = getCacheConfigManager().getCacheConfig().getConfig(arguments.className);
		var facade = getFacadeFactory().getFacadeByScope(config.getScope());

		if(facade.hasCacheManager())
		{
			return facade.getCacheManager().getEstimatedSize(arguments.className);
		}

		return 0;
	</cfscript>
</cffunction>

<cffunction name="getCalculatedSize" hint="A slow look at how many items are in cache, where a copy of the cache is taken, and inspected item by item." access="public" returntype="numeric" output="false">
	<cfargument name="className" hint="the name of the class" type="string" required="Yes">
	<cfscript>
		var config = getCacheConfigManager().getCacheConfig().getConfig(arguments.className);
		var facade = getFacadeFactory().getFacadeByScope(config.getScope());

		if(facade.hasCacheManager())
		{
			return facade.getCacheManager().getCalculatedSize(arguments.className);
		}

		return 0;
	</cfscript>
</cffunction>

<cffunction name="getTotalEstimatedSize" hint="get the estimated size for all classes" access="public" returntype="numeric" output="false">
	<cfscript>
		var iterator = getCachedClasses().iterator();
		var sum = 0;

		while(iterator.hasNext())
		{
			sum = sum + getEstimatedSize(iterator.next());
		}

		return sum;
	</cfscript>
</cffunction>

<cffunction name="getTotalCalculatedSize" hint="get the calculated size for all classes" access="public" returntype="numeric" output="false">
	<cfscript>
		var iterator = getCachedClasses().iterator();
		var sum = 0;

		while(iterator.hasNext())
		{
			sum = sum + getCalculatedSize(iterator.next());
		}

		return sum;
	</cfscript>
</cffunction>

<cffunction name="getHits" hint="returns the number of hits for that class" access="public" returntype="numeric" output="false">
	<cfargument name="className" hint="the class to retrive hits for" type="string" required="Yes">
	<cfscript>
		return getMapValue(getHitMap(), arguments.className);
	</cfscript>
</cffunction>

<cffunction name="getMisses" hint="returns the number of misses for that class" access="public" returntype="numeric" output="false">
	<cfargument name="className" hint="the class to retrive hits for" type="string" required="Yes">
	<cfscript>
		return getMapValue(getMissMap(), arguments.className);
	</cfscript>
</cffunction>

<cffunction name="resetHitsAndMisses" hint="resets the Hit and MIss counters back to 0" access="public" returntype="void" output="false">
	<cfscript>
		setHitMap(StructNew());
		setMissMap(StructNew());
	</cfscript>
</cffunction>

<cffunction name="getTotalHits" hint="get the total number of hits" access="public" returntype="numeric" output="false">
	<cfscript>
		var iterator = getCachedClasses().iterator();
		var sum = 0;

		while(iterator.hasNext())
		{
			sum = sum + getHits(iterator.next());
		}

		return sum;
	</cfscript>
</cffunction>

<cffunction name="getTotalMisses" hint="get the total number of hits" access="public" returntype="numeric" output="false">
	<cfscript>
		var iterator = getCachedClasses().iterator();
		var sum = 0;

		while(iterator.hasNext())
		{
			sum = sum + getMisses(iterator.next());
		}

		return sum;
	</cfscript>
</cffunction>

<cffunction name="getHitMissRatio" hint="returns the ratio of hits vs misses. Values above 1 mean that more hits are occuring than misses." access="public" returntype="numeric" output="false">
	<cfargument name="className" hint="the name of the class to get the ratio for" type="string" required="Yes">
	<cfscript>
		var misses = getMisses(arguments.className);

		//avoid /0 errors
		if(misses eq 0)
		{
			return 0;
		}

		return getHits(arguments.className) / misses;
	</cfscript>
</cffunction>

<cffunction name="getTotalHitMissRatio" hint="returns the ratio of total hits vs total misses. Values above 1 mean that more hits are occurring more than misses." access="public" returntype="numeric" output="false">
	<cfscript>
		var misses = getTotalMisses();

		//avoid /0 errors
		if(misses eq 0)
		{
			return 0;
		}

		return getTotalHits() / misses;
	</cfscript>
</cffunction>

<cffunction name="resetEvictions" hint="resets eviction counters back to 0" access="public" returntype="void" output="false">
	<cfscript>
		setEvictMap(StructNew());
	</cfscript>
</cffunction>

<cffunction name="getEvictions" hint="get the total number of cache evictions for this class" access="public" returntype="numeric" output="false">
	<cfargument name="className" hint="the class to retrive hits for" type="string" required="Yes">
	<cfscript>
		return getMapValue(getEvictMap(), arguments.className);
	</cfscript>
</cffunction>

<cffunction name="getTotalEvictions" hint="get the total number of cache evictions" access="public" returntype="numeric" output="false">
	<cfscript>
		var iterator = getCachedClasses().iterator();
		var sum = 0;

		while(iterator.hasNext())
		{
			sum = sum + getEvictions(iterator.next());
		}

		return sum;
	</cfscript>
</cffunction>


<!------------------------------------------- PACKAGE ------------------------------------------->

<cffunction name="hit" hint="add an extra count to this cache's value being found successfully" access="package" returntype="void" output="false">
	<cfargument name="className" hint="the className being hit" type="string" required="Yes">
	<cfscript>
		var map = getValueMap(getHitMap(), arguments.className, "hit");

		map[arguments.className] = map[arguments.className] + 1;
	</cfscript>
</cffunction>

<cffunction name="miss" hint="add an extra count to this cache's value not being found" access="package" returntype="void" output="false">
	<cfargument name="className" hint="the className being missed" type="string" required="Yes">
	<cfscript>
		var map = getValueMap(getMissMap(), arguments.className, "miss");

		map[arguments.className] = map[arguments.className] + 1;
	</cfscript>
</cffunction>

<cffunction name="evict" hint="adds ane extra counter to the cache eviction count" access="package" returntype="void" output="false">
	<cfargument name="className" hint="the className being evicted" type="string" required="Yes">
	<cfscript>
		var map = getValueMap(getEvictMap(), arguments.className, "evict");

		map[arguments.className] = map[arguments.className] + 1;
	</cfscript>
</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getValueMap" hint="returns default values for a value map" access="private" returntype="struct" output="false">
	<cfargument name="map" hint="the structure being returned" type="struct" required="Yes">
	<cfargument name="className" hint="the className being retrieved" type="string" required="Yes">
	<cfargument name="operation" hint="the name of the operation" type="string" required="Yes">

	<cfif NOT StructKeyExists(arguments.map, arguments.className)>
		<cflock name="transfer.CacheMonitor.#arguments.operation#.#arguments.className#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT StructKeyExists(arguments.map, arguments.className))
			{
				arguments.map[arguments.className] = 0;
			}
		</cfscript>
		</cflock>
	</cfif>

	<cfreturn arguments.map />
</cffunction>

<cffunction name="getMapValue" hint="returns a map value, if it exists, otherwise, returns 0" access="private" returntype="numeric" output="false">
	<cfargument name="map" hint="the map to search for" type="struct" required="Yes">
	<cfargument name="className" hint="the className being retrieved" type="string" required="Yes">
	<cfscript>
		if(StructKeyExists(arguments.map, arguments.className))
		{
			return StructFind(arguments.map, arguments.className);
		}

		return 0;
	</cfscript>
</cffunction>

<cffunction name="eachCacheManager" hint="HOF that runs a function against each facade's ConfigManager, if it has one" access="private" returntype="void" output="false">
	<cfargument name="function" hint="the function to call on the CacheManager" type="any" required="Yes">
	<cfargument name="args" hint="the argument data to pass from function call to function call" type="struct" required="false" default="#StructNew()#">
	<cfscript>
		var factory = getFacadeFactory(); //speed

		invokeFacadeCacheManager(factory.getInstanceFacade(), arguments.function, arguments.args);
		invokeFacadeCacheManager(factory.getApplicationFacade(), arguments.function, arguments.args);

		try
		{
			//we do this, as the request scope variables can just dissapear
			invokeFacadeCacheManager(factory.getRequestFacade(), arguments.function, arguments.args);
		}
		catch(coldfusion.runtime.UndefinedElementException exc)	{ /*do nothing*/ }

		invokeFacadeCacheManager(factory.getServerFacade(), arguments.function, arguments.args);

		try
		{
			//we do this, as the session scope variables can just dissapear
			invokeFacadeCacheManager(factory.getSessionFacade(), arguments.function, arguments.args);
		}
		catch(coldfusion.runtime.UndefinedElementException exc) { /*do nothing*/ }

		//really not required, but to keep clean
		invokeFacadeCacheManager(factory.getNoneFacade(), arguments.function, arguments.args);
	</cfscript>
</cffunction>

<cffunction name="invokeFacadeCacheManager" hint="invokes the function against the cache manager if the facade has one" access="private" returntype="void" output="false">
	<cfargument name="facade" hint="the facade to call against" type="transfer.com.facade.AbstractBaseFacade" required="Yes">
	<cfargument name="function" hint="the function to call on the CacheManager" type="any" required="Yes">
	<cfargument name="args" hint="the argument data to pass from function call to function call" type="struct" required="true">
	<cfscript>
		var call = arguments.function;

		if(facade.hasCacheManager())
		{
			arguments.args.cacheManager = facade.getCacheManager();
			call(argumentCollection=arguments.args);
		}
	</cfscript>
</cffunction>

<!--- HOF commands --->

<cffunction name="executeGetCachedClasses" hint="adds the keyset from the cached classes to the array in the arguments" access="private" returntype="void" output="false">
	<cfargument name="cacheManager" hint="the java cache manager" type="any" required="Yes">
	<cfargument name="classArray" hint="the array of classes" type="array" required="Yes">
	<cfscript>
		arguments.classArray.addAll(arguments.cacheManager.getCachedClasses());
	</cfscript>
</cffunction>

<!--- /HOF commands --->

<cffunction name="getFacadeFactory" access="private" returntype="transfer.com.facade.FacadeFactory" output="false">
	<cfreturn instance.FacadeFactory />
</cffunction>

<cffunction name="setFacadeFactory" access="private" returntype="void" output="false">
	<cfargument name="FacadeFactory" type="transfer.com.facade.FacadeFactory" required="true">
	<cfset instance.FacadeFactory = arguments.FacadeFactory />
</cffunction>

<cffunction name="getCacheConfigManager" access="private" returntype="transfer.com.cache.CacheConfigManager" output="false">
	<cfreturn instance.CacheConfigManager />
</cffunction>

<cffunction name="setCacheConfigManager" access="private" returntype="void" output="false">
	<cfargument name="CacheConfigManager" type="transfer.com.cache.CacheConfigManager" required="true">
	<cfset instance.CacheConfigManager = arguments.CacheConfigManager />
</cffunction>

<cffunction name="getHitMap" access="private" returntype="struct" output="false">
	<cfreturn instance.HitMap />
</cffunction>

<cffunction name="setHitMap" access="private" returntype="void" output="false">
	<cfargument name="HitMap" type="struct" required="true">
	<cfset instance.HitMap = arguments.HitMap />
</cffunction>

<cffunction name="getMissMap" access="private" returntype="struct" output="false">
	<cfreturn instance.MissMap />
</cffunction>

<cffunction name="setMissMap" access="private" returntype="void" output="false">
	<cfargument name="MissMap" type="struct" required="true">
	<cfset instance.MissMap = arguments.MissMap />
</cffunction>

<cffunction name="getEvictMap" access="private" returntype="struct" output="false">
	<cfreturn instance.evictMap />
</cffunction>

<cffunction name="setEvictMap" access="private" returntype="void" output="false">
	<cfargument name="evictMap" type="struct" required="true">
	<cfset instance.evictMap = arguments.evictMap />
</cffunction>

</cfcomponent>
