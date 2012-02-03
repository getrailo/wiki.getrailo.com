<!--- Document Information -----------------------------------------------------

Title:      Datasource.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Datasource Bean

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		27/06/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="Datasource" hint="Datasource Bean">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="Datasource" output="false">
	<cfscript>
		setName("");
		setUsername("");
		setPassword("");

		return this;
	</cfscript>
</cffunction>

<cffunction name="getName" access="public" returntype="string" output="false">
	<cfreturn instance.Name />
</cffunction>

<cffunction name="getUserName" access="public" returntype="string" output="false">
	<cfreturn instance.UserName />
</cffunction>

<cffunction name="getPassword" access="public" returntype="string" output="false">
	<cfreturn instance.Password />
</cffunction>

<cffunction name="getDatabaseType" access="public" returntype="string" output="false">
	<cfreturn instance.DatabaseType />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="The memento the is the state of the object" type="struct" required="Yes">

	<cfscript>
		setName(arguments.memento.name);
		setUserName(arguments.memento.username);
		setPassword(arguments.memento.password);

		setDatabaseType(queryDatabaseType());
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getConnection" hint="Returns a java.sql.Connection" access="private" returntype="any" output="false">
	<cfscript>
		var datasourceService = createObject("Java", "coldfusion.server.ServiceFactory").getDataSourceService();

		if(Len(getUserName()))
		{
			return datasourceService.getDatasource(getName()).getConnection(getUserName(), getPassword());
		}
		else
		{
			return datasourceService.getDatasource(getName()).getConnection();
		}
	</cfscript>
</cffunction>

<cffunction name="getDataBaseProductName" hint="retrience the database product name" access="private" returntype="string" output="false">
	<cfscript>
		var connection = getConnection();
		var db = connection.getMetaData().getDatabaseProductName();

		connection.close();

		return db;
	</cfscript>
</cffunction>

<cffunction name="queryDatabaseType" hint="Returns string value of the db type. Current values are: mssql, mysql" access="private" returntype="string" output="false">
	<cfscript>
		var type = 0;
		var db = getDataBaseProductName();

		switch(db)
		{
			case "Microsoft SQL Server":
				type = "mssql";
			break;

			case "MySQL":
				type = "mysql";
			break;

			case "PostgreSQL":
				type = "postgresql";
			break;

			case "Oracle":
				type = "oracle";
			break;

			default:
				connection.close();
				throw("UnsupportedDatabaseException", "An unsupported database has been attempted to be used", "The database of type '#db#' is currently not supported by Transfer");
			break;
		}


		return type;
	</cfscript>
</cffunction>

<cffunction name="setName" access="private" returntype="void" output="false">
	<cfargument name="Name" type="string" required="true">
	<cfset instance.Name = arguments.Name />
</cffunction>

<cffunction name="setUserName" access="private" returntype="void" output="false">
	<cfargument name="UserName" type="string" required="true">
	<cfset instance.UserName = arguments.UserName />
</cffunction>


<cffunction name="setPassword" access="private" returntype="void" output="false">
	<cfargument name="Password" type="string" required="true">
	<cfset instance.Password = arguments.Password />
</cffunction>

<cffunction name="setDatabaseType" access="private" returntype="void" output="false">
	<cfargument name="DatabaseType" type="string" required="true">
	<cfset instance.DatabaseType = arguments.DatabaseType />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>