<!--- Document Information -----------------------------------------------------

Title:      TransferGateway.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Dynamically creates SQL for gateway calls

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		04/04/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="TransferGateway" hint="Dynamically develops SQL for gateway calls">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="TransferGateway" output="false">
	<cfargument name="datasource" hint="The datasource BO" type="transfer.com.sql.Datasource" required="Yes" _autocreate="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfscript>
		setDataSource(arguments.datasource);
		setObjectManager(arguments.objectManager);
		setSelectSQLCache(StructNew());

		return this;
	</cfscript>

</cffunction>

<cffunction name="list" hint="Lists a series of object values" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="No" default="">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="No" default="true">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="no" default="true">

	<cfscript>
		var object = getObjectManager().getObject(arguments.className);
		var qQuery = 0;
	</cfscript>

	<cfquery name="qQuery" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
		#writeSelectFromSQL(object, false, arguments.useAliases)#

		#writeOrderBySQL(object, arguments.orderProperty, arguments.orderASC)#
	</cfquery>
	<cfreturn qQuery>
</cffunction>

<cffunction name="listByProperty" hint="Lists a series of values, filtered by a given value" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to filter by" type="string" required="Yes">
	<cfargument name="propertyValue" hint="The value to filter by (only simple values)" type="any" required="Yes">
	<cfargument name="onlyRetrievePrimaryKey" hint="boolean to whether or not to only retrieve the primary key" type="boolean" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="No" default="">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="No" default="true">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="no" default="true">

	<cfscript>
		var object = getObjectManager().getObject(arguments.className);
		var qQuery = 0;
		var filterProperty = object.getPropertyByName(arguments.propertyName);
	</cfscript>

	<cfquery name="qQuery" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
		#writeSelectFromSQL(object, arguments.onlyRetrievePrimaryKey, arguments.useAliases)#

		where
		#filterProperty.getColumn()# =
		<cfswitch expression="#filterProperty.getType()#">
			<cfcase value="date">
				<cfqueryparam value="#arguments.propertyValue#" cfsqltype="cf_sql_timestamp">
			</cfcase>
			<cfcase value="numeric">
				<cfqueryparam value="#arguments.propertyValue#" cfsqltype="cf_sql_float">
			</cfcase>
			<cfcase value="boolean">
				<cfqueryparam value="#arguments.propertyValue#" cfsqltype="cf_sql_bit">
			</cfcase>
			<cfdefaultcase>
				<cfqueryparam value="#arguments.propertyValue#" cfsqltype="cf_sql_varchar">
			</cfdefaultcase>
		</cfswitch>

		#writeOrderBySQL(object, arguments.orderProperty, arguments.orderASC)#
	</cfquery>
	<cfreturn qQuery>
</cffunction>

<cffunction name="listByPropertyMap" hint="Lists values, filtered by a Struct of Property : Value properties" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="propertyMap" hint="Struct with keys that match to properties, and values to filter by" type="struct" required="Yes">
	<cfargument name="onlyRetrievePrimaryKey" hint="boolean to whether or not to only retrieve the primary key" type="boolean" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="No" default="">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="No" default="true">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="no" default="true">

	<cfscript>
		var object = getObjectManager().getObject(arguments.className);
		var iterator = 0;
		var qQuery = 0;
		var filterProperty = 0;
		var key = 0;
		var propertyValue = 0;

		arguments.propertyMap = cleanStruct(arguments.propertyMap);
		iterator = StructKeyArray(arguments.propertyMap).iterator();
	</cfscript>

	<cfquery name="qQuery" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
		#writeSelectFromSQL(object, arguments.onlyRetrievePrimaryKey, arguments.useAliases)#


		<cfif NOT StructIsEmpty(propertyMap)>
			where

			<cfloop condition="#iterator.hasNext()#">
				<cfset key = iterator.next()>
				<cfset filterProperty = object.getPropertyByName(key)>
				<cfset propertyValue = arguments.propertyMap[key]>

				#filterProperty.getColumn()# =
				<cfswitch expression="#filterProperty.getType()#">
					<cfcase value="date">
						<cfqueryparam value="#propertyValue#" cfsqltype="cf_sql_date">
					</cfcase>
					<cfcase value="numeric">
						<cfqueryparam value="#propertyValue#" cfsqltype="cf_sql_float">
					</cfcase>
					<cfcase value="boolean">
						<cfqueryparam value="#propertyValue#" cfsqltype="cf_sql_bit">
					</cfcase>
					<cfdefaultcase>
						<cfqueryparam value="#propertyValue#" cfsqltype="cf_sql_varchar">
					</cfdefaultcase>
				</cfswitch>

				<cfif iterator.hasNext()>
					AND
				</cfif>

			</cfloop>

		</cfif>

		#writeOrderBySQL(object, arguments.orderProperty, arguments.orderASC)#
	</cfquery>
	<cfreturn qQuery>

