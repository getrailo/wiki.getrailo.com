<!--- Document Information -----------------------------------------------------

Title:      Datasource.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    cf8 datasource bean

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		31/08/2007		Created

------------------------------------------------------------------------------->

<cfcomponent name="Datasource" hint="Datasource Bean" extends="transfer.com.sql.Datasource">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="Datasource" output="false">
	<cfscript>
		super.init();

		return this;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getDataBaseProductName" hint="retrience the database product name" access="private" returntype="string" output="false">
	<cfscript>
		var db = 0;
	</cfscript>
	<cfdbinfo datasource="#getName()#" username="#getUserName()#" password="#getPassword()#" name="db" type="version">

	<cfscript>
		return db.database_productName;
	</cfscript>
</cffunction>

</cfcomponent>