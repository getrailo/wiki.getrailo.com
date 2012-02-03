<!--- Document Information -----------------------------------------------------

Title:      MementoBuilder.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Builder for creating memento structs from queries

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		18/04/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="MementoBuilder" hint="Builder for creating memento structs from queries">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="MementoBuilder" output="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes">
	<cfargument name="query" hint="The query the memento has been built off" type="query" required="Yes">
	<cfargument name="javaLoader" hint="The java loader for the memento class" type="any" required="Yes">
	<cfscript>
		setObjectManager(arguments.objectManager);
		setQuery(arguments.query);
		setJavaLoader(arguments.javaLoader);

		setMementoCollection(StructNew());
		setParentCompositePaths(StructNew());
		setCompositePathCache(StructNew());

		return this;
	</cfscript>
</cffunction>

<cffunction name="add" hint="Add a set of memento values to the collection" access="public" returntype="void" output="false">
	<cfargument name="compositeName" hint="The name of the composite" type="string" required="Yes">
	<cfargument name="key" hint="The primary key value of this object" type="string" required="Yes">
	<cfargument name="className" hint="The classname of the object" type="string" required="Yes">
	<cfargument name="isArray" hint="If the collection from here is an array or not" type="boolean" required="Yes">
	<cfargument name="structValue" hint="The struct of values for this part of the memento" type="struct" required="Yes">
	<cfargument name="parentClassName" hint="The classname of the parent of this object" type="string" required="Yes">
	<cfargument name="parentKey" hint="The primary key of the parent of this object" type="string" required="Yes">
	<cfargument name="parentCompositeName" hint="The parent composite name" type="string" required="Yes">
	<cfargument name="parentParentClassName" hint="The 2nd level parent composite name" type="string" required="Yes">

	<cfscript>
		var memento = 0;
		var parent = 0;

		if(hasInCollection(arguments.className, arguments.key))
		{
			memento = getFromCollection(arguments.className, arguments.key);
		}
		else
		{
			//memento = createObject("component", "transfer.com.dynamic.Memento").init(arguments.structValue);
			memento = getJavaLoader().create("com.compoundtheory.dynamic.Memento").init(arguments.structValue);
			addToCollection(className, arguments.key, memento);
		}

		if(hasMemento())
		{
			//if we're taking a different path to the same object, ignore it
			if(validateParentCompositePath(arguments.parentClassName, arguments.parentKey, arguments.parentCompositeName, arguments.parentParentClassName))
			{
				//add it to it's parent
				parent = getFromCollection(arguments.parentClassName, arguments.parentKey);
				parent.addChild(arguments.compositeName, arguments.isArray, memento);
			}
		}
		else
		{
			//set the top level one, will only happen once
			setMemento(memento);
		}
	</cfscript>
</cffunction>

<cffunction name="getMementoStruct" hint="Returns the Struct value of the memento" access="public" returntype="struct" output="false">
	<cfreturn getMemento().getMemento()>
</cffunction>

