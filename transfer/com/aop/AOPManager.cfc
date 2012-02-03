<!--- Document Information -----------------------------------------------------

Title:      aopManager.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Facade for aop management

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		19/02/2008		Created

------------------------------------------------------------------------------->
<cfcomponent hint="Facade for aop management" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="AOPManager" output="false">
	<cfargument name="aopFactory" hint="the aop factory" type="transfer.com.aop.AOPFactory" required="Yes">
	<cfscript>
		setAOPAdvisor(arguments.aopFactory.getAOPAdvisor());

		return this;
	</cfscript>
</cffunction>

<cffunction name="advise" hint="wrap some advice around a method" access="public" returntype="void" output="false">
	<cfargument name="component" hint="the component to apply the advice to" type="any" required="Yes">
	<cfargument name="pointcut" hint="either a function, or a regex for functions to advise" type="any" required="Yes">
	<cfargument name="adviceBuilder" hint="the advice builder" type="transfer.com.aop.AbstractBaseAdviceBuilder" required="Yes">
	<cfargument name="debug" hint="when true, cftrace's the method names that gets adviced" type="boolean" required="No">
	<cfscript>
		getAOPAdvisor().advise(argumentCollection=arguments);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getAOPAdvisor" access="private" returntype="AOPAdvisor" output="false">
	<cfreturn instance.aopAdvisor />
</cffunction>

<cffunction name="setAOPAdvisor" access="private" returntype="void" output="false">
	<cfargument name="aopAdvisor" type="AOPAdvisor" required="true">
	<cfset instance.aopAdvisor = arguments.aopAdvisor />
</cffunction>

</cfcomponent>