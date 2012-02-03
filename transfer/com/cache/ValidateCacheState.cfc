<!--- Document Information -----------------------------------------------------

Title:      ValidateCacheState.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose: 	Vaidates the state of the object, that all it's external compositions are cached

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		16/03/2007		Created

------------------------------------------------------------------------------->
<cfcomponent name="ValidateCacheState" hint="Vaidates the state of the object, that all it's external compositions are cached" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="ValidateCacheState" output="false">
	<cfargument name="objectManager" hint="The object manager" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="cacheManager" hint="The cache manager" type="transfer.com.cache.CacheManager" required="Yes" _autocreate="false">
	<cfargument name="methodInvoker" hint="The method invoker" type="transfer.com.dynamic.MethodInvoker" required="Yes" _autocreate="false">
	<cfscript>
		variables.instance = StructNew();

		setObjectManager(arguments.objectManager);
		setCacheManager(arguments.cacheManager);
		setMethodInvoker(arguments.methodInvoker);

		return this;
	</cfscript>
</cffunction>

<cffunction name="validateIsCached" hint="validates if a TransferObject is the same one as in cache" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to syncronise" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.transfer.getClassName());
		var key = getMethodInvoker().invokeMethod(arguments.transfer, "get" & object.getPrimaryKey().getName());
		var cachedObject = 0;
	</cfscript>

	<cfif getCacheManager().have(object.getClassName(), key)>
		<cftry>
			<cfset cachedObject = getCacheManager().get(object.getClassName(), key)>
			<cfif cachedObject.sameTransfer(arguments.transfer)>
				<cfreturn true />
			</cfif>
			<cfcatch type="java.lang.Exception">
				<cfswitch expression="#cfcatch.Type#">
					<!--- catch it if it gets removed along the way --->
					<cfcase value="com.compoundtheory.objectcache.ObjectNotFoundException">
						<cfreturn false>
					</cfcase>
					<cfdefaultcase>
						<cfrethrow>
					</cfdefaultcase>
				</cfswitch>
			</cfcatch>
		</cftry>
	</cfif>
	<cfreturn false>
</cffunction>
<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getMethodInvoker" access="private" returntype="transfer.com.dynamic.MethodInvoker" output="false">
	<cfreturn instance.MethodInvoker />
</cffunction>

<cffunction name="setMethodInvoker" access="private" returntype="void" output="false">
	<cfargument name="MethodInvoker" type="transfer.com.dynamic.MethodInvoker" required="true">
	<cfset instance.MethodInvoker = arguments.MethodInvoker />
</cffunction>

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

</cfcomponent>