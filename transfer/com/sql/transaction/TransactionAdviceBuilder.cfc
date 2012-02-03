<!--- Document Information -----------------------------------------------------

Title:      TransactionAdviceBuilder.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Builds the dynamic advice for Transactions

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		20/02/2008		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Builds the dynamic advice for Transactions" extends="transfer.com.aop.AbstractBaseAdviceBuilder" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransactionAdviceBuilder" output="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfscript>
		super.init(argumentCollection=arguments);

		instance.static.ADVICE_NAME = "Transaction";

		instance.mixins = StructNew();
		instance.mixins.__dependencyInject = variables.__dependencyInject;


		getMethodInjector().start(this);
		getMethodInjector().removeMethod(this, "__dependencyInject");
		getMethodInjector().stop(this);

		return this;
	</cfscript>
</cffunction>

<cffunction name="configure" hint="configure before using, and after init" access="public" returntype="void" output="false">
	<cfargument name="transaction" hint="The transaction service" type="Transaction" required="Yes">
	<cfargument name="transactionScopeKey" hint="the key the transaction is under" type="uuid" required="Yes">
	<cfscript>
		setTransaction(arguments.transaction);
		setTransactionScopeKey(arguments.transactionScopeKey);
	</cfscript>
</cffunction>

<cffunction name="buildAdvice" hint="builds the advice" access="public" returntype="void" output="false">
	<cfargument name="component" hint="the component to apply the advice to" type="any" required="Yes">
	<cfargument name="pointcut" hint="either a function, or a regex for functions to advise" type="any" required="Yes">
	<cfargument name="buffer" hint="the definition buffer to write to" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfscript>
		var dependency = StructNew();

		dependency.transaction = getTransaction();

		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine('var transaction = variables["#getTransactionScopeKey()#"].transaction;');
		arguments.buffer.writeLine("return transaction.execute(this, joinPointName, arguments);");
		arguments.buffer.cfscript(false);

		//make sure that the Transaction object is available in the variables scope
		if(NOT StructKeyExists(arguments.component, "__dependencyInject"))
		{
			//we don't need to start and stop, as we're already in a external block
			getMethodInjector().injectMethod(arguments.component, instance.mixins.__dependencyInject);
		}

		arguments.component.__dependencyInject(getTransactionScopeKey(), dependency);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getTransactionScopeKey" access="private" returntype="uuid" output="false">
	<cfreturn instance.transactionScopeKey />
</cffunction>

<cffunction name="setTransactionScopeKey" access="private" returntype="void" output="false">
	<cfargument name="transactionScopeKey" type="uuid" required="true">
	<cfset instance.transactionScopeKey = arguments.transactionScopeKey />
</cffunction>

<cffunction name="getTransaction" access="private" returntype="Transaction" output="false">
	<cfreturn instance.transaction />
</cffunction>

<cffunction name="setTransaction" access="private" returntype="void" output="false">
	<cfargument name="transaction" type="Transaction" required="true">
	<cfset instance.transaction = arguments.transaction />
</cffunction>

<!--- MIXINS --->

<cffunction name="__dependencyInject" hint="inject a dependency into the variables scope" access="public" returntype="void" output="false">
	<cfargument name="key" hint="the key to inject to" type="string" required="Yes">
	<cfargument name="value" hint="the value to inject" type="any" required="Yes">
	<cfscript>
		variables[arguments.key] = arguments.value;
	</cfscript>
</cffunction>

</cfcomponent>