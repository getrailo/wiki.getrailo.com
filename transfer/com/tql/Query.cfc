<cfcomponent name="Query" hint="The TQL Query objects">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="transfer.com.tql.Query" output="false">
	<cfargument name="tql" hint="The TQL to set the query to" type="string" required="Yes">
	<cfscript>
		variables.instance = StructNew();

		configure(tql);

		return this;
	</cfscript>
</cffunction>

<cffunction name="setParam" hint="Sets a mapped parameter" access="public" returntype="void" output="false">
	<cfargument name="name" hint="The name of the mapping" type="string" required="Yes">
	<cfargument name="value" hint="The value of the mapping, required if 'null' is false" type="string" required="false">
	<cfargument name="type" hint="The type of the mapped value: string, date, boolean, numeric, GUID, UUID" type="string" required="false" default="string">
	<cfargument name="list" hint="if the mapped value is a list" type="boolean" required="No" default="false">
	<cfargument name="isNull" hint="If the value is actually null" type="boolean" required="No" default="false">
	<cfscript>
		if(NOT (StructKeyExists(arguments, "value") OR arguments.isNull))
		{
			throw("InvalidParamMappingException", "A mapped parameter value must be set if null is false", "Arguments 'value' must be set if 'null' is false");
		}

		addMappedParameter(arguments.name, arguments);
	</cfscript>
</cffunction>

<cffunction name="getParam" hint="Returns a mapped param" access="public" returntype="struct" output="false">
	<cfargument name="mapName" hint="The name of the mapping" type="string" required="Yes">
	<cfreturn getMappedParameter(arguments.mapName) />
</cffunction>

<cffunction name="getAliasColumns" access="public" returntype="boolean" output="false">
	<cfreturn variables.AliasColumns />
</cffunction>

<cffunction name="setAliasColumns" hint="If true, columns are alias'ed to the property names. Defaults to true." access="public" returntype="void" output="false">
	<cfargument name="AliasColumns" type="boolean" required="true">
	<cfset variables.AliasColumns = arguments.AliasColumns />
</cffunction>

<cffunction name="getTQL" access="public" returntype="string" output="false">
	<cfreturn instance.TQL />
</cffunction>

<cffunction name="clean" hint="Cleans the Query object for reuse" access="public" returntype="void" output="false">
	<cfscript>
		configure("");
	</cfscript>
</cffunction>

<cffunction name="getDistinctMode" access="public" returntype="boolean" output="false">
	<cfreturn instance.DistinctMode />
</cffunction>

<cffunction name="setDistinctMode" hint="When set to true, the query is run as DISTINCT. Defaults to false." access="public" returntype="void" output="false">
	<cfargument name="DistinctMode" type="boolean" required="true">
	<cfset instance.DistinctMode = arguments.DistinctMode />
</cffunction>

<cffunction name="getCacheEvaluation" access="public" returntype="boolean" output="false">
	<cfreturn instance.CacheEvaluation />
</cffunction>

<cffunction name="setCacheEvaluation" hint="When set to true, Transfer knows that the TQL isn't going to change, and caches the evaluation of the TQL for reuse. Defaults to: false" access="public" returntype="void" output="false">
	<cfargument name="CacheEvaluation" type="boolean" required="true">
	<cfset instance.CacheEvaluation = arguments.CacheEvaluation />
</cffunction>

<cffunction name="getHash" hint="returns a hash for the state this query" access="public" returntype="string" output="false">
	<cfreturn hash(getTQL() & getDistinctMode() & getAliasColumns()) />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="configure" hint="Configuration" access="private" returntype="void" output="false">
	<cfargument name="tql" hint="The tql to set the query to" type="string" required="Yes">
	<cfscript>
		setTQL(arguments.tql);
		setMappedParameters(StructNew());
		setAliasColumns(true);
		setDistinctMode(false);
		setCacheEvaluation(true);
	</cfscript>
</cffunction>

<cffunction name="getMappedParameters" access="private" returntype="struct" output="false">
	<cfreturn instance.MappedParameters />
</cffunction>

<cffunction name="setMappedParameters" access="private" returntype="void" output="false">
	<cfargument name="MappedParameters" type="struct" required="true">
	<cfset instance.MappedParameters = arguments.MappedParameters />
</cffunction>

<cffunction name="addMappedParameter" hint="Adds a mapped param to the collection" access="private" returntype="void" output="false">
	<cfargument name="mapName" hint="The name to map it to" type="string" required="Yes">
	<cfargument name="mapValues" hint="The struct of values to be mapped" type="struct" required="Yes">
	<cfscript>
		StructInsert(getMappedParameters(), arguments.mapName, arguments.mapValues);
	</cfscript>
</cffunction>

<cffunction name="getMappedParameter" hint="returns a mapped parameter" access="private" returntype="struct" output="false">
	<cfargument name="mapName" hint="The name to map the param to" type="string" required="Yes">
	<cfscript>
		return StructFind(getMappedParameters(), arguments.mapName);
	</cfscript>
</cffunction>

<cffunction name="setTQL" access="private" returntype="void" output="false">
	<cfargument name="TQL" type="string" required="true">
	<cfset instance.TQL = arguments.TQL />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>