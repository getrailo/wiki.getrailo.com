<!--- Document Information -----------------------------------------------------

Title:      ObjectManager.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Manages the Object configurations

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		13/07/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="ObjectManager" hint="Manages the Object configurations">

<cfscript>
	instance = StructNew();

	//constants
	static = Structnew();
	static.LINKS_BY_CLASS_QUERY_KEY = "linksByClass";
	static.ONE_TO_MANY_LINKS_TO_QUERY_KEY = "onetomanyLinkTo";
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="ObjectManager" output="false">
	<cfargument name="configReader" hint="The XML Reader for the config file" type="transfer.com.io.XMLFileReader" required="Yes" _autocreate="false">

	<cfscript>
		setObjectDAO(createObject("component", "transfer.com.object.ObjectDAO").init(arguments.configReader));

		//use a hashmap, as its case sensitive
		setObjectCache(createObject("java", "java.util.Collections").synchronizedMap(createObject("java", "java.util.HashMap").init()));

		setObjectGateway(createObject("component", "transfer.com.object.ObjectGateway").init(arguments.configReader));
		setQueryCache(createObject("component", "transfer.com.collections.QueryCache").init());

		return this;
	</cfscript>
</cffunction>

<cffunction name="getObject" hint="creates an Object meta data for use" access="public" returntype="Object" output="false">
	<cfargument name="class" hint="The class to be retrieving" type="string" required="Yes">

	<cfscript>
		var object = 0;
		var cache = getObjectCache();
	</cfscript>

	<cfif NOT StructKeyExists(cache, arguments.class)>
		<cflock name="transfer.ObjectManager.getObject.#arguments.class#" timeout="60" throwontimeout="true">
			<cfscript>
				//get the defintion
				if(NOT StructKeyExists(cache, arguments.class))
				{
					object = getObjectDAO().getObject(createEmptyObject(), arguments.class);

					cache[arguments.class] = object;

					//run the notify, so we do the post processing here
					object.notifyComplete();

					//add it after the cache, so that if it refers to itself, it can find itself in the cache.
					object.validate();
				}
			</cfscript>
		</cflock>
	</cfif>

	<!---
		Lock is here so that notify() finishes before a thread can get a compelted obejct.
		Also has some weird performance improvements?
	 --->
	<cflock name="transfer.ObjectManager.getObject.#arguments.class#" timeout="60" throwontimeout="true" type="readonly">
		<cfscript>
			return StructFind(cache, arguments.class);
		</cfscript>
	</cflock>
</cffunction>

<cffunction name="getObjectLazyManyToOne" hint="creates an Object with only a single many to one, with it's lazy attribute set to true" access="public" returntype="Object" output="false">
	<cfargument name="class" hint="The class to be retrieving" type="string" required="Yes">
	<cfargument name="name" hint="The name of the many to one" type="string" required="Yes">
	<cfscript>
		var object = 0;
		var key = arguments.class & "|" & arguments.name & "|LazyManyToOne";
		var manytoone = 0;
		var cache = getObjectCache();
	</cfscript>

	<cfif NOT StructKeyExists(cache, key)>
		<cflock name="transfer.ObjectManager.getObjectLazyManyToOne.#key#" timeout="60" throwontimeout="true">
			<cfscript>
				//get the defintion
				if(NOT StructKeyExists(cache, key))
				{
					//new object
					object = getObjectDAO().getObject(createEmptyObject(), arguments.class);

					//let's massage it so that it represents an object with the item we want.
					manytoone = object.getManyToOneByName(arguments.name);

					manytoone.setIsLazy(false);

					object.clearManyToOne();
					object.clearManyToMany();
					object.clearOneToMany();

					object.addManyToOne(manytoone);

					cache[key] = object;
				}
			</cfscript>
		</cflock>
	</cfif>

	<cfscript>
		return cache[key];
	</cfscript>
</cffunction>

<cffunction name="getObjectLazyOneToMany" hint="creates an Object with only a single onetomany, with it's lazy attribute set to true" access="public" returntype="Object" output="false">
	<cfargument name="class" hint="The class to be retrieving" type="string" required="Yes">
	<cfargument name="name" hint="The name of the onetomany" type="string" required="Yes">
	<cfscript>
		var object = 0;
		var key = arguments.class & "|" & arguments.name & "|LazyOneToMany";
		var onetomany = 0;
		var cache = getObjectCache();
	</cfscript>

	<cfif NOT StructKeyExists(cache, key)>
		<cflock name="transfer.ObjectManager.getObjectLazyOneToMany.#key#" timeout="60" throwontimeout="true">
			<cfscript>
				//get the defintion
				if(NOT StructKeyExists(cache, key))
				{
					//new object
					object = getObjectDAO().getObject(createEmptyObject(), arguments.class);

					//let's massage it so that it represents an object with the item we want.
					onetomany = object.getOneToManyByName(arguments.name);

					onetomany.setIsLazy(false);

					object.clearManyToOne();
					object.clearManyToMany();
					object.clearOneToMany();

					object.addOneToMany(onetomany);

					cache[key] = object;
				}
			</cfscript>
		</cflock>
	</cfif>

	<cfscript>
		return cache[key];
	</cfscript>
</cffunction>

