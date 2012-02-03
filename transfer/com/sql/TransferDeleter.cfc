<!--- Document Information -----------------------------------------------------

Title:      TransferDeleter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Deletes a transfer from the DB

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/08/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="TransferDeleter" hint="Deletes a transfer from the DB" extends="AbstractBaseTransfer">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransferDeleter" output="false">
	<cfargument name="datasource" hint="The datasource BO" type="transfer.com.sql.Datasource" required="Yes" _autocreate="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="queryExecutionPool" hint="the query execution pool" type="transfer.com.sql.collections.QueryExecutionPool" required="Yes">
	<cfargument name="queryCache" hint="the query object cache" type="transfer.com.sql.collections.QueryCache" required="Yes">
	<cfargument name="transaction" type="transfer.com.sql.transaction.Transaction" required="true" _autocreate="false">
	<cfscript>
		super.init(argumentCollection=arguments);

		return this;
	</cfscript>
</cffunction>

<cffunction name="delete" hint="Deletes a transfer object" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to insert" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="useTransaction" hint="Whether or not to use an internal transaction block" type="boolean" required="true">
	<cfscript>
		if(arguments.useTransaction)
		{
			getTransaction().execute(this, "deleteBlock", arguments);
		}
		else
		{
			deleteBlock(arguments.transfer);
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="deleteBlock" hint="run the delete" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to delete" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		deleteAllManyToMany(arguments.transfer);
		deleteBasic(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="deleteBasic" hint="Deletes the single table part of the object" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to delete" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var query = buildDeleteBasic(arguments.transfer);
		var queryExec = query.createExecution();

		setPrimaryKey(queryExec, arguments.transfer);

		queryExec.execute();

		getQueryExecutionPool().recycle(queryExec);
	</cfscript>
</cffunction>

<cffunction name="buildDeleteBasic" hint="buids a basic delete" access="private" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="transfer" hint="The transfer object to insert" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var key = "basic.delete." &arguments.transfer.getClassName();
		var query = 0;
		var object = 0;
	</cfscript>
	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT getQueryCache().hasQuery(key))
			{
				query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());
				object = getObjectManager().getObject(arguments.transfer.getClassName());
				query.start();

				query.appendSQL("DELETE FROM ");
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

<cffunction name="deleteAllManyToMany" hint="Deletes any links that currently exist from this object out to a many to many link" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to insert" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var query = buildDeleteAllManyToMany(arguments.transfer);
		var queryExec = query.createExecution();

		setPrimaryKey(queryExec, arguments.transfer);

		queryExec.execute();

		getQueryExecutionPool().recycle(queryExec);
	</cfscript>
</cffunction>

<cffunction name="buildDeleteAllManyToMany" hint="builds the sql to delete external manytomany results" access="public" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="transfer" hint="The transfer object to delete" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var key = "manytomany.delete." & arguments.transfer.getClassName();
		var query = 0;
		var qManyToMany = 0;
		var object = 0;
	</cfscript>

	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
			<cfif NOT getQueryCache().hasQuery(key)>
				<cfscript>
					query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());
					qManyToMany = getObjectManager().getManyToManyLinksByClassLinkTo(arguments.transfer.getClassName());
					object = getObjectManager().getObject(arguments.transfer.getClassName());
				</cfscript>
				<cfloop query="qManyToMany">
					<cfscript>
						query.start();

						query.appendSQL("DELETE FROM ");
						query.appendSQL(table);
						query.appendSQL(" WHERE ");

						if(linkFrom eq arguments.transfer.getClassName())
						{
							//query.appendSQL(columnFrom);
							mapPrimaryKey(query, object, columnFrom);
						}
						else if(linkTo eq arguments.transfer.getClassName())
						{
							//query.appendSQL(columnTo);
							mapPrimaryKey(query, object, columnTo);
						}
						else
						{
							throw("transfer.ManyToManyMisconfiguredException",
									  "There is a error in the ManyToMany configuration.",
									  "In TransferObject '"& object.getClassName() &"' manytomany '"& name &"' does not link back to the containing object defintion.");
						}

						query.stop();
					</cfscript>
				</cfloop>
				<cfset getQueryCache().addQuery(key, query) />
			</cfif>
		</cflock>
	</cfif>
	<cfreturn getQueryCache().getQuery(key) />
</cffunction>

</cfcomponent>