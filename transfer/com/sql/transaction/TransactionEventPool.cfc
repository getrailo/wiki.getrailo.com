
<cfcomponent name="TransactionEventPool" hint="A pool for TransactionEvent objects" extends="transfer.com.collections.AbstractBaseSemiSoftRefObjectPool">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="TransactionEventPool" output="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		//5 hard referenced items
		super.init(5, arguments.javaLoader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getTransactionEvent" hint="Gives you a Transaction Event" access="public" returntype="TransactionEvent" output="false">
	<cfargument name="object" hint="A Transaction object to send with the event" type="any" required="Yes">
	<cfargument name="method" hint="the name of the method" type="string" required="Yes">
	<cfargument name="args" hint="the argument collection for the method" type="struct" required="Yes">
	<cfscript>
		var event = 0;

		event = pop();

		event.setMemento(arguments);

		return event;
	</cfscript>
</cffunction>

<cffunction name="recycle" hint="recycles the event back in" access="public" returntype="void" output="false">
	<cfargument name="event" hint="Transaction event to be recycled" type="transfer.com.events.TransactionEvent" required="Yes">
	<cfscript>
		arguments.event.clean();
		push(arguments.event);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getNewObject" hint="returns the new CFC to repopulate the pool" access="private" returntype="TransactionEvent" output="false">
	<cfreturn createObject("component", "transfer.com.sql.transaction.TransactionEvent").init() />
</cffunction>

</cfcomponent>