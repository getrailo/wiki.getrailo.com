<!--- Document Information -----------------------------------------------------

Title:      Property.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Property BO

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/07/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="Property" hint="Property BO">
<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Property" output="false">
	<cfscript>
		setName("");
		setType("");
		setSet(true);
		setColumn("");
		setIsNullable(false);
		removeNullValue();
		setIgnoreUpdate(false);
		setIgnoreInsert(false);
		setRefreshInsert(false);
		setRefreshUpdate(false);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getName" access="public" returntype="string" output="false">
	<cfreturn instance.name />
</cffunction>

<cffunction name="getType" access="public" returntype="string" output="false">
	<cfreturn instance.type />
</cffunction>

<cffunction name="getSet" access="public" returntype="boolean" output="false">
	<cfreturn instance.Set />
</cffunction>

<cffunction name="getColumn" access="public" returntype="string" output="false">
	<cfreturn instance.Column />
</cffunction>

<cffunction name="getIsNullable" access="public" returntype="boolean" output="false">
	<cfreturn instance.IsNullable />
</cffunction>

<cffunction name="getNullValue" access="public" returntype="string" output="false">
	<cfreturn instance.NullValue />
</cffunction>

<cffunction name="hasNullValue" hint="Returns if the property has a nullvalue" access="public" returntype="boolean" output="false">
	<cfreturn StructKeyExists(instance, "nullvalue")>
</cffunction>

<cffunction name="getIgnoreInsert" access="public" returntype="boolean" output="false">
	<cfreturn instance.IgnoreInsert />
</cffunction>

<cffunction name="getRefreshInsert" access="public" returntype="string" output="false">
	<cfreturn instance.RefreshInsert />
</cffunction>

<cffunction name="getIgnoreUpdate" access="public" returntype="boolean" output="false">
	<cfreturn instance.IgnoreUpdate />
</cffunction>

<cffunction name="getRefreshUpdate" access="public" returntype="string" output="false">
	<cfreturn instance.RefreshUpdate />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setName(arguments.memento.name);
		setType(arguments.memento.type);
		setSet(arguments.memento.set);
		setColumn(arguments.memento.column);
		setIsNullable(arguments.memento.nullable);

		if(StructKeyExists(arguments.memento, "nullvalue"))
		{
			setNullValue(arguments.memento.nullvalue);
		}

		//this is the way it comes out the xml
		setIgnoreUpdate(memento["ignore-update"]);
		setIgnoreInsert(memento["ignore-insert"]);
		setRefreshInsert(memento["refresh-insert"]);
		setRefreshUpdate(memento["refresh-update"]);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setRefreshUpdate" access="private" returntype="void" output="false">
	<cfargument name="RefreshUpdate" type="string" required="true">
	<cfset instance.RefreshUpdate = arguments.RefreshUpdate />
</cffunction>

<cffunction name="setIgnoreUpdate" access="private" returntype="void" output="false">
	<cfargument name="IgnoreUpdate" type="boolean" required="true">
	<cfset instance.IgnoreUpdate = arguments.IgnoreUpdate />
</cffunction>

<cffunction name="setRefreshInsert" access="private" returntype="void" output="false">
	<cfargument name="RefreshInsert" type="string" required="true">
	<cfset instance.RefreshInsert = arguments.RefreshInsert />
</cffunction>

<cffunction name="setIgnoreInsert" access="private" returntype="void" output="false">
	<cfargument name="IgnoreInsert" type="boolean" required="true">
	<cfset instance.IgnoreInsert = arguments.IgnoreInsert />
</cffunction>

<cffunction name="removeNullValue" hint="Removes having a null value" access="private" returntype="void" output="false">
	<cfscript>
		StructDelete(instance, "nullvalue");
	</cfscript>
</cffunction>

<cffunction name="setName" access="private" returntype="void" output="false">
	<cfargument name="name" type="string" required="true">
	<cfset instance.name = arguments.name />
</cffunction>

<cffunction name="setType" access="private" returntype="void" output="false">
	<cfargument name="type" type="string" required="true">
	<cfset instance.type = LCase(arguments.type) />
</cffunction>

<cffunction name="setSet" access="private" returntype="void" output="false">
	<cfargument name="Set" type="boolean" required="true">
	<cfset instance.Set = arguments.Set />
</cffunction>

<cffunction name="setColumn" access="private" returntype="void" output="false">
	<cfargument name="Column" type="string" required="true">
	<cfset instance.Column = arguments.Column />
</cffunction>

<cffunction name="setIsNullable" access="private" returntype="void" output="false">
	<cfargument name="IsNullable" type="boolean" required="true">
	<cfset instance.IsNullable = arguments.IsNullable />
</cffunction>

<cffunction name="setNullValue" access="private" returntype="void" output="false">
	<cfargument name="nullvalue" type="string" required="true">
	<cfset instance.nullvalue = arguments.nullvalue />
</cffunction>

</cfcomponent>