</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="cleanStruct" hint="Removes unwanted struct key with null values"  access="private" returntype="struct" output="false">
    <cfargument name="struct" type="struct" required="true">
    <cfset var key = "">
    <cfset var clean = structNew()>
    <cfloop collection="#arguments.struct#" item="key">
        <cfif structKeyExists(arguments.struct,key)>
            <cfset clean[key] = arguments.struct[key]>
        </cfif>
    </cfloop>
    <cfreturn clean>
</cffunction>

<cffunction name="writeSelectFromSQL" hint="Writes the select and from SQL" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The object to be listing" type="transfer.com.object.Object" required="Yes">
	<cfargument name="onlyRetrievePrimaryKey" hint="boolean to whether or not to only retrieve the primary key" type="boolean" required="Yes">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="Yes">
	<cfscript>
		var key = arguments.object.getClassName() & ":" & arguments.onlyRetrievePrimaryKey & ":" & arguments.useAliases;
		var cache = getSelectSQLCache();

		if(NOT StructKeyExists(cache, key))
		{
			cache[key] = buildSelectFromSQL(argumentCollection=arguments);
		}

		return cache[key];
	</cfscript>
</cffunction>

<cffunction name="buildSelectFromSQL" hint="Writes the select and from SQL" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The object to be listing" type="transfer.com.object.Object" required="Yes">
	<cfargument name="onlyRetrievePrimaryKey" hint="boolean to whether or not to only retrieve the primary key" type="boolean" required="Yes">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="Yes">
	<cfscript>
		//create me a string buffer for performance
		var buffer = createObject("java", "java.lang.StringBuffer").init("select ");
		var iterator = 0;
		var property = 0;
		var parentOneToMany = 0;
		var manytoone = 0;
		var isFirst = true;
		var primaryKey = arguments.object.getPrimaryKey();
	</cfscript>

	<cfif NOT arguments.onlyRetrievePrimaryKey>
		<cfscript>
			iterator = arguments.object.getPropertyIterator();

			while(iterator.hasNext())
			{
				property = iterator.next();

				if(NOT isFirst)
				{
					buffer.append(", ");
				}
				isFirst = false;

				buffer.append(property.getColumn());

				if(arguments.useAliases AND (property.getColumn() neq property.getName()))
				{
					buffer.append(" as ");
					buffer.append(property.getName());
				}
			}
		</cfscript>
	</cfif>

	<cfscript>
		if(NOT primaryKey.getIsComposite())
		{
			if(NOT isFirst)
			{
				buffer.append(", ");
			}

			buffer.append(primaryKey.getColumn());
			if(arguments.useAliases AND (primaryKey.getColumn() neq primaryKey.getName()))
			{
				buffer.append(" as ");
				buffer.append(primaryKey.getName());
			}
		}
		else if(arguments.onlyRetrievePrimaryKey) //retrieve primary key AND is composite, for read() ops
		{
			iterator = primaryKey.getPropertyIterator();

			while(iterator.hasNext())
			{
				property = iterator.next();
				if(NOT isFirst)
				{
					buffer.append(", ");
				}
				isFirst = false;

				//we know this is only for read() ops, so no need to alias
				buffer.append(property.getColumn());
			}

			iterator = primaryKey.getManyToOneIterator();

			while(iterator.hasNext())
			{
				manytoone = iterator.next();
				if(NOT isFirst)
				{
					buffer.append(", ");
				}
				isFirst = false;

				//we know this is only for read() ops, so no need to alias
				buffer.append(manytoone.getLink().getColumn());
			}

			iterator = primaryKey.getParentOneToManyIterator();

			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();
				if(NOT isFirst)
				{
					buffer.append(", ");
				}
				isFirst = false;

				//we know this is only for read() ops, so no need to alias
				buffer.append(parentOneToMany.getLink().getColumn());
			}
		}

		buffer.append(" from ");
		buffer.append(arguments.object.getTable());

		return buffer.toString();
	</cfscript>
</cffunction>

<cffunction name="writeOrderBySQL" hint="Writes the order by SQL" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The object the properties are read from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="Yes">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="Yes">

	<cfscript>
		var buffer = createObject("java", "java.lang.StringBuffer").init("");
		if(Len(arguments.orderProperty))
		{
			buffer.append("order by ");
			buffer.append(arguments.object.getPropertyByName(arguments.orderProperty).getColumn());
			if(arguments.orderASC)
			{
				buffer.append(" ASC");
			}
			else
			{
				buffer.append(" DESC");
			}
		}
		return buffer.toString();
	</cfscript>
</cffunction>

<cffunction name="getDatasource" access="private" returntype="Datasource" output="false">
	<cfreturn instance.Datasource />
</cffunction>

<cffunction name="setDatasource" access="private" returntype="void" output="false">
	<cfargument name="Datasource" type="Datasource" required="true">
	<cfset instance.Datasource = arguments.Datasource />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getSelectSQLCache" access="private" returntype="struct" output="false">
	<cfreturn instance.selectSQLCache />
</cffunction>

<cffunction name="setSelectSQLCache" access="private" returntype="void" output="false">
	<cfargument name="selectSQLCache" type="struct" required="true">
	<cfset instance.selectSQLCache = arguments.selectSQLCache />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>