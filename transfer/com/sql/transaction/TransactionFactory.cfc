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

<cffunction name="init" hint="Constructor" access="public" returntype="TransactionFactory" output="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _factoryMethod="getMethodInjector">
	<cfargument name="aopManager" hint="the manager for AOP" type="transfer.com.aop.AOPManager" required="Yes">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _factorymethod="getJavaLoader">
	<cfscript>
		super.init();

		setSingleton(arguments.methodInjector);
		setSingleton(arguments.aopManager);
		setSingleton(arguments.javaLoader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getTransaction" hint="returns the transfer Transaction service" access="public" returntype="transfer.com.sql.transaction.Transaction" output="false">
	<cfreturn getSingleton("transfer.com.sql.transaction.Transaction") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>