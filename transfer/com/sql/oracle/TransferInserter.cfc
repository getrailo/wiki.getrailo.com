<cfcomponent name="TransferInserter" hint="TransferInserter for Oracle" extends="transfer.com.sql.TransferInserter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<!--- <cffunction name="sqlBeforeInsert" hint="Selects the ID using select sequence.nexval from dual" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The object that is being inserted" type="transfer.com.object.Object" required="Yes">
	<cfreturn "select "& arguments.object.getSequence() &".nextval as id from dual">
</cffunction>
 --->

<cffunction name="buildSQLBeforeInsert" hint="builds the SQL Before Insert, if populating" access="private" returntype="any" output="false">
	<cfargument name="object" hint="The object that is being inserted" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var query = 0;
		var key = "before.insert." & object.getClassName();
	</cfscript>
	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT getQueryCache().hasQuery(key))
			{
				query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());
				query.start();

				query.appendSQL("select "& arguments.object.getSequence() &".nextval as id from dual");

				query.stop();

				getQueryCache().addQuery(key, query);
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn getQueryCache().getQuery(key) />
</cffunction>

</cfcomponent>