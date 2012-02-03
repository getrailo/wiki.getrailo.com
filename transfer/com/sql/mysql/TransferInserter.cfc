<!--- Document Information -----------------------------------------------------

Title:      TransferInserter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    TransferInserter for MySQL

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		27/04/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="TransferInserter" hint="TransferInserter for MySQL" extends="transfer.com.sql.TransferInserter">

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="buildSQLAfterInsert" hint="Selects the ID using LAST_INSERT_ID()" access="private" returntype="any" output="false">
	<cfargument name="object" hint="The object that is being inserted" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var query = 0;
		var key = "after.insert." & object.getClassName();
	</cfscript>
	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT getQueryCache().hasQuery(key))
			{
			query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());
				query.start();

				query.appendSQL("select LAST_INSERT_ID() as id");

				query.stop();

				getQueryCache().addQuery(key, query);
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn getQueryCache().getQuery(key) />
</cffunction>

</cfcomponent>