<!--- Document Information -----------------------------------------------------

Title:      TransferFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Factory for Transfer

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		27/06/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="TransferFactory" hint="The Factory for Transfer, should be a scope singleton">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransferFactory" output="false">
	<cfargument name="datasourcePath" hint="The path to datasource xml file. Should be a relative path, i.e. /myapp/configs/datasource.xml" type="string" required="No">
	<cfargument name="configPath" hint="The path to the config xml file, Should be a relative path, i.e. /myapp/configs/transfer.xml" type="string" required="No">
	<cfargument name="definitionPath" hint="directory to write the defition files. Should be from root, i.e. /myapp/definitions/, as it is used for cfinclude" default="/transfer/resources/definitions/" type="string" required="No">
	<cfargument name="configuration" hint="A configuration bean.  If you supply one, you don't need to provide any other arguments" type="transfer.com.config.Configuration" required="No">

	<cfscript>
		var datasourceDAO = 0;
		var datasource = 0;

		var configReader = 0;

		var root = getDirectoryFromPath(getMetaData(this).path);

		var datasourceXSD = root & "resources/xsd/datasource.xsd";
		var transferXSD = root & "resources/xsd/transfer.xsd";
		var factory = createObject("component", "transfer.com.factory.Factory").init();

		var dsDAOArgs = StructNew();
		dsDAOArgs.datasourceFactory = factory.getDatasourceFactory();

		//push data from config object
		if(StructKeyExists(arguments, "configuration"))
		{
			arguments.datasourcePath = arguments.configuration.getDataSourcePath();
			arguments.configPath = arguments.configuration.getConfigPath();
			arguments.definitionPath = arguments.configuration.getDefinitionPath();
		}

		//Datasource first
		if(Len(arguments.datasourcePath))
		{
			dsDAOArgs.xmlFileReader = createObject("component", "transfer.com.io.XMLFileReader").init(expandPath(arguments.datasourcePath), datasourceXSD);
		}
		else
		{
			dsDAOArgs.configuration = arguments.configuration;
		}


		datasourceDAO = createObject("component", "transfer.com.sql.DatasourceDAO").init(argumentCollection=dsDAOArgs);

		setDatasource(dataSourceDAO.getDataSource());

		//object configuration
		configReader = createObject("component", "transfer.com.io.XMLFileReader").init(expandPath(arguments.configPath), transferXSD);

		//if we have a config object, and it has imports, lets add them
		if(StructKeyExists(arguments, "configuration"))
		{
			addImports(arguments.configuration, configReader);
		}

		//clean up definition Path
		if(NOT arguments.definitionPath.endsWith("/"))
		{
			arguments.definitionPath = arguments.definitionPath & "/";
		}

		//set up initial dependencies
		factory.setSingleton(getDatasource(), "transfer.com.sql.Datasource"); //make sure it is set to the the right name
		factory.setSingleton(configReader);
		factory.setPropertyValue("definitionPath", arguments.definitionPath);
		factory.setPropertyValue("version", getVersion());

		setTransactionManager(factory.getTransactionManager());

		setTransfer(createObject("component", "transfer.com.Transfer").init(factory));

		return this;
	</cfscript>
</cffunction>

<cffunction name="getDatasource" access="public" hint="Returns the datasource bean that provides connectivity details to the database" returntype="transfer.com.sql.Datasource" output="false">
	<cfreturn instance.Datasource />
</cffunction>

<cffunction name="getTransfer" access="public" hint="Returns the main library class, that is used in all processing" returntype="transfer.com.Transfer" output="false">
	<cfreturn instance.Transfer />
</cffunction>

<cffunction name="getTransaction" hint="returns the Transfer transaction management service" access="public" returntype="transfer.com.sql.transaction.Transaction" output="false">
	<cfreturn getTransactionManager().getTransaction() />
</cffunction>

<cffunction name="getVersion" access="public" hint="Returns the version number" returntype="string" output="false">
	<cfreturn "1.1"/>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="addImports" hint="add the imports into the configReader" access="private" returntype="void" output="false">
	<cfargument name="configuration" hint="the config bean" type="transfer.com.config.Configuration" required="Yes">
	<cfargument name="configReader" hint="the XML config reader" type="transfer.com.io.XMLFileReader" required="Yes">
	<cfscript>
		var imports = arguments.configuration.getConfigPathCollection();
		var len = ArrayLen(imports);
		var counter = 2;
		var configState = 0;

		if(len gte 2)
		{
			for(; counter lte len; counter = counter + 1)
			{
				configState = imports[counter];
				arguments.configReader.addXML(expandPath(configState.configPath), configState.overwrite);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="getTransactionManager" access="private" returntype="transfer.com.sql.transaction.TransactionManager" output="false">
	<cfreturn instance.TransactionManager />
</cffunction>

<cffunction name="setTransactionManager" access="private" returntype="void" output="false">
	<cfargument name="TransactionManager" type="transfer.com.sql.transaction.TransactionManager" required="true">
	<cfset instance.TransactionManager = arguments.TransactionManager />
</cffunction>

<cffunction name="setTransfer" access="private" returntype="void" output="false">
	<cfargument name="Transfer" type="transfer.com.Transfer" required="true">
	<cfset instance.Transfer = arguments.Transfer />
</cffunction>

<cffunction name="setDatasource" access="private" returntype="void" output="false">
	<cfargument name="Datasource" type="transfer.com.sql.Datasource" required="true">
	<cfset instance.Datasource = arguments.Datasource />
</cffunction>


</cfcomponent>