<!--- Document Information -----------------------------------------------------

Title:      Transaction.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Transaction management to allow for cache clearing on Transaction failure, and nested Transactions

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		19/02/2008		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Transaction management to allow for cache clearing on Transaction failure, and nested Transactions"
			 extends="transfer.com.collections.AbstractBaseObservable"
			 output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Transaction" output="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfargument name="aopManager" hint="the manager for AOP" type="transfer.com.aop.AOPManager" required="Yes" autocreate="false">
	<cfargument name="transactionAdviceBuilder" hint="builds the transaction advice" type="transfer.com.sql.transaction.TransactionAdviceBuilder" required="Yes">
	<cfargument name="transactionEventPool" hint="the transaction event pool" type="transfer.com.sql.transaction.TransactionEventPool" required="Yes">
	<cfscript>
		super.init();

		instance.static.TRANSACTION_SCOPE_KEY = "3501D249-D86A-D21E-B66A4ABA1F5BFE92";

		instance.mixins = StructNew();
		instance.mixins.__invoke = variables.__invoke;

		setMethodInjector(arguments.methodInjector);
		setSystem(createObject("java", "java.lang.System"));

		getMethodInjector().start(this);
		getMethodInjector().removeMethod(this, "__invoke");
		getMethodInjector().stop(this);

		setTransactionLocal(createObject("java", "java.lang.ThreadLocal").init());

		arguments.transactionAdviceBuilder.configure(this, instance.static.TRANSACTION_SCOPE_KEY);

		setTransactionAdviceBuilder(arguments.transactionAdviceBuilder);
		setAOPMAnager(arguments.aopManager);
		setTransactionEventPool(arguments.transactionEventPool);

		return this;
	</cfscript>
</cffunction>

