<!--- Document Information -----------------------------------------------------

Title:      SQLFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    the factory for SQL related objects

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/09/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="The Factory for SQL related objects" extends="transfer.com.factory.AbstractBaseFactory" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="AOPFactory" output="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfargument name="definitionPath" hint="Path to where the definitions are kept" type="string" required="Yes">
	<cfscript>
		super.init();

		setPropertyValue("definitionPath", arguments.definitionPath);
		setSingleton(arguments.methodInjector);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getAOPAdvisor" hint="returns the AOP Advisor service" access="public" returntype="transfer.com.aop.AOPAdvisor" output="false">
	<cfreturn getSingleton("transfer.com.aop.AOPAdvisor") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>