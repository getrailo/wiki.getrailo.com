<!--- Document Information -----------------------------------------------------

Title:      CacheConfigDAO.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Data Access Object for Java com.compoundtheory.objectcache.CacheConfig

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		15/05/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="CacheConfigDAO" hint="Data Access Object for Java com.compoundtheory.objectcache.CacheConfig">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="CacheConfigDAO" output="false">
	<cfargument name="javaLoader" hint="The Java loader for loading Java classes" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfargument name="configReader" hint="The XML Reader for the config file" type="transfer.com.io.XMLFileReader" required="Yes">
	<cfscript>
		setConfigReader(arguments.configReader);
		setJavaLoader(arguments.javaLoader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getCacheConfig" hint="Retruns the Java com.compoundtheory.objectcache.CacheManager object" access="public" returntype="any" output="false">
	<cfscript>
		var xPathDefault = "/transfer/objectCache/defaultcache/";
		var xPathCache = "/transfer/objectCache/cache/";
		var cacheConfig = 0;
		var xDefault = getConfigReader().search(xPathDefault);
		var xCache = getConfigReader().search(xPathCache);
		var config = 0;
		var defaultConfig = 0;
		var iterator = xCache.iterator();
		var xConfig = 0;

		if(ArrayLen(xDefault))
		{
			defaultConfig = createConfigFromXML(xDefault[1]);
		}
		else
		{
			defaultConfig = getJavaLoader().create("com.compoundtheory.objectcache.Config").init();
		}

		//set the default config
		cacheConfig = getJavaLoader().create("com.compoundtheory.objectcache.CacheConfig").init(defaultConfig);

		//now lets add all the other cache configs
		while(iterator.hasNext())
		{
			xConfig = iterator.next();
			config = createConfigFromXML(xConfig, defaultConfig);
			cacheConfig.addConfig(xConfig.xmlattributes.class, config);
		}

		return cacheConfig;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="createConfigFromXML" hint="Creates a com.compoundtheory.objectcache.Config from an xml element" access="private" returntype="any" output="false">
	<cfargument name="element" hint="The element to produce it from" type="XML" required="Yes">
	<cfargument name="defaultConfig" hint="The default config to pull default values from" required="No" default="#getJavaLoader().create('com.compoundtheory.objectcache.Config').init()#">
	<cfscript>
		//set default values
		var maxObjects = arguments.defaultConfig.getMaxObjects();
		var secondsPersisted = arguments.defaultConfig.getSecondsPersisted();
		var secondsAccessedTimeout = arguments.defaultConfig.getSecondsAccessedTimeout();
		var scope = arguments.defaultConfig.getScope();

		if(StructKeyExists(arguments.element, "maxobjects"))
		{
			maxObjects = arguments.element.maxobjects.xmlattributes.value;
		}

		if(StructKeyExists(arguments.element, "maxminutespersisted"))
		{
			secondsPersisted = arguments.element.maxminutespersisted.xmlattributes.value * 60;
		}

		if(StructKeyExists(arguments.element, "accessedminutestimeout"))
		{
			secondsAccessedTimeout = arguments.element.accessedminutestimeout.xmlattributes.value * 60;
		}

		if(StructKeyExists(arguments.element, "scope"))
		{
			scope = arguments.element.scope.xmlattributes.type;
		}

		return getJavaLoader().create("com.compoundtheory.objectcache.Config").init(JavaCast("int", maxObjects),
																					JavaCast("int", secondsPersisted),
																					JavaCast("int", secondsAccessedTimeout),
																					scope);
	</cfscript>
</cffunction>

<cffunction name="getJavaLoader" access="private" returntype="any" output="false">
	<cfreturn instance.JavaLoader />
</cffunction>

<cffunction name="setJavaLoader" access="private" returntype="void" output="false">
	<cfargument name="JavaLoader" type="any" required="true">
	<cfset instance.JavaLoader = arguments.JavaLoader />
</cffunction>

<cffunction name="getConfigReader" access="private" returntype="transfer.com.io.XMLFileReader" output="false">
	<cfreturn instance.ConfigReader />
</cffunction>

<cffunction name="setConfigReader" access="private" returntype="void" output="false">
	<cfargument name="ConfigReader" type="transfer.com.io.XMLFileReader" required="true">
	<cfset instance.ConfigReader = arguments.ConfigReader />
</cffunction>

</cfcomponent>