<cffunction name="_dump">
	<cfargument name="s">
	<cfargument name="abort" default="true">
	<cfset var g = "">
		<cfdump var="#arguments.s#">
		<cfif arguments.abort>
		<cfabort>
		</cfif>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="validateParentCompositePath" hint="validates if the parent composite paths are the same as what has been followed before" access="private" returntype="boolean" output="false">
	<cfargument name="className" hint="the classname of the parent" type="string" required="Yes">
	<cfargument name="key" hint="The primary key value" type="string" required="Yes">
	<cfargument name="compositeName" hint="The name of the composite" type="string" required="Yes">
	<cfargument name="parentClassName" hint="the parent class name" type="string" required="Yes">

	<cfscript>
		var compositePathKey = getCompositePathKey(arguments.className, arguments.key);
		var compositionPath = getCompositionPath(arguments.className, arguments.key, arguments.compositeName, arguments.parentClassName);

		if(NOT StructKeyExists(getParentCompositePaths(), compositePathKey))
		{
			StructInsert(getParentCompositePaths(),
						getCompositePathKey(arguments.className, arguments.key),
						compositionPath);

			return true;
		}
		else if(StructFind(getParentCompositePaths() , compositePathKey) eq compositionPath)
		{
			return true;
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="getCompositePathKey" hint="returns the key in a common fashion" access="private" returntype="string" output="false">
	<cfargument name="className" hint="the classname of the parent" type="string" required="Yes">
	<cfargument name="key" hint="The primary key value" type="string" required="Yes">

	<cfreturn arguments.className & "|" & arguments.key>
</cffunction>

<cffunction name="getCompositionPath" hint="if it has the composition path, returns is, otherwise builds it" access="private" returntype="string" output="false">
	<cfargument name="className" hint="the classname of the parent" type="string" required="Yes">
	<cfargument name="key" hint="The primary key value" type="string" required="Yes">
	<cfargument name="compositeName" hint="The name of the composite" type="string" required="Yes">
	<cfargument name="parentClassName" hint="the parent class name" type="string" required="Yes">
	<cfscript>
		var compositePath = 0;

		if(hasInCompositePathCache(arguments.className, arguments.key, arguments.compositeName, arguments.parentClassName))
		{
			compositePath = getFromCompositePathCache(arguments.className, arguments.key, arguments.compositeName, arguments.parentClassName);
		}
		else
		{
			compositePath = buildCompositePath(arguments.className, arguments.key, arguments.compositeName, arguments.parentClassName);
			addToCompositePathCache(arguments.className, arguments.key, arguments.compositeName, arguments.parentClassName, compositePath);
		}

		return compositePath;
	</cfscript>
</cffunction>

<cffunction name="buildCompositePath" hint="Builds the composite path by traversing the tree from the bottom up" access="private" returntype="string" output="false">
	<cfargument name="className" hint="the classname of the parent" type="string" required="Yes">
	<cfargument name="key" hint="The primary key value" type="string" required="Yes">
	<cfargument name="compositeName" hint="The name of the composite" type="string" required="Yes">
	<cfargument name="parentClassName" hint="the parent class name" type="string" required="Yes">
	<cfargument name="compositeKey" hint="The current composite key" type="string" required="no" default="">

	<cfscript>
		var qComposite = 0;
		var object = getObjectManager().getObject(arguments.className);
		var subKey = 0;
		var qSource = getQuery();
		var type = object.getPrimaryKey().getType();
	</cfscript>

	<cfquery name="qComposite" dbtype="query" debug="false">
		select
			transfer_parentClassName,
			transfer_parentKey,
			transfer_parentCompositeName,
			transfer_parentParentClassName
		from
			qSource
		where
			transfer_className = <cfqueryparam value="#arguments.className#" cfsqltype="cf_sql_varchar">
			and
			transfer_compositeName = <cfqueryparam value="#arguments.compositeName#" cfsqltype="cf_sql_varchar">
			and
			transfer_parentClassName = <cfqueryparam value="#arguments.parentClassName#" cfsqltype="cf_sql_varchar">
			and
			#object.getPrimaryKey().getColumn()# =
			<cfif type eq "numeric">
				<cfqueryparam value="#arguments.key#" cfsqltype="cf_sql_float">
			<cfelseif type eq "date">
				<cfqueryparam value="#arguments.key#" cfsqltype="cf_sql_timestamp">
			<cfelseif type eq "boolean">
				<cfqueryparam value="#arguments.key#" cfsqltype="cf_sql_bit">
			<cfelse>
				<cfqueryparam value="#arguments.key#" cfsqltype="cf_sql_varchar">
			</cfif>
	</cfquery>

	<cfscript>
		subKey = arguments.className & "|" & arguments.key & "|" & arguments.compositeName & "|" & arguments.parentClassName;
		subKey = ListAppend(arguments.compositeKey, subKey, ":");

		if(Len(qComposite.transfer_parentClassName))
		{

			return buildCompositePath(qComposite.transfer_parentClassName,
										qComposite.transfer_parentKey,
										qComposite.transfer_parentCompositeName,
										qComposite.transfer_parentParentClassName,
										subKey);
		}
		else
		{
			return subkey;
		}
	</cfscript>
</cffunction>

<cffunction name="getParentCompositePaths" access="private" returntype="struct" output="false">
	<cfreturn instance.ParentCompositePaths />
</cffunction>

<cffunction name="setParentCompositePaths" access="private" returntype="void" output="false">
	<cfargument name="ParentCompositePaths" type="struct" required="true">
	<cfset instance.ParentCompositePaths = arguments.ParentCompositePaths />
</cffunction>

<cffunction name="getQuery" access="private" returntype="query" output="false">
	<cfreturn instance.Query />
</cffunction>

<cffunction name="setQuery" access="private" returntype="void" output="false">
	<cfargument name="Query" type="query" required="true">
	<cfset instance.Query = arguments.Query />
</cffunction>

<cffunction name="getMemento" access="private" returntype="any" output="false">
	<cfreturn instance.memento />
</cffunction>

<cffunction name="setMemento" access="private" returntype="void" output="false">
	<cfargument name="Memento" type="any" required="true">
	<cfset instance.memento = arguments.Memento />
</cffunction>

<cffunction name="hasMemento" hint="If there is a top level memento set" access="private" returntype="boolean" output="false">
	<cfreturn StructKeyExists(instance, "memento")>
</cffunction>

<cffunction name="getMementoCollection" access="private" returntype="struct" output="false">
	<cfreturn instance.MementoCollection />
</cffunction>

<cffunction name="setMementoCollection" access="private" returntype="void" output="false">
	<cfargument name="MementoCollection" type="struct" required="true">
	<cfset instance.MementoCollection = arguments.MementoCollection />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="addToCollection" hint="Adds the memento to the collection" access="private" returntype="void" output="false">
	<cfargument name="className" hint="The classname for the memento" type="string" required="Yes">
	<cfargument name="key" hint="The key value" type="string" required="Yes">
	<cfargument name="memento" hint="The memento object to add" type="any" required="Yes">

	<cfscript>
		StructInsert(getMementoCollection(), arguments.className & ":" & arguments.key, arguments.memento);
	</cfscript>
</cffunction>

<cffunction name="hasInCollection" hint="checks to see if the memento is already in the collection" access="private" returntype="boolean" output="false">
	<cfargument name="className" hint="The classname for the memento" type="string" required="Yes">
	<cfargument name="key" hint="The key value" type="string" required="Yes">
	<cfreturn StructKeyExists(getMementoCollection(), arguments.className & ":" & arguments.key)>
</cffunction>

<cffunction name="getFromCollection" hint="Retrieves a Memento object from the collection" access="private" returntype="any" output="false">
	<cfargument name="className" hint="The classname for the memento" type="string" required="Yes">
	<cfargument name="key" hint="The key value" type="string" required="Yes">
	<cfscript>
		return StructFind(getMementoCollection(), arguments.className & ":" & arguments.key);
	</cfscript>
</cffunction>

<cffunction name="addToCompositePathCache" hint="Adds the memento to the collection" access="private" returntype="void" output="false">
	<cfargument name="className" hint="the classname of the parent" type="string" required="Yes">
	<cfargument name="key" hint="The primary key value" type="string" required="Yes">
	<cfargument name="compositeName" hint="The name of the composite" type="string" required="Yes">
	<cfargument name="parentClassName" hint="the parent class name" type="string" required="Yes">
	<cfargument name="compositePathKey" hint="The composite path key" type="string" required="Yes">
	<cfscript>
		StructInsert(getCompositePathCache(), arguments.className & "|"  & arguments.key & "|" & arguments.compositeName & "|" & arguments.parentClassName, arguments.compositePathKey);
	</cfscript>
</cffunction>

<cffunction name="hasInCompositePathCache" hint="checks to see if the memento is already in the collection" access="private" returntype="boolean" output="false">
	<cfargument name="className" hint="the classname of the parent" type="string" required="Yes">
	<cfargument name="key" hint="The primary key value" type="string" required="Yes">
	<cfargument name="compositeName" hint="The name of the composite" type="string" required="Yes">
	<cfargument name="parentClassName" hint="the parent class name" type="string" required="Yes">
	<cfreturn StructKeyExists(getCompositePathCache(), arguments.className & "|"  & arguments.key & "|" & arguments.compositeName & "|" & arguments.parentClassName)>
</cffunction>

<cffunction name="getFromCompositePathCache" hint="Retrieves a Memento object from the collection" access="private" returntype="string" output="false">
	<cfargument name="className" hint="the classname of the parent" type="string" required="Yes">
	<cfargument name="key" hint="The primary key value" type="string" required="Yes">
	<cfargument name="compositeName" hint="The name of the composite" type="string" required="Yes">
	<cfargument name="parentClassName" hint="the parent class name" type="string" required="Yes">
	<cfscript>
		return StructFind(getCompositePathCache(), arguments.className & "|"  & arguments.key & "|" & arguments.compositeName & "|" & arguments.parentClassName);
	</cfscript>
</cffunction>

<cffunction name="getCompositePathCache" access="private" returntype="struct" output="false">
	<cfreturn instance.CompositePathCache />
</cffunction>

<cffunction name="setCompositePathCache" access="private" returntype="void" output="false">
	<cfargument name="CompositePathCache" type="struct" required="true">
	<cfset instance.CompositePathCache = arguments.CompositePathCache />
</cffunction>

<cffunction name="getJavaLoader" access="private" returntype="transfer.com.util.JavaLoader" output="false">
	<cfreturn instance.JavaLoader />
</cffunction>

<cffunction name="setJavaLoader" access="private" returntype="void" output="false">
	<cfargument name="JavaLoader" type="transfer.com.util.JavaLoader" required="true">
	<cfset instance.JavaLoader = arguments.JavaLoader />
</cffunction>

</cfcomponent>