<!--- Document Information -----------------------------------------------------

Title:      SoftReferenceHandler.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    A place to manage all the soft references in the system

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		20/02/2007		Created

------------------------------------------------------------------------------->

<cfcomponent name="SoftReferenceHandler" hint="Handles Soft References in Transfer" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="SoftReferenceHandler" output="false">
	<cfargument name="cacheConfigManager" hint="The cache config manager" type="transfer.com.cache.CacheConfigManager" required="Yes" _autocreate="false">
	<cfargument name="facadeFactory" hint="The facade factpry for getting to the cache" type="transfer.com.facade.FacadeFactory" required="Yes" _autocreate="false">
	<cfscript>
		variables.instance = StructNew();

		setFacadeFactory(arguments.facadeFactory);
		setCacheConfigManager(arguments.cacheConfigManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="register" hint="Registers a new TransferObject with the Handler, and returns a java.ref.softReference" access="public" returntype="any" output="false">
	<cfargument name="transfer" hint="The transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var scope = getCacheConfigManager().getCacheConfig().getConfig(arguments.transfer.getClassName()).getScope();
		var facade = getFacadeFactory().getFacadeByScope(scope);

		return facade.getSoftReferenceRegister().register(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="clearAllReferences" hint="clear and queue all the soft refrences stored in here" access="public" returntype="void" output="false">
	<cfscript>
		eachSoftReferenceRegister(executeClearAllReferences);
	</cfscript>
</cffunction>

<cffunction name="reap" hint="this has been seperated out, so the cf8 version can do this async" access="public" returntype="void" output="false">
	<cfscript>
		syncronousReap(5);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="syncronousReap" hint="syncronous Reap: reaps the collected objects out of the pool" access="private" returntype="void" output="false">
	<cfargument name="secondLimit" hint="The second limit on reaping, 0 is unlimited" type="numeric" required="No" default="0">
	<cfscript>
		eachSoftReferenceRegister(executeReap, arguments);
	</cfscript>
</cffunction>

<cffunction name="eachSoftReferenceRegister" hint="HOF that runs a function against each facade's ConfigManager, if it has one" access="private" returntype="void" output="false">
	<cfargument name="function" hint="the function to call on the SoftReferenceRegister" type="any" required="Yes">
	<cfargument name="args" hint="the argument data to pass from function call to function call" type="struct" required="false" default="#StructNew()#">
	<cfscript>
		var factory = getFacadeFactory(); //speed

		invokeFacadeSoftReferenceRegister(factory.getInstanceFacade(), arguments.function, arguments.args);
		invokeFacadeSoftReferenceRegister(factory.getApplicationFacade(), arguments.function, arguments.args);

		try
		{
			//we do this, as the request scope variables can just dissapear
			invokeFacadeSoftReferenceRegister(factory.getRequestFacade(), arguments.function, arguments.args);
		}
		catch(coldfusion.runtime.UndefinedElementException exc)	{ /*do nothing*/ }

		invokeFacadeSoftReferenceRegister(factory.getServerFacade(), arguments.function, arguments.args);

		try
		{
			//we do this, as the session scope variables can just dissapear
			invokeFacadeSoftReferenceRegister(factory.getSessionFacade(), arguments.function, arguments.args);
		}
		catch(coldfusion.runtime.UndefinedElementException exc) { /*do nothing*/ }

		//really not required, but to keep clean
		invokeFacadeSoftReferenceRegister(factory.getNoneFacade(), arguments.function, arguments.args);
	</cfscript>
</cffunction>

<cffunction name="invokeFacadeSoftReferenceRegister" hint="invokes the function against the soft reference register if the facade has one" access="private" returntype="void" output="false">
	<cfargument name="facade" hint="the facade to call against" type="transfer.com.facade.AbstractBaseFacade" required="Yes">
	<cfargument name="function" hint="the function to call on the SoftReferenceRegister" type="any" required="Yes">
	<cfargument name="args" hint="the argument data to pass from function call to function call" type="struct" required="true">
	<cfscript>
		var call = arguments.function;

		if(facade.hasSoftReferenceRegister())
		{
			arguments.args.softReferenceRegister = facade.getSoftReferenceRegister();
			call(argumentCollection=arguments.args);
		}
	</cfscript>
</cffunction>

<!--- HOF function arguments --->

<cffunction name="executeClearAllReferences" hint="calls 'clearAllReference' on each of the facades" access="private" returntype="void" output="false">
	<cfargument name="softReferenceRegister" hint="the soft reference register to call on" type="transfer.com.cache.SoftReferenceRegister" required="Yes">
	<cfscript>
		arguments.softReferenceRegister.clearAllReferences();
	</cfscript>
</cffunction>

<cffunction name="executeReap" hint="executes the reap action on each of the facades" access="private" returntype="void" output="false">
	<cfargument name="softReferenceRegister" hint="the soft reference register to call on" type="transfer.com.cache.SoftReferenceRegister" required="Yes">
	<cfargument name="secondLimit" hint="The second limit on reaping, 0 is unlimited" type="numeric" required="Yes">
	<cfscript>
		arguments.softReferenceRegister.reap(argumentCollection=arguments);
	</cfscript>
</cffunction>

<!--- /HOF function arguments --->


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

</cfcomponent>