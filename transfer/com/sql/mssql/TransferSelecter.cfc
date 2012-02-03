<!--- Document Information -----------------------------------------------------

Title:      TransferSelecter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Builds a query out of BO Data, for MSSQL

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		25/05/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="TransferSelecter" hint="Builds a Query out of BO data, for MSSQL" extends="transfer.com.sql.TransferSelecter">

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="castValue" hint="Cast the value of this to another value" access="public" returntype="string" output="false">
	<cfargument name="column" hint="The column to write the 'NULL' for" type="string" required="Yes">
	<cfargument name="type" hint="Type to cast it to" type="string" required="Yes">
	<cfscript>
		var sql = "CAST(" & arguments.column & " as ";

		switch(arguments.type)
		{
			case "varchar":
				sql = sql & "varchar(1000)";
			break;
		}

		sql = sql & ")";

		return sql;
	</cfscript>
</cffunction>

<cffunction name="writeConcat" hint="writes concat seperator" access="private" returntype="string" output="false">
	<cfreturn " + "/>
</cffunction>

<cffunction name="appendCompositeKeyValue" hint="appends the composite key value to the buffer" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="the string buffer" type="any" required="Yes">
	<cfargument name="table" hint="the name of the table" type="string" required="Yes">
	<cfargument name="column" hint="the column to add" type="string" required="Yes">
	<cfscript>
		var localBuffer = createObject("java", "java.lang.StringBuffer").init();

		super.appendCompositeKeyValue(localBuffer, arguments.table, arguments.column);

		arguments.buffer.append(castValue(localBuffer.toString(), "varchar"));
	</cfscript>
</cffunction>

</cfcomponent>