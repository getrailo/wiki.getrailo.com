<!--- Document Information -----------------------------------------------------

Title:      DatasourceFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    The Datsource factory

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/09/2007		Created

------------------------------------------------------------------------------->
<cfcomponent hint="The datasource Factory" extends="transfer.com.sql.DatasourceFactory" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="DatasourceFactory" output="false">
	<cfscript>
		super.init();

		return this;
	</cfscript>
</cffunction>

<cffunction name="getDatasource" hint="returns a datasource object" access="public" returntype="transfer.com.sql.Datasource" output="false">
	<cfreturn getSingleton("transfer.com.sql.cf8.Datasource") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>