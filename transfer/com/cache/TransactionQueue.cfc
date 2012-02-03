<!--- Document Information -----------------------------------------------------

Title:      TransactionQueue.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Managed the queue for a given transaction, on a particular thread

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		22/02/2008		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Managed the queue for a given transaction, on a particular thread" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransactionQueue" output="false">
	<cfargument name="transfer" hint="the transfer orm lib" type="transfer.com.Transfer" required="Yes" _autocreate="false">
	<cfargument name="transaction" type="transfer.com.sql.transaction.Transaction" required="true" _autocreate="false">
	<cfscript>
		setTransfer(arguments.transfer);
		setTransaction(arguments.transaction);
		setQueueLocal(createObject("java", "java.lang.ThreadLocal").init());

		getTransaction().addObserver(this);

		return this;
	</cfscript>
</cffunction>

<cffunction name="append" hint="appends a transfer object to the queue" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to append to the queue" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		ArrayAppend(getQueue(), arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="remove" hint="remove a transfer object from the transfer queue" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to append to the queue" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var queue = getQueue();
		var len = ArrayLen(queue);
		var counter = 1;
		var item = 0;
		for(; counter lte len; counter = counter + 1)
		{
			item = queue[counter];
			if(item.sameTransfer(arguments.transfer))
			{
				ArrayDeleteAt(getQueue(), counter);
				return;
			}
		}
	</cfscript>
</cffunction>

<cffunction name="actionTransactionEvent" hint="action the transaction event" access="public" returntype="void" output="false">
	<cfargument name="event" hint="the transaction event object" type="transfer.com.sql.transaction.TransactionEvent" required="Yes">
	<cfscript>
		if(arguments.event.getAction() eq "commit")
		{
			resetQueue();
		}
		else if(arguments.event.getAction() eq "rollback")
		{
			discardQueue();
			resetQueue();
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="discardQueue" hint="discards the entire transaction queue" access="private" returntype="void" output="false">
	<cfscript>
		var queue = getQueue();
		var len = ArrayLen(queue);
		var counter = 1;
		var object = 0;

		for(; counter lte len; counter = counter + 1)
		{
			object = queue[counter];
			getTransfer().discard(object);
		}
	</cfscript>
</cffunction>

<cffunction name="resetQueue" hint="resets the transaction queue to it's initial state" access="private" returntype="void" output="false">
	<!---
		we're going to use an ArrayList, as it's only used on a single thread
		and it get's passed by reference'
	 --->
	<cfset getQueueLocal().set(createObject("java", "java.util.ArrayList").init()) />
</cffunction>

<cffunction name="getQueue" hint="returns the thread local transaction queue" access="private" returntype="array" output="false">
	<cfscript>
		var local = StructNew();

		local.queue = getQueueLocal().get();

		if(NOT StructKeyExists(local, "queue"))
		{
			resetQueue();
			return getQueueLocal().get();
		}

		return local.queue;
	</cfscript>
</cffunction>

<cffunction name="getQueueLocal" access="private" returntype="any" output="false">
	<cfreturn instance.queueLocal />
</cffunction>

<cffunction name="setQueueLocal" access="private" returntype="void" output="false">
	<cfargument name="queueLocal" type="any" required="true">
	<cfset instance.queueLocal = arguments.queueLocal />
</cffunction>

<cffunction name="getTransaction" access="private" returntype="transfer.com.sql.transaction.Transaction" output="false">
	<cfreturn instance.transaction />
</cffunction>

<cffunction name="setTransaction" access="private" returntype="void" output="false">
	<cfargument name="transaction" type="transfer.com.sql.transaction.Transaction" required="true">
	<cfset instance.transaction = arguments.transaction />
</cffunction>

<cffunction name="getTransfer" access="private" returntype="transfer.com.Transfer" output="false">
	<cfreturn instance.transfer />
</cffunction>

<cffunction name="setTransfer" access="private" returntype="void" output="false">
	<cfargument name="transfer" type="transfer.com.Transfer" required="true">
	<cfset instance.transfer = arguments.transfer />
</cffunction>

</cfcomponent>