<!--- Document Information -----------------------------------------------------

Title:      TransferSelecter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Builds a query out of BO Data, for MYSQL

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		25/05/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="TransferSelecter" hint="Builds a Query out of BO data, for MYSQL" extends="transfer.com.sql.TransferSelecter">

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="castValue" hint="Cast the value of this to another value" access="public" returntype="string" output="false">
	<cfargument name="column" hint="The column to write the 'NULL' for" type="string" required="Yes">
	<cfargument name="type" hint="Type to cast it to" type="string" required="Yes">
	<cfscript>
		var sql = "CONVERT(" & arguments.column & ", ";

		switch(arguments.type)
		{
			case "varchar":
				sql = sql & "char(1000)";
			break;
		}

		sql = sql & ")";

		return sql;
	</cfscript>
</cffunction>

<cffunction name="writeConcat" hint="writes concat seperator" access="private" returntype="string" output="false">
	<!--- the convert is so that we always get back a string --->
	<cfreturn ", char(1000)), CONVERT("/>
</cffunction>

<cffunction name="writeStartConcat" hint="writes the start concat seperator" access="private" returntype="string" output="false">
	<cfreturn "CONCAT(CONVERT("/>
</cffunction>

<cffunction name="writeEndConcat" hint="writes the end concat seperator" access="private" returntype="string" output="false">
	<cfreturn ", char(1000)))"/>
</cffunction>


</cfcomponent>