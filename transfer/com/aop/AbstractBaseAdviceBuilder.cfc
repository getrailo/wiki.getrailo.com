<!--- Document Information -----------------------------------------------------

Title:      AbstractBaseAdviceBuilder.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Abstract base for building advice on the fly

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		20/02/2008		Created

------------------------------------------------------------------------------->
<cfcomponent hint="Abstract base for building aop advice on the fly" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="AbstractBaseAdviceBuilder" output="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfscript>
		variables.instance = StructNew();

		instance.static = StructNew();

		setMethodInjector(arguments.methodInjector);

		return this;
	</cfscript>
</cffunction>

<cffunction name="buildAdvice" hint="builds the advice" access="public" returntype="void" output="false">
	<cfargument name="component" hint="the component to apply the advice to" type="any" required="Yes">
	<cfargument name="pointcut" hint="either a function, or a regex for functions to advise" type="any" required="Yes">
	<cfargument name="buffer" hint="the definition buffer to write to" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="getAdviceName" hint="gives an adive name for debugging purposes" access="public" returntype="string" output="false">
	<cfreturn instance.static.ADVICE_NAME />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getMethodInjector" access="private" returntype="transfer.com.dynamic.MethodInjector" output="false">
	<cfreturn instance.methodInjector />
</cffunction>

<cffunction name="setMethodInjector" access="private" returntype="void" output="false">
	<cfargument name="methodInjector" type="transfer.com.dynamic.MethodInjector" required="true">
	<cfset instance.methodInjector = arguments.methodInjector />
</cffunction>

</cfcomponent>