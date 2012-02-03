<!--- Document Information -----------------------------------------------------

Title:      DecoratorBuilder.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Builds the decorators

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		11/08/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="DecoratorBuilder" hint="Builds the decorators">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="DecoratorBuilder" output="false">
	<cfargument name="definitionPath" hint="Path to where the definitions are kept" type="string" required="Yes">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfscript>
		setDefinitionPath(arguments.definitionPath);
		setMethodInjector(arguments.methodInjector);
		setDecoratorWriter(createObject("component", "transfer.com.dynamic.DecoratorWriter").init(expandPath(getDefinitionPath()), arguments.objectManager));
		setObjectManager(arguments.objectManager);

		//setup mixin functions
		instance.mixin = StructNew();
		instance.mixin.buildDecorator = variables.buildDecorator;

		getMethodInjector().start(this);
		//remove it
		getMethodInjector().removeMethod(this, "buildDecorator");
		getMethodInjector().stop(this);

		return this;
	</cfscript>
</cffunction>

<cffunction name="createDecorator" hint="creates an empty Transfer Object" access="public" returntype="transfer.com.TransferDecorator" output="false">
	<cfargument name="object" hint="The object def, as the transfer won't know it's class yet" type="transfer.com.object.Object" required="Yes">
	<cfargument name="transfer" hint="The transferObject" type="transfer.com.TransferObject" required="Yes">

	<cfscript>
		//create the decorator class
		var decorator = createObject("component", arguments.object.getDecorator());
		var injector = getMethodInjector();
	</cfscript>

	<!--- let's double lock this down, so we don't get two people trying to write files at the same time --->
	<cfif NOT getDecoratorWriter().hasDefinition(arguments.object)>
		<cflock name="transfer.createDecorator.#arguments.object.getClassName()#" throwontimeout="yes" timeout="60">
		<cfscript>
			//make sure the defintion file has been written
			if(NOT getDecoratorWriter().hasDefinition(arguments.object))
			{
				//if not, write it
				getDecoratorWriter().writeDefinition(arguments.object, arguments.transfer);
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfscript>
		//build the object
		injector.start(decorator);

		injector.injectMethod(decorator, instance.mixin.buildDecorator);

		decorator.buildDecorator(injector, getDefinitionPath() & getDecoratorWriter().getDefinitionFileName(object));

		injector.stop(decorator);

		return decorator;
	</cfscript>
</cffunction>

<!--- mixin function --->
<cffunction name="buildDecorator" hint="mixin function: Builds the decorator structure" access="public" returntype="void" output="false">
	<cfargument name="methodInjector" hint="The method injector" type="methodInjector" required="Yes">
	<cfargument name="decoratorFileName" hint="The name the decorator file is" type="string" required="Yes">
	<cfscript>
		//where to place variables UDFs
		var varScope = StructNew();
		var item = 0;
		var key = 0;

		//move methods out of variables scope into my varScope

		for(key in variables)
		{
			item = variables[key];
			if(isCustomFunction(item))
			{
				varScope[key] = variables[key];
				arguments.methodInjector.removeMethod(this, key);
			}
		}
	</cfscript>

	<!--- include the file --->
	<cftry>
		<cfinclude template="#arguments.decoratorFileName#">
		<cfcatch type="any">
			<cfthrow type="transfer.#cfcatch.type#" message="Error found in: #arguments.decoratorFileName#" detail="#cfcatch.message# : #cfcatch.detail#">
		</cfcatch>
	</cftry>

	<cfscript>
		/*
			let's get really lazy, because otherwise this going to get really complicated.
			loops around variables scope, if it's a UDF, inject it, if it's not
			leave it alone.
		*/

		for(key in variables)
		{
			item = variables[key];
			if(isCustomFunction(item))
			{
				if(StructKeyExists(varScope, key))
				{
					arguments.methodInjector.removeMethod(this, key);
				}
				else
				{
					arguments.methodInjector.injectMethod(this, item);
				}
			}
		}

		/*
			now we overwrite those methods with our own
			ones.
		*/
		for(key in varScope)
		{
			arguments.methodInjector.injectMethod(this, varScope[key]);
		}

		//remove myself
		arguments.methodInjector.removeMethod(this, "buildDecorator");
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getDefinitionPath" access="private" returntype="string" output="false">
	<cfreturn instance.DefinitionPath />
</cffunction>

<cffunction name="setDefinitionPath" access="private" returntype="void" output="false">
	<cfargument name="DefinitionPath" type="string" required="true">
	<cfset instance.DefinitionPath = arguments.DefinitionPath />
</cffunction>

<cffunction name="getMethodInjector" access="private" returntype="MethodInjector" output="false">
	<cfreturn instance.MethodInjector />
</cffunction>

<cffunction name="setMethodInjector" access="private" returntype="void" output="false">
	<cfargument name="MethodInjector" type="MethodInjector" required="true">
	<cfset instance.MethodInjector = arguments.MethodInjector />
</cffunction>

<cffunction name="getDecoratorWriter" access="private" returntype="DecoratorWriter" output="false">
	<cfreturn instance.DecoratorWriter />
</cffunction>

<cffunction name="setDecoratorWriter" access="private" returntype="void" output="false">
	<cfargument name="DecoratorWriter" type="DecoratorWriter" required="true">
	<cfset instance.DecoratorWriter = arguments.DecoratorWriter />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

</cfcomponent>