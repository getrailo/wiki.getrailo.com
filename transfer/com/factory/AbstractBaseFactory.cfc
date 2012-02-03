<!--- Document Information -----------------------------------------------------

Title:      AbstractBaseFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Abstract base for all factories

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/09/2007		Created

------------------------------------------------------------------------------->
<cfcomponent hint="the abstract base for all factories" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="setSingleton" hint="adds a singleton to the factory, for lookup purposes" access="public" returntype="void" output="false">
	<cfargument name="object" hint="the object to add" type="any" required="Yes">
	<cfargument name="class" hint="the name of the class" type="string" required="No">
	<cfscript>
		if(NOT structKeyExists(arguments, "class"))
		{
			arguments.class = getMetaData(arguments.object).name;
		}

		StructInsert(getSingletonCache(), arguments.class, arguments.object);
	</cfscript>
</cffunction>

<cffunction name="setPropertyValue" hint="sets a property value for use in autowiring" access="public" returntype="void" output="false">
	<cfargument name="name" hint="the name of the property value to match to" type="string" required="Yes">
	<cfargument name="value" hint="the value use" type="string" required="Yes">
	<cfscript>
		StructInsert(getPropertyValueCache(), arguments.name, arguments.value);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="init" hint="Constructor" access="private" returntype="void" output="false">
	<cfscript>
		var invoker = createObject("component", "transfer.com.dynamic.MethodInvoker").init();

		variables.instance = StructNew();

		setSingletonCache(StructNew());
		setPropertyValueCache(StructNew());

		setSingleton(invoker);
	</cfscript>
</cffunction>

<cffunction name="getSingleton" hint="creates and keeps a singleton" access="private" returntype="any" output="false">
	<cfargument name="class" hint="the class name" type="string" required="Yes">
	<cfscript>
		var object = 0;
	</cfscript>
	<cfif NOT hasSingleton(arguments.class)>
		<cflock name="transfer.Factory.#arguments.class#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT hasSingleton(arguments.class))
			{
				object = autowire(createObject("component", arguments.class));

				setSingleton(object, class);

				return object;
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn StructFind(getSingletonCache(), arguments.class) />
</cffunction>

<cffunction name="autowire" hint="autowires a bean by class name" access="private" returntype="any" output="false">
	<cfargument name="object" hint="the object to autowire" type="any" required="Yes">
	<cfscript>
		var meta = getMetaData(arguments.object.init);
		var args = StructNew();
		var counter = 1;
		var len = ArrayLen(meta.parameters);
		var arg = 0;
		var param = 0;

		try
		{
			for(; counter lte len; counter = counter + 1)
			{
				param = meta.parameters[counter];

				if(param.type eq "string")
				{
					//property values are mapped by name
					arg = getPropertyValue(param.name);
				}
				else
				{
					if(NOT StructKeyExists(param, "_autocreate"))
					{
						param._autocreate = true;
					}

					if(StructKeyExists(param, "_factoryMethod"))
					{
						if(StructKeyExists(param, "_factory"))
						{
							arg = getObjectFromFactory(param._factory, param._factoryMethod, param._autocreate);
						}
						else
						{
							arg = getMethodInvoker().invokeMethod(this, param._factoryMethod);
						}
					}
					else if(param._autocreate) //you may be able to auto create
					{
						//objects are mapped by class
						arg = getSingleton(param.type);
					}
					else
					{
						arg = getSingletonFromCache(param.type);
					}
				}

				args[param.name] = arg;
			}

			return getMethodInvoker().invokeMethod(arguments.object, "init", args);
		}
		catch(any exc)
		{
			throw("transfer.factory.AutoWireException", "Error while attempting to autowire object of type #getMetaData(arguments.object).name#", "<br/>[Line: #exc.tagContext[1].line# :: #exc.tagContext[1].template# :: #exc.message# :: #exc.detail#]");
		}
	</cfscript>
</cffunction>

<cffunction name="getObjectFromFactory" hint="gets an object from a factory" access="private" returntype="any" output="false">
	<cfargument name="factoryClass" hint="the name of the factory" type="string" required="Yes">
	<cfargument name="factorymethod" hint="the name of the method to get the result from" type="string" required="Yes">
	<cfargument name="autocreate" hint="whether or not to auto create the factory" type="boolean" required="No" default="true">
	<cfscript>
		var factory = 0;

		if(arguments.autocreate)
		{
			factory = getSingleton(arguments.factoryClass);
		}
		else
		{
			factory = getSingletonFromCache(arguments.factoryClass);
		}

		return getMethodInvoker().invokeMethod(factory, arguments.factoryMethod);
	</cfscript>
</cffunction>

<cffunction name="getSingletonFromCache" hint="returns the singleton from the cache" access="private" returntype="any" output="false">
	<cfargument name="class" hint="the class of the singleton to retrieve" type="string" required="Yes">
	<cfscript>
		return StructFind(getSingletonCache(), arguments.class);
	</cfscript>
</cffunction>

<cffunction name="hasSingleton" hint="whether or not it hsa it in cache" access="private" returntype="boolean" output="false">
	<cfargument name="class" hint="the class name" type="string" required="Yes">
	<cfreturn StructKeyExists(getSingletonCache(), arguments.class) />
</cffunction>

<cffunction name="getPropertyValue" hint="returns a property value" access="private" returntype="string" output="false">
	<cfargument name="name" hint="the name of the property" type="string" required="Yes">
	<cfreturn StructFind(getPropertyValueCache(), arguments.name) />
</cffunction>

<cffunction name="getSingletonCache" access="private" returntype="struct" output="false">
	<cfreturn instance.SingletonCache />
</cffunction>

<cffunction name="setSingletonCache" access="private" returntype="void" output="false">
	<cfargument name="SingletonCache" type="struct" required="true">
	<cfset instance.SingletonCache = arguments.SingletonCache />
</cffunction>

<cffunction name="getPropertyValueCache" access="private" returntype="struct" output="false">
	<cfreturn instance.PropertyValueCache />
</cffunction>

<cffunction name="setPropertyValueCache" access="private" returntype="void" output="false">
	<cfargument name="PropertyValueCache" type="struct" required="true">
	<cfset instance.PropertyValueCache = arguments.PropertyValueCache />
</cffunction>

<cffunction name="getMethodInvoker" hint="returns a method invoker" access="public" returntype="transfer.com.dynamic.MethodInvoker" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.MethodInvoker") />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>