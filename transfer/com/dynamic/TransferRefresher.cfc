<!--- Document Information -----------------------------------------------------

Title:      TransferRefresher.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Refreshes a transfer with Data after an insert or update

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		27/07/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="TransferRefresher" hint="Refreshes a transfer with Data after an insert or update">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="TransferRefresher" output="false">
	<cfargument name="sqlManager" hint="The SQL Manager" type="transfer.com.sql.SQLManager" required="Yes">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		setSQLManager(arguments.sqlManager);
		setObjectManager(arguments.objectManager);
		setMethodInvoker(createObject("component", "transfer.com.dynamic.MethodInvoker").init());

		return this;
	</cfscript>
</cffunction>

<cffunction name="refreshInsert" hint="refresh after an insert" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.transfer.getClassName());

		if(getSQLManager().hasInsertRefresh(arguments.transfer))
		{
			refresh(arguments.transfer, getSQLManager().getInsertRefreshQuery(arguments.transfer), "insert");
		}
	</cfscript>
</cffunction>

<cffunction name="refreshUpdate" hint="refresh after an insert" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		if(getSQLManager().hasUpdateRefresh(arguments.transfer))
		{
			refresh(arguments.transfer, getSQLManager().getUpdateRefreshQuery(arguments.transfer), "update");
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="refresh" hint="Refreshes the values of the object" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="refreshQuery" hint="The query with the refreshed data" type="query" required="Yes">
	<cfargument name="state" hint="update or insert" type="string" required="Yes">
	<cfscript>
		var memento = StructNew();
		var value = 0;
		var object = getObjectManager().getObject(arguments.transfer.getClassName());
		var iterator = object.getPropertyIterator();
		var property = 0;
		var refresh = false;

		/*
		move the resultset to the first row, so the
		getPropertyColumn can work propertly
		*/
		arguments.refreshQuery.first();

		while(iterator.hasNext())
		{
			property = iterator.next();

			switch(arguments.state)
			{
				case "insert":
					refresh = property.getRefreshInsert();
				break;

				case "update":
					refresh = property.getRefreshUpdate();
				break;
			}

			if(refresh)
			{
				memento[property.getName()] = getSQLManager().getPropertyColumnValue(arguments.refreshQuery, object, property);
			}
			else
			{
				memento[property.getName()] = getMethodInvoker().invokeMethod(arguments.transfer, "get" & property.getName());
			}
		}

		arguments.transfer.setPropertyMemento(memento);
	</cfscript>
</cffunction>

<cffunction name="getSQLManager" access="private" returntype="transfer.com.sql.SQLManager" output="false">
	<cfreturn instance.SQLManager />
</cffunction>

<cffunction name="setSQLManager" access="private" returntype="void" output="false">
	<cfargument name="SQLManager" type="transfer.com.sql.SQLManager" required="true">
	<cfset instance.SQLManager = arguments.SQLManager />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getMethodInvoker" access="private" returntype="transfer.com.dynamic.MethodInvoker" output="false">
	<cfreturn instance.MethodInvoker />
</cffunction>

<cffunction name="setMethodInvoker" access="private" returntype="void" output="false">
	<cfargument name="MethodInvoker" type="transfer.com.dynamic.MethodInvoker" required="true">
	<cfset instance.MethodInvoker = arguments.MethodInvoker />
</cffunction>

</cfcomponent>