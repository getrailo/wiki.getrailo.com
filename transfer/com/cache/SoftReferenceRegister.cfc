<!--- Document Information -----------------------------------------------------

Title:      SoftReferenceRegister.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Manages Soft references, specifically for each facade type

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		16/07/2008		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Manages Soft references, specifically for each facade type" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="SoftReferenceRegister" output="false">
	<cfargument name="facade" hint="The facade this SoftReferenceRegister is connected to" type="transfer.com.facade.AbstractBaseFacade" required="Yes">
	<cfargument name="eventManager" type="transfer.com.events.EventManager" required="true">
	<cfargument name="cacheMonitor" hint="The cache monitor" type="transfer.com.cache.CacheMonitor" required="Yes">
	<cfscript>
		var Collections = createObject("java", "java.util.Collections");
		//instance scope please
		variables.instance = StructNew();

		setFacade(arguments.facade);
		setEventManager(arguments.eventManager);

		setReferenceQueue(createObject("java", "java.lang.ref.ReferenceQueue").init());

		//we need to use a Java collection, as we are using objects as keys
		setReferenceClassMap(Collections.synchronizedMap(createObject("java", "java.util.HashMap").init()));

		//use this to count the stack
		setStackCountLocal(createObject("java", "java.lang.ThreadLocal").init());

		setThread(createObject("java", "java.lang.Thread"));

		setCacheMonitor(arguments.cacheMonitor);

		return this;
	</cfscript>
</cffunction>

<cffunction name="register" hint="Registers a new TransferObject with the Handler, and returns a java.ref.softReference" access="public" returntype="any" output="false">
	<cfargument name="transfer" hint="The transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var softRef = createObject("java", "java.lang.ref.SoftReference").init(arguments.transfer, getReferenceQueue());

		getReferenceClassMap().put(softRef, arguments.transfer.getClassName());

		return softRef;
	</cfscript>
</cffunction>

<cffunction name="clearAllReferences" hint="clear and queue all the soft refrences stored in here" access="public" returntype="void" output="false">
	<cfscript>
		//use a clone to dodge concurrent modification exceptions
		var iterator = createObject("java", "java.util.HashSet").init(getReferenceClassMap().keySet()).iterator();
		var softRef = 0;

		//loop over all soft references
		while(iterator.hasNext())
		{
			softRef = iterator.next();
			softRef.clear();
			softRef.enqueue();
		}
	</cfscript>
</cffunction>

<cffunction name="reap" hint="this has been seperated out, so the cf8 version can do this async" access="public" returntype="void" output="false">
	<cfargument name="secondLimit" hint="The second limit on reaping, 0 is unlimited" type="numeric" required="Yes">
	<cfargument name="yieldOnLoop" hint="whether or not to yield() at end of every loop" type="boolean" required="No" default="false">
	<cfscript>
		var local = StructNew(); //we will use this, as is Defined seems to be causing heap issues
		var softRef = 0;
		var facade = getFacade(); //speed
		var cacheManager = 0;
		var class = 0;
		var startCount = getTickCount();
		var limit = secondLimit * 1000;

		local.softRef = getReferenceQueue().poll();

		/*
			if we've come here more than 5 times, dump it, and start again,
			the lower stacked syncronous reap calls will pick this up,
			and we won't get an overflow
		*/
		if(getStackCount() gte 2)
		{
			return;
		}

		while(StructKeyExists(local, "softRef"))
		{
			if(arguments.yieldOnLoop)
			{
				getThread().yield();
			}

			//remove resolution
			softRef = local.softRef;

			//reap on the caching layer
			if(facade.hasCacheManager())
			{
				cacheManager = facade.getCacheManager();

				class = JavaCast("string", getReferenceClassMap().get(softRef));

				cacheManager.reap(class, softRef);

				local.transferObject = cacheManager.popReapedCFC(softRef);
				if(StructKeyExists(local, "transferObject"))
				{
					getEventManager().fireAfterDiscardEvent(local.transferObject);
				}

				getCacheMonitor().evict(class);
			}

			getReferenceClassMap().remove(softRef);

			//reap on the observer layer
			if(facade.hasAfterCreateObserverCollection())
			{
				facade.getAfterCreateObserverCollection().removeObserverByKey(softRef);
			}

			if(facade.hasAfterUpdateObserverCollection())
			{
				facade.getAfterUpdateObserverCollection().removeObserverByKey(softRef);
			}

			if(facade.hasAfterDeleteObserverCollection())
			{
				facade.getAfterDeleteObserverCollection().removeObserverByKey(softRef);
			}

			if(facade.hasAfterDiscardObserverCollection())
			{
				facade.getAfterDiscardObserverCollection().removeObserverByKey(softRef);
			}

			if(limit neq 0 AND (getTickCount() - startCount) gt limit)
			{
				//break out
				StructClear(local);
				startCount = getTickCount();
			}
			else
			{
				local.softRef = getReferenceQueue().poll();
			}
		}

		resetStackCount();
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getStackCount" hint="returns the stack count" access="private" returntype="numeric" output="false">
	<cfscript>
		var local = StructNew();

		local.count = getStackCountLocal().get();

		if(NOT StructKeyExists(local, "count"))
		{
			resetStackCount();
		}
		else
		{
			getStackCountLocal().set(local.count + 1);
		}

		return getStackCountLocal().get();
	</cfscript>
