<!--- Document Information -----------------------------------------------------

Title:      AOPAdvisor.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    This does the heavy lifting for getting the advice around the methods

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		20/02/2008		Created

------------------------------------------------------------------------------->
<cfcomponent hint="This does the heavy lifting for getting the advice around the methods" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="AOPAdvisor" output="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfargument name="definitionPath" hint="Path to where the definitions are kept" type="string" required="Yes">
	<cfscript>
		variables.instance = StructNew();

		instance.static.AOP_KEY = "34F87242-94F5-0FD5-39C2185B9E0CEBE8"; //this gives us a unique place to put original methods

		instance.mixins = StructNew();
		instance.mixins.__weave = variables.__weave;
		instance.mixins.__findPointCuts = variables.__findPointCuts;

		setMethodInjector(arguments.methodInjector);
		setDefinitionPath(arguments.definitionPath);

		getMethodInjector().start(this);
		getMethodInjector().removeMethod(this, "__weave");
		getMethodInjector().removeMethod(this, "__findPointCuts");
		getMethodInjector().stop(this);

		return this;
	</cfscript>
</cffunction>

<cffunction name="advise" hint="wrap some advice around a method" access="public" returntype="void" output="false">
	<cfargument name="component" hint="the component to apply the advice to" type="any" required="Yes">
	<cfargument name="pointcut" hint="either a function, or a regex for functions to advise" type="any" required="Yes">
	<cfargument name="adviceBuilder" hint="the advice builder" type="transfer.com.aop.AbstractBaseAdviceBuilder" required="Yes">
	<cfargument name="debug" hint="when true, cftrace's the method names that gets adviced" type="boolean" required="No" default="false">
	<cfscript>
		var pointCutArray = 0;
		var counter = 1;
		var len = 0;

		getMethodInjector().start(arguments.component);

		//not too fussed with the threading, as if it doesn't exist, it can get added more than once
		if(NOT StructKeyExists(arguments.component, "__weave"))
		{
			getMethodInjector().injectMethod(arguments.component, instance.mixins.__weave);
		}

		if(isCustomFunction(arguments.pointcut))
		{
			weaveAdvice(arguments.component, arguments.pointcut, arguments.adviceBuilder, arguments.debug);
		}
		else if(isSimpleValue(arguments.pointcut))
		{
			pointCutArray = findPointCuts(arguments.component, arguments.pointCut);

			len = ArrayLen(pointCutArray);
			for(; counter lte len; counter = counter + 1)
			{
				weaveAdvice(arguments.component, pointCutArray[counter], arguments.adviceBuilder, arguments.debug);
			}
		}

		getMethodInjector().stop(arguments.component);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="weaveAdvice" hint="weaves the advice into the component's method" access="private" returntype="void" output="false">
	<cfargument name="component" hint="the component to apply the advice to" type="any" required="Yes">
	<cfargument name="pointcut" hint="the function to write" type="any" required="Yes">
	<cfargument name="adviceBuilder" hint="the advice builder" type="transfer.com.aop.AbstractBaseAdviceBuilder" required="Yes">
	<cfargument name="debug" hint="when true, cftrace's the method names that gets adviced" type="boolean" required="No" default="false">
	<cfscript>
		var buffer = createObject("component", "transfer.com.dynamic.definition.DefinitionBuffer").init();
		var meta = getMetaData(arguments.pointcut);
		var fileName = getMetaData(arguments.component).name & "." & meta.name & ".aop.transfer";
		var fileWriter = createObject("component", "transfer.com.io.FileWriter").init(expandPath(getDefinitionPath()) & fileName);

		buffer.writeCopyOpenFunction(arguments.pointcut, "Advice for AOP intercepted method");

		buffer.cfscript(true);
		buffer.writeLine('var joinPointName = "#meta.name#_#instance.static.AOP_KEY#";');
		buffer.cfscript(false);

		arguments.adviceBuilder.buildAdvice(arguments.component, arguments.pointcut, buffer);

		buffer.writeCFFunctionClose();

		fileWriter.write(buffer.toDefintionString());

		arguments.component.__weave(getMethodInjector(), meta.name, getDefinitionPath() & fileName, instance.static.AOP_KEY);

		fileWriter.delete();
	</cfscript>
	<cfif arguments.debug>
		<cftrace text="Weaving #arguments.adviceBuilder.getAdviceName()# advice on #getMetaData(arguments.component).name#::#meta.name#()">
	</cfif>
</cffunction>

<cffunction name="findPointCuts" hint="builds a array of methods from a poincut regex" access="private" returntype="array" output="false">
	<cfargument name="component" hint="the component to apply the advice to" type="any" required="Yes">
	<cfargument name="pointcut" hint="a regex for functions to advise" type="string" required="Yes">Z
	<cfscript>
		if(NOT StructKeyExists(arguments.component, "__findPointCuts"))
		{
			getMethodInjector().injectMethod(arguments.component, instance.mixins.__findPointCuts);
		}

		return arguments.component.__findPointCuts(arguments.pointcut);
	</cfscript>
</cffunction>

<cffunction name="getMethodInjector" access="private" returntype="transfer.com.dynamic.MethodInjector" output="false">
	<cfreturn instance.methodInjector />
</cffunction>

<cffunction name="setMethodInjector" access="private" returntype="void" output="false">
	<cfargument name="methodInjector" type="transfer.com.dynamic.MethodInjector" required="true">
	<cfset instance.methodInjector = arguments.methodInjector />
</cffunction>

<cffunction name="getDefinitionPath" access="private" returntype="string" output="false">
	<cfreturn instance.DefinitionPath />
</cffunction>

<cffunction name="setDefinitionPath" access="private" returntype="void" output="false">
	<cfargument name="DefinitionPath" type="string" required="true">
	<cfset instance.DefinitionPath = arguments.DefinitionPath />
</cffunction>

<!--- MIXINS --->

<cffunction name="__weave" hint="weaves the advice" access="public" returntype="void" output="false">
	<cfargument name="methodInjector" hint="The method injector" type="transfer.com.dynamic.MethodInjector" required="Yes">
	<cfargument name="pointCutName" hint="the name of the advice to weave" type="string" required="Yes">
	<cfargument name="advicePath" hint="The name the advice file" type="string" required="Yes">
	<cfargument name="aopKey" hint="the aop scope key" type="string" required="Yes">
	<cfscript>
		//first, move the function to where I want it to go, so I can call it later
		variables[arguments.pointCutName & "_" & arguments.aopKey] = variables[arguments.pointCutName];

		arguments.methodInjector.removeMethod(this, arguments.pointCutName);
	</cfscript>
	<cfinclude template="#arguments.advicePath#">
	<cfscript>
		arguments.methodInjector.injectMethod(this, variables[arguments.pointcutName]);
	</cfscript>
</cffunction>

<cffunction name="__findPointCuts" hint="builds an array of method point cuts from a string regex" access="public" returntype="array" output="false">
	<cfargument name="pointcut" hint="a regex for functions to advise" type="string" required="Yes">
	<cfscript>
		var pointCuts = ArrayNew(1);
		var keys = StructKeyArray(variables);
		var key = 0;
		var len = ArrayLen(keys);
		var counter = 1;
		var item = 0;

		for(; counter lte len; counter = counter + 1)
		{
			key = keys[counter];
			item = variables[key];

			if(isCustomFunction(item) AND reFindNoCase(arguments.pointCut, key))
			{
				ArrayAppend(pointCuts, item);
			}
		}

		return pointCuts;
	</cfscript>
</cffunction>

</cfcomponent>