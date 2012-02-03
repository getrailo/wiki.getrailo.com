<cfcomponent name="TransferEventPool" hint="A pool for TransferEvent objects" extends="transfer.com.collections.AbstractBaseSemiSoftRefObjectPool">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="TransferEventPool" output="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		//10 hard referenced items
		super.init(10, arguments.javaLoader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getTransferEvent" hint="Gives you a Transfer Event" access="public" returntype="transfer.com.events.TransferEvent" output="false">
	<cfargument name="transfer" hint="A transfer object to send with the event" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var event = 0;
		var memento = StructNew();

		event = pop();

		memento.transferObject = arguments.transfer;
		event.setMemento(memento);

		return event;
	</cfscript>
</cffunction>

<cffunction name="recycle" hint="recycles the event back in" access="public" returntype="void" output="false">
	<cfargument name="event" hint="transfer event to be recycled" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		arguments.event.clean();
		push(arguments.event);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getNewObject" hint="virtual method: returns the new CFC to repopulate the pool" access="private" returntype="any" output="false">
	<cfreturn createObject("component", "transfer.com.events.TransferEvent").init() />
</cffunction>

</cfcomponent>