<cffunction name="execute" hint="executes a method, wrapped in a Transfer based transaction (works fine on private methods as well!)" access="public" returntype="any" output="false">
	<cfargument name="component" hint="the component context to execute the method" type="any" required="Yes">
	<cfargument name="method" hint="the name of the method to invoke" type="string" required="Yes">
	<cfargument name="args" hint="the argument collection to pass through" type="struct" required="false" default="#StructNew()#">
	<cfscript>
		var local = StructNew();
		var event = 0;
	</cfscript>
	<cfif NOT StructKeyExists(arguments.component, "__invoke")>
		<cflock name="transfer.Transaction.execute.#getSystem().identityHashCode(arguments.component)#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT StructKeyExists(arguments.component, "__invoke"))
			{
				getMethodInjector().start(arguments.component);
				getMethodInjector().injectMethod(arguments.component, instance.mixins.__invoke);
				getMethodInjector().stop(arguments.component);
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfif getInTransaction()>
		<cfset local.return = arguments.component.__invoke(arguments.method, arguments.args) />
	<cfelse>
		<cfset event = getTransactionEventPool().getTransactionEvent(arguments.component, arguments.method, arguments.args) />
		<cfset event.setAction("start") />
		<cftry>
			<cfset getTransactionLocal().set(true) />
			<cftransaction>
				<cfset fireEvent(event) />
				<cfset local.return = arguments.component.__invoke(arguments.method, arguments.args) />
			</cftransaction>
			<cfcatch>
				<cfset event.setAction("rollback") />
				<cfset fireEvent(event) />
				<cfset getTransactionLocal().set(false) />
				<cfrethrow>
			</cfcatch>
		</cftry>
		<cfset event.setAction("commit") />
		<cfset fireEvent(event) />
		<cfset getTransactionLocal().set(false) />
	</cfif>
	<cfscript>
		if(StructKeyExists(local, "return"))
		{
			return local.return;
		}
	</cfscript>
</cffunction>

<cffunction name="advise" hint="wrap transaction advise around a given method, or regex pattern of methods" access="public" returntype="void" output="false">
	<cfargument name="component" hint="the component to apply the advice to" type="any" required="Yes">
	<cfargument name="pointcut" hint="either a function, or a regex for functions to advise" type="any" required="Yes">
	<cfargument name="debug" hint="when true, cftrace's the method names that gets adviced" type="boolean" required="No" default="false">
	<cfscript>
		getAOPManager().advise(arguments.component, arguments.pointcut, getTransactionAdviceBuilder(), arguments.debug);
	</cfscript>
</cffunction>

<cffunction name="getInTransaction" hint="returns if we are in a transaction" access="public" returntype="boolean" output="false">
	<cfscript>
		var local = StructNew();
		local.in = getTransactionLocal().get();

		if(NOT StructKeyExists(local, "in"))
		{
			getTransactionLocal().set(false);
			return getTransactionLocal().get();
		}

		return local.in;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="fireActionMethod" hint="fires the transaction action method" access="private" returntype="void" output="false">
	<cfargument name="object" hint="the object to fire against" type="any" required="Yes">
	<cfargument name="event" hint="The event object to fire" type="TransactionEvent" required="Yes">
	<cfscript>
		arguments.object.actionTransactionEvent(arguments.event);
	</cfscript>
</cffunction>

<cffunction name="getTransactionLocal" access="private" returntype="any" output="false">
	<cfreturn instance.transactionLocal />
</cffunction>

<cffunction name="setTransactionLocal" access="private" returntype="void" output="false">
	<cfargument name="transactionLocal" type="any" required="true">
	<cfset instance.transactionLocal = arguments.transactionLocal />
</cffunction>

<cffunction name="getMethodInjector" access="private" returntype="transfer.com.dynamic.MethodInjector" output="false">
	<cfreturn instance.methodInjector />
</cffunction>

<cffunction name="setMethodInjector" access="private" returntype="void" output="false">
	<cfargument name="methodInjector" type="transfer.com.dynamic.MethodInjector" required="true">
	<cfset instance.methodInjector = arguments.methodInjector />
</cffunction>

<cffunction name="getTransactionAdviceBuilder" access="private" returntype="transfer.com.sql.transaction.TransactionAdviceBuilder" output="false">
	<cfreturn instance.transactionAdviceBuilder />
</cffunction>

<cffunction name="setTransactionAdviceBuilder" access="private" returntype="void" output="false">
	<cfargument name="transactionAdviceBuilder" type="transfer.com.sql.transaction.TransactionAdviceBuilder" required="true">
	<cfset instance.transactionAdviceBuilder = arguments.transactionAdviceBuilder />
</cffunction>

<cffunction name="getAOPManager" access="private" returntype="transfer.com.aop.AOPManager" output="false">
	<cfreturn instance.aopManager />
</cffunction>

<cffunction name="setAOPManager" access="private" returntype="void" output="false">
	<cfargument name="aopManager" type="transfer.com.aop.AOPManager" required="true">
	<cfset instance.aopManager = arguments.aopManager />
</cffunction>

<cffunction name="getTransactionEventPool" access="private" returntype="transfer.com.sql.transaction.TransactionEventPool" output="false">
	<cfreturn instance.transactionEventPool />
</cffunction>

<cffunction name="setTransactionEventPool" access="private" returntype="void" output="false">
	<cfargument name="transactionEventPool" type="transfer.com.sql.transaction.TransactionEventPool" required="true">
	<cfset instance.transactionEventPool = arguments.transactionEventPool />
</cffunction>

<cffunction name="getSystem" access="private" returntype="any" output="false">
	<cfreturn instance.System />
</cffunction>

<cffunction name="setSystem" access="private" returntype="void" output="false">
	<cfargument name="System" type="any" required="true">
	<cfset instance.System = arguments.System />
</cffunction>

<!--- MIXINS --->

<cffunction name="__invoke" hint="invokes a method on a cfc (mixin)" access="public" returntype="any" output="false">
	<cfargument name="method" hint="the method name to invoke" type="string" required="Yes">
	<cfargument name="args" hint="the argument collection to pass through" type="struct" required="false" default="#StructNew()#">
	<cfscript>
		//use this, as better to check for nulls.
		var local = StructNew();
		var call = variables[arguments.method];

		local.return = call(argumentCollection=arguments.args);

		if(StructKeyExists(local, "return"))
		{
			return local.return;
		}
	</cfscript>
</cffunction>

</cfcomponent>