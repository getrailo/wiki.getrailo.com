<!--- Document Information -----------------------------------------------------

Title:      TransferInserter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    TransferInserter for MSSQL Server

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		27/04/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="TransferInserter" hint="TransferInserter for mssql" extends="transfer.com.sql.TransferInserter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="buildSqlInsideInsert" hint="Overwrite method to run SQL inside the insert query (with no generation), and before the end of the cfquery block. Should select a 'id' column for id population" access="private" returntype="void" output="false">
	<cfargument name="query" hint="the query object" type="transfer.com.sql.Query" required="Yes">
	<cfargument name="object" hint="The oject that is being inserted" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		query.appendSQL("; ");
		query.appendSQL("select SCOPE_IDENTITY() as id");
	</cfscript>
</cffunction>

<!--- <cffunction name="sqlInsideInsert" hint="Overwrite method to run SQL directly after the insert query (with no generation), and before the end of the cfquery block" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The oject that is being inserted" type="transfer.com.object.Object" required="Yes">
	<cfreturn "select SCOPE_IDENTITY() as id">
</cffunction> --->

</cfcomponent>