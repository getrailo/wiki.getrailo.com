<!--- Document Information -----------------------------------------------------

Title:      CacheSynchronise.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Synchronised data between cached and non cached objects

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		06/09/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="CacheSynchronise" hint="Synchronised data between cached and non cached objects">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="CacheSynchronise" output="false">
	<cfargument name="objectManager" hint="The object manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfargument name="cacheManager" hint="The cache manager" type="transfer.com.cache.CacheManager" required="Yes">
	<cfargument name="methodInvoker" hint="The method invoker" type="transfer.com.dynamic.MethodInvoker" required="Yes">
	<cfscript>
		setObjectManager(arguments.objectManager);
		setCacheManager(arguments.cacheManager);
		setMethodInvoker(arguments.methodInvoker);

		return this;
	</cfscript>
</cffunction>

<cffunction name="synchronise" hint="syncronises the data, and returns the cached TransferObject if there is one, otherwise returns the original TransferObject" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="transfer" hint="The transfer object to syncronise" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.transfer.getClassName());
		var key = getMethodInvoker().invokeMethod(arguments.transfer, "get" & object.getPrimaryKey().getName());
		var System = createObject("java", "java.lang.System");
		var cachedObject = 0;
	</cfscript>
	<cfif getCacheManager().have(object.getClassName(), key)>
		<cftry>

			<cfset cachedObject = getCacheManager().get(object.getClassName(), key)>

			<!--- This needs to be locked, so we don't get overwritten syncronisations --->
			<cfif NOT cachedObject.sameTransfer(arguments.transfer)>
				<cflock name="transfer.synchronise.#cachedObject.getClassName()#.#System.identityHashCode(cachedObject)#" timeout="60">
					<cfscript>
						arguments.transfer.copyValuesTo(cachedObject);

						return cachedObject;
					</cfscript>
				</cflock>
			</cfif>

			<cfcatch type="java.lang.Exception">
				<cfswitch expression="#cfcatch.Type#">
					<!--- catch it if it gets removed along the way --->
					<cfcase value="com.compoundtheory.objectcache.ObjectNotFoundException">
						<cfreturn arguments.transfer>
					</cfcase>
					<cfdefaultcase>
						<cfrethrow>
					</cfdefaultcase>
				</cfswitch>
			</cfcatch>
		</cftry>
	</cfif>

	<cfreturn arguments.transfer>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getCacheManager" access="private" returntype="transfer.com.cache.CacheManager" output="false">
	<cfreturn instance.CacheManager />
</cffunction>

<cffunction name="setCacheManager" access="private" returntype="void" output="false">
	<cfargument name="CacheManager" type="transfer.com.cache.CacheManager" required="true">
	<cfset instance.CacheManager = arguments.CacheManager />
</cffunction>

<cffunction name="getMethodInvoker" access="private" returntype="transfer.com.dynamic.MethodInvoker" output="false">
	<cfreturn instance.MethodInvoker />
</cffunction>

<cffunction name="setMethodInvoker" access="private" returntype="void" output="false">
	<cfargument name="MethodInvoker" type="transfer.com.dynamic.MethodInvoker" required="true">
	<cfset instance.MethodInvoker = arguments.MethodInvoker />
</cffunction>

</cfcomponent>