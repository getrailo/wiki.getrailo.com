<!--- Document Information -----------------------------------------------------

Title:      ScopeDAO.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Data Access Object for Scope Values

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		15/05/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="ScopeDAO" hint="Data Access Object for Scope Values">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="ScopeDAO" output="false">
	<cfargument name="configReader" hint="The XML Reader for the config file" type="transfer.com.io.XMLFileReader" required="Yes">
	<cfscript>
		setConfigReader(arguments.configReader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getScope" hint="Retrieves a definition of a scope" access="public" returntype="transfer.com.cache.Scope" output="false">
	<cfargument name="scope" hint="Scope object to populate" type="transfer.com.cache.Scope" required="Yes">
	<cfargument name="scopeType" hint="The scope to retrieve" type="string" required="Yes">

	<cfscript>
		var xPath = "/transfer/objectCache/scopes/";
		var xScope = 0;
		var memento = StructNew();

		xPath = xPath & arguments.scopeType;

		xScope = getConfigReader().search(xPath);

		memento.type = arguments.scopeType;

		if(arrayLen(xScope))
		{
			memento.key = xScope[1].xmlattributes.key;
		}
		else
		{
			memento.key = "transfer";
		}

		arguments.scope.setMemento(memento);

		return arguments.scope;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getConfigReader" access="private" returntype="transfer.com.io.XMLFileReader" output="false">
	<cfreturn instance.ConfigReader />
</cffunction>

<cffunction name="setConfigReader" access="private" returntype="void" output="false">
	<cfargument name="ConfigReader" type="transfer.com.io.XMLFileReader" required="true">
	<cfset instance.ConfigReader = arguments.ConfigReader />
</cffunction>

</cfcomponent>