<cffunction name="getObjectLazyManyToMany" hint="creates an Object with only a single manytomany, with it's lazy attribute set to true" access="public" returntype="Object" output="false">
	<cfargument name="class" hint="The class to be retrieving" type="string" required="Yes">
	<cfargument name="name" hint="The name of the manytomany" type="string" required="Yes">
	<cfscript>
		var object = 0;
		var key = arguments.class & "|" & arguments.name & "|LazyManyToMany";
		var manytomany = 0;
		var cache = getObjectCache();
	</cfscript>

	<cfif NOT StructKeyExists(cache, key)>
		<cflock name="transfer.ObjectManager.getObjectLazyOneToMany.#key#" timeout="60" throwontimeout="true">
			<cfscript>
				//get the defintion
				if(NOT StructKeyExists(cache, key))
				{
					//new object
					object = getObjectDAO().getObject(createEmptyObject(), arguments.class);

					//let's massage it so that it represents an object with the item we want.
					manytomany = object.getManyToManyByName(arguments.name);

					manytomany.setIsLazy(false);

					object.clearManyToOne();
					object.clearManyToMany();
					object.clearOneToMany();

					object.addManyToMany(manytomany);

					cache[key] = object;
				}
			</cfscript>
		</cflock>
	</cfif>

	<cfscript>
		return cache[key];
	</cfscript>
</cffunction>

<cffunction name="getObjectLazyParentOneToMany" hint="creates an Object with no compositions" access="public" returntype="transfer.com.object.Object" output="false">
	<cfargument name="class" hint="The class to be retrieving" type="string" required="Yes">
	<cfscript>
		var object = 0;
		var key = arguments.class & "|LazyParentOneToMany";
		var manytomany = 0;
		var cache = getObjectCache();
	</cfscript>

	<cfif NOT StructKeyExists(cache, key)>
		<cflock name="transfer.ObjectManager.getObjectLazyParentOneToMany.#key#" timeout="60" throwontimeout="true">
			<cfscript>
				//get the defintion
				if(NOT StructKeyExists(cache, key))
				{
					//new object
					object = getObjectDAO().getObject(createEmptyObject(), arguments.class);

					//let's massage it so that it represents an object with the item we want.
					object.clearManyToOne();
					object.clearManyToMany();
					object.clearOneToMany();

					cache[key] = object;
				}
			</cfscript>
		</cflock>
	</cfif>

	<cfscript>
		return cache[key];
	</cfscript>
</cffunction>

<cffunction name="getManyToManyLinksByClassLinkTo" hint="Gets a query of Many to Many details by the class it is linked to" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The classname to search on" type="string" required="Yes">
	<cfscript>
		var key = static.LINKS_BY_CLASS_QUERY_KEY & "|" & arguments.className;
	</cfscript>

	<cfif not getQueryCache().checkQuery(key)>
		<cflock name="transfer.ObjectManager.getManyToManyLinksByClassLinkTo.#arguments.className#" timeout="60" throwontimeout="true">
			<cfscript>
				if(not getQueryCache().checkQuery(key))
				{
					getQueryCache().cacheQuery(getObjectGateway().getManyToManyLinksByClassLinkTo(arguments.className), key);
				}
			</cfscript>
		</cflock>
	</cfif>

	<cfscript>
		return getQueryCache().getQuery(key);
	</cfscript>
</cffunction>

<cffunction name="getCachedClassCount" hint="returns the number of object classes who are actively cached" access="public" returntype="numeric" output="false">
	<cfscript>
		var total = getObjectGateway().getObjectCount();
		var none = getObjectGateway().getCacheScopeCount("none");

		return total - none;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="createEmptyObject" hint="Creates an empty Object BO" access="public" returntype="Object" output="false">
	<cfreturn createObject("component", "transfer.com.object.Object").init(this)>
</cffunction>

<cffunction name="getObjectDao" access="private" returntype="ObjectDAO" output="false">
	<cfreturn instance.ObjectDao />
</cffunction>

<cffunction name="setObjectDao" access="private" returntype="void" output="false">
	<cfargument name="ObjectDao" type="ObjectDAO" required="true">
	<cfset instance.ObjectDao = arguments.ObjectDao />
</cffunction>

<cffunction name="getObjectCache" access="private" returntype="struct" output="false">
	<cfreturn instance.objectCache />
</cffunction>

<cffunction name="setObjectCache" access="private" returntype="void" output="false">
	<cfargument name="objectCache" type="struct" required="true">
	<cfset instance.objectCache = arguments.objectCache />
</cffunction>

<cffunction name="getObjectGateway" access="private" returntype="ObjectGateway" output="false">
	<cfreturn instance.ObjectGateway />
</cffunction>

<cffunction name="setObjectGateway" access="private" returntype="void" output="false">
	<cfargument name="ObjectGateway" type="ObjectGateway" required="true">
	<cfset instance.ObjectGateway = arguments.ObjectGateway />
</cffunction>

<cffunction name="getQueryCache" access="private" returntype="transfer.com.collections.QueryCache" output="false">
	<cfreturn instance.QueryCache />
</cffunction>

<cffunction name="setQueryCache" access="private" returntype="void" output="false">
	<cfargument name="QueryCache" type="transfer.com.collections.QueryCache" required="true">
	<cfset instance.QueryCache = arguments.QueryCache />
</cffunction>

</cfcomponent>