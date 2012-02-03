<!--- Document Information -----------------------------------------------------

Title:      TransferRefresher.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    SQL management for refreshing TransferObject values

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		14/08/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="SQL management for refreshing TransferObject values" extends="transfer.com.sql.AbstractBaseTransfer" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransferRefresher" output="false">
	<cfargument name="datasource" hint="The datasource BO" type="transfer.com.sql.Datasource" required="Yes" _autocreate="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="queryExecutionPool" hint="the query execution pool" type="transfer.com.sql.collections.QueryExecutionPool" required="Yes">
	<cfargument name="queryCache" hint="the query object cache" type="transfer.com.sql.collections.QueryCache" required="Yes">
	<cfargument name="transaction" type="transfer.com.sql.transaction.Transaction" required="true" _autocreate="false">
	<cfscript>
		super.init(argumentCollection=arguments);

		setInsertRefreshCache(StructNew());
		setUpdateRefreshCache(StructNew());

		return this;
	</cfscript>
</cffunction>

<cffunction name="hasInsertRefresh" hint="Check to see if it requires a run of the refresh query" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfif NOT StructKeyExists(getInsertRefreshCache(), arguments.transfer.getClassName())>
		<cflock name="transfer.refresh.has.insert.#arguments.transfer.getClassName()#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT StructKeyExists(getInsertRefreshCache(), arguments.transfer.getClassName()))
			{
				StructInsert(getInsertRefreshCache(), arguments.transfer.getClassName(), resovlveHasInsertRefresh(arguments.transfer));
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn StructFind(getInsertRefreshCache(), arguments.transfer.getClassName()) />
</cffunction>

<cffunction name="getInsertRefreshQuery" hint="Returns the refresh query for an insert" access="public" returntype="query" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var query = buildInsertRefresh(arguments.transfer);
		var queryExec = query.createExecution();
		var qResult = 0;

		setPrimaryKey(queryExec, arguments.transfer);

		qResult = queryExec.executeQuery();

		getQueryExecutionPool().recycle(queryExec);

		return qResult;
		</cfscript>
</cffunction>

<cffunction name="hasUpdateRefresh" hint="Check to see if it requires a run of the refresh query" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfif NOT StructKeyExists(getUpdateRefreshCache(), arguments.transfer.getClassName())>
		<cflock name="transfer.refresh.has.update.#arguments.transfer.getClassName()#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT StructKeyExists(getUpdateRefreshCache(), arguments.transfer.getClassName()))
			{
				StructInsert(getUpdateRefreshCache(), arguments.transfer.getClassName(), resovlveHasUpdateRefresh(arguments.transfer));
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn StructFind(getUpdateRefreshCache(), arguments.transfer.getClassName()) />
</cffunction>

<cffunction name="getUpdateRefreshQuery" hint="Returns the refresh query for an insert" access="public" returntype="query" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var query = buildUpdateRefresh(arguments.transfer);
		var queryExec = query.createExecution();
		var qResult = 0;

		setPrimaryKey(queryExec, arguments.transfer);

		qResult = queryExec.executeQuery();

		getQueryExecutionPool().recycle(queryExec);

		return qResult;
		</cfscript>
</cffunction>


<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="buildInsertRefresh" hint="builds the insert refresh query" access="private" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var key = "transfer.refresh.get.insert." & arguments.transfer.getClassName();
		var object = 0;
		var property = 0;
		var iterator = 0;
		var query = 0;
		var isFirst = true;
	</cfscript>
	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT getQueryCache().hasQuery(key))
			{
				query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());
				object = getObjectManager().getObject(arguments.transfer.getClassName());
				iterator = object.getPropertyIterator();

				query.start();

				query.appendSQL("SELECT ");

				while(iterator.hasNext())
				{
					property = iterator.next();

					if(property.getRefreshInsert())
					{
						isFirst = commaSeperator(query, isFirst);
						query.appendSQL(property.getColumn());
					}
				}

				query.appendSQL(" FROM ");

				query.appendSQL(object.getTable());

				query.appendSQL(" WHERE ");

				mapPrimaryKey(query, object);

				query.stop();

				getQueryCache().addQuery(key, query);
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn getQueryCache().getQuery(key) />
</cffunction>

<cffunction name="buildUpdateRefresh" hint="builds the insert refresh query" access="private" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var key = "transfer.refresh.get.update." & arguments.transfer.getClassName();
		var object = 0;
		var property = 0;
		var iterator = 0;
		var query = 0;
		var isFirst = true;
	</cfscript>
	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT getQueryCache().hasQuery(key))
			{
				query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());
				object = getObjectManager().getObject(arguments.transfer.getClassName());
				iterator = object.getPropertyIterator();

				query.start();

				query.appendSQL("SELECT ");

				while(iterator.hasNext())
				{
					property = iterator.next();

					if(property.getRefreshUpdate())
					{
						isFirst = commaSeperator(query, isFirst);
						query.appendSQL(property.getColumn());
					}
				}

				query.appendSQL(" FROM ");

				query.appendSQL(object.getTable());

				query.appendSQL(" WHERE ");

				mapPrimaryKey(query, object);

				query.stop();

				getQueryCache().addQuery(key, query);
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn getQueryCache().getQuery(key) />
</cffunction>

<cffunction name="resovlveHasInsertRefresh" hint="whether a given object has a insert refresh" access="private" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.transfer.getClassName());
		var property = 0;
		var iterator = object.getPropertyIterator();

		while(iterator.hasNext())
		{
			property = iterator.next();
			if(property.getRefreshInsert())
			{
				return true;
			}
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="resovlveHasUpdateRefresh" hint="whether a given object has a insert refresh" access="private" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The object to refresh" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.transfer.getClassName());
		var property = 0;
		var iterator = object.getPropertyIterator();

		while(iterator.hasNext())
		{
			property = iterator.next();
			if(property.getRefreshUpdate())
			{
				return true;
			}
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="getInsertRefreshCache" access="private" returntype="struct" output="false">
	<cfreturn instance.InsertRefreshCache />
</cffunction>

<cffunction name="setInsertRefreshCache" access="private" returntype="void" output="false">
	<cfargument name="InsertRefreshCache" type="struct" required="true">
	<cfset instance.InsertRefreshCache = arguments.InsertRefreshCache />
</cffunction>

<cffunction name="getUpdateRefreshCache" access="private" returntype="struct" output="false">
	<cfreturn instance.UpdateRefreshCache />
</cffunction>

<cffunction name="setUpdateRefreshCache" access="private" returntype="void" output="false">
	<cfargument name="UpdateRefreshCache" type="struct" required="true">
	<cfset instance.UpdateRefreshCache = arguments.UpdateRefreshCache />
</cffunction>

</cfcomponent>