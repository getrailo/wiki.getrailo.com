<!--- Document Information -----------------------------------------------------

Title:      SoftReferenceHandler.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    CF8 implementation of the soft reference handler that uses a async reap()

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		20/09/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="CF8 implementation of the soft reference handler that uses a async reap()" extends="transfer.com.cache.SoftReferenceHandler" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="SoftReferenceHandler" output="false">
	<cfargument name="cacheConfigManager" hint="The cache config manager" type="transfer.com.cache.CacheConfigManager" required="Yes" _autocreate="false">
	<cfargument name="facadeFactory" hint="The facade factpry for getting to the cache" type="transfer.com.facade.FacadeFactory" required="Yes" _autocreate="false">
	<cfscript>
		super.init(argumentCollection=arguments);

		instance.static.THREAD_TIMEOUT = "10"; //if the reap() hasn't run in 10 minutes, run it
		resetLastRunTime();
		setThreadCountLocal(createObject("java", "java.lang.ThreadLocal").init());
		setThread(createObject("java", "java.lang.Thread"));

		/*
			store the object id, as we use it to make sure that threads for this
			instance of the SRH are unique, as we may have more than one instance
			of Transfer per application scope.
		*/
		setObjectID(createObject("java", "java.lang.System").identityHashCode(this));

		return this;
	</cfscript>
</cffunction>

<cffunction name="reap" hint="this has been seperated out, so the cf8 version can do this async" access="public" returntype="void" output="false">
	<cfset var group = getThread().currentThread().getThreadGroup().getName() />

	<!--- if we're in onAppEnd, or onSessionEnd, ignore --->
	<cfif group eq "scheduler">
		<cfreturn />
	<!--- if we're inside a cfthread, run syncronously --->
	<cfelseif group eq "cfthread">
		<cfscript>
			/*
				Reap for no longer than 20 seconds, as otherwise, may take up too much
				processing.
			*/
			syncronousReap(20, true);
		</cfscript>
	<cfelse>
		<!---
		Let's not be so greedy about threads, let's just have one at a time, so we don't end up queueing stupidly.
		We have cfthread, so we don't need to do this as often.
		 --->
		<cfif DateDiff("n", getLastRunTime(), Now()) gt instance.static.THREAD_TIMEOUT>

			<cflock name="transfer.SoftReferenceHandler.reap" throwontimeout="true" timeout="60">

				<cfif DateDiff("n", getLastRunTime(), Now()) gt instance.static.THREAD_TIMEOUT>
					<cfset setLastRunTime(Now()) />
					<cfthread action="run" name="transfer.SoftReferenceHandler_#getObjectID()#_#getThreadCount()#" priority="low">
						<cfscript>
							var currentThread = getThread().currentThread();
							var priority = currentThread.getPriority();

							currentThread.setPriority(3); //lower priority

							syncronousReap(20, true);
							resetLastRunTime();

							currentThread.setPriority(priority);
						</cfscript>
					</cfthread>
				</cfif>
			</cflock>
		</cfif>
	</cfif>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getThreadCount" hint="returns the thread count" access="private" returntype="numeric" output="false">
	<cfscript>
		var local = StructNew();

		local.count = getThreadCountLocal().get();

		if(NOT StructKeyExists(local, "count"))
		{
			getThreadCountLocal().set(0);
		}
		else
		{
			getThreadCountLocal().set(local.count + 1);
		}

		return getThreadCountLocal().get();
	</cfscript>
</cffunction>

<cffunction name="getThreadCountLocal" access="private" returntype="any" output="false">
	<cfreturn instance.threadCountLocal />
</cffunction>

<cffunction name="setThreadCountLocal" access="private" returntype="void" output="false">
	<cfargument name="threadCountLocal" type="any" required="true">
	<cfset instance.threadCountLocal = arguments.threadCountLocal />
</cffunction>

<cffunction name="getLastRunTime" access="private" returntype="date" output="false">
	<cfreturn instance.lastRunTime />
</cffunction>

<cffunction name="setLastRunTime" access="private" returntype="void" output="false">
	<cfargument name="lastRunTime" type="date" required="true">
	<cfset instance.lastRunTime = arguments.lastRunTime />
</cffunction>

<cffunction name="resetLastRunTime" hint="resets the value of the last runtime" access="private" returntype="void" output="false">
	<cfscript>
		var resetAmount = -1 * (instance.static.THREAD_TIMEOUT + 1);
		//set it to the static value + 1
		setLastRuntime(DateAdd("n", resetAmount, Now()));
	</cfscript>
</cffunction>

<cffunction name="getThread" access="private" returntype="any" output="false">
	<cfreturn instance.Thread />
</cffunction>

<cffunction name="setThread" access="private" returntype="void" output="false">
	<cfargument name="Thread" type="any" required="true">
	<cfset instance.Thread = arguments.Thread />
</cffunction>

<cffunction name="getObjectID" access="private" returntype="string" output="false">
	<cfreturn instance.objectID />
</cffunction>

<cffunction name="setObjectID" access="private" returntype="void" output="false">
	<cfargument name="objectID" type="string" required="true">
	<cfset instance.objectID = arguments.objectID />
</cffunction>



</cfcomponent>