</cffunction>

<cffunction name="resetStackCount" hint="resets the stack cout to 0" access="private" returntype="void" output="false">
	<cfset getStackCountLocal().set(0) />
</cffunction>

<cffunction name="getStackCountLocal" access="private" returntype="any" output="false">
	<cfreturn instance.StackCountLocal />
</cffunction>

<cffunction name="setStackCountLocal" access="private" returntype="void" output="false">
	<cfargument name="StackCountLocal" type="any" required="true">
	<cfset instance.StackCountLocal = arguments.StackCountLocal />
</cffunction>

<cffunction name="getThread" access="private" returntype="any" output="false">
	<cfreturn instance.Thread />
</cffunction>

<cffunction name="setThread" access="private" returntype="void" output="false">
	<cfargument name="Thread" type="any" required="true">
	<cfset instance.Thread = arguments.Thread />
</cffunction>

<cffunction name="getReferenceClassMap" access="private" returntype="struct" output="false">
	<cfreturn instance.ReferenceClassMap />
</cffunction>

<cffunction name="setReferenceClassMap" access="private" returntype="void" output="false">
	<cfargument name="ReferenceClassMap" type="struct" required="true">
	<cfset instance.ReferenceClassMap = arguments.ReferenceClassMap />
</cffunction>

<cffunction name="getFacade" access="private" returntype="transfer.com.facade.AbstractBaseFacade" output="false">
	<cfreturn instance.Facade />
</cffunction>

<cffunction name="setFacade" access="private" returntype="void" output="false">
	<cfargument name="Facade" type="transfer.com.facade.AbstractBaseFacade" required="true">
	<cfset instance.Facade = arguments.Facade />
</cffunction>

<cffunction name="getReferenceQueue" access="private" hint="java.lang.ref.ReferenceQueue" returntype="any" output="false">
	<cfreturn instance.ReferenceQueue />
</cffunction>

<cffunction name="setReferenceQueue" access="private" returntype="void" output="false">
	<cfargument name="ReferenceQueue" type="any" hint="java.lang.ref.ReferenceQueue" required="true">
	<cfset instance.ReferenceQueue = arguments.ReferenceQueue />
</cffunction>

<cffunction name="getEventManager" access="private" returntype="transfer.com.events.EventManager" output="false">
	<cfreturn instance.eventManager />
</cffunction>

<cffunction name="setEventManager" access="private" returntype="void" output="false">
	<cfargument name="eventManager" type="transfer.com.events.EventManager" required="true">
	<cfset instance.eventManager = arguments.eventManager />
</cffunction>

<cffunction name="getCacheMonitor" access="private" returntype="transfer.com.cache.CacheMonitor" output="false">
	<cfreturn instance.cacheMonitor />
</cffunction>

<cffunction name="setCacheMonitor" access="private" returntype="void" output="false">
	<cfargument name="cacheMonitor" type="transfer.com.cache.CacheMonitor" required="true">
	<cfset instance.cacheMonitor = arguments.cacheMonitor />
</cffunction>

</cfcomponent>