<!--- Document Information -----------------------------------------------------

Title:      TransferSelecter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Selects the data for a Transfer Object

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		09/08/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Selects the data for a Transfer Object" extends="AbstractBaseTransfer" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransferSelecter" output="false">
	<cfargument name="datasource" hint="The datasource BO" type="transfer.com.sql.Datasource" required="Yes" _autocreate="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="tQLConverter" hint="Converter for {property} statements" type="transfer.com.sql.TQLConverter" required="Yes">
	<cfargument name="queryExecutionPool" hint="the query execution pool" type="transfer.com.sql.collections.QueryExecutionPool" required="Yes">
	<cfargument name="queryCache" hint="the query object cache" type="transfer.com.sql.collections.QueryCache" required="Yes">
	<cfargument name="transaction" type="transfer.com.sql.transaction.Transaction" required="true" _autocreate="false">
	<cfscript>
		super.init(argumentCollection=arguments);

		setTQLConverter(arguments.tQLConverter);

		return this;
	</cfscript>
</cffunction>

<cffunction name="select" hint="read the object data from the DB, and return it" access="public" returntype="query" output="false">
	<cfargument name="object" hint="The Object BO" type="transfer.com.object.Object" required="Yes">
	<cfargument name="key" hint="The id key for the data" type="any" required="Yes">
	<cfargument name="lazyLoadName" hint="the name of the lazy load, if there is one, for locking and caching" type="string" required="No">
	<cfscript>
		var query = buildSelectSQL(argumentCollection=arguments);
		var queryExec = query.createExecution();
		var qResult = 0;

		setPrimaryKey(queryExec=queryExec, object=arguments.object, key=arguments.key);

		qResult = queryExec.executeQuery();

		getQueryExecutionPool().recycle(queryExec);

		return qResult;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="buildSelectSQL" hint="Creates the SQL for the Object BO" access="private" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="object" hint="The Object BO" type="transfer.com.object.Object" required="Yes">
	<cfargument name="lazyLoadName" hint="the name of the lazy load, if there is one, for locking and caching" type="string" required="No">
	<cfscript>
		var key = "transfer.select." & arguments.object.getClassName();
		var fromSQL = 0;
		var columnStruct = 0;
		var query = 0;

		if(structKeyExists(arguments, "lazyLoadName"))
		{
			key = key & "." & arguments.lazyLoadName;
		}
	</cfscript>

	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT getQueryCache().hasQuery(key))
			{
				columnStruct = buildColumnStruct(arguments.object, structKeyExists(arguments, "lazyLoadName")); //meta data for the tables and columns

				fromSQL = buildInitialFromSQL(arguments.object); //create the from sql

				//var whereSQL = buildWhere(arguments.object); //where clause

				query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());

				query.start();

				//put it all together
				query = buildSQL(arguments.object, query, columnStruct, fromSQL);

				query.stop();

				getQueryCache().addQuery(key, query);
			}
		</cfscript>
		</cflock>
	</cfif>

	<cfreturn getQueryCache().getQuery(key) />
</cffunction>

<cffunction name="buildColumnStruct" hint="Builds an struct with a key on table, with an array inside of each column, with type and column" access="private" returntype="struct" output="false">
	<cfargument name="object" hint="The BO of the object to build the list to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="lazyLoaded" hint="if the SQL is for a lazy populate" type="boolean" required="No" default="false">
	<cfargument name="columnStruct" hint="Struct of Arrays defining tables and their columns" type="struct" required="No" default="#StructNew()#">
	<cfargument name="visitedClasses" hint="Array of class names that have been visited" type="array" required="No" default="#arrayNew(1)#">
	<cfargument name="compositionName" hint="The name of the composition" type="string" required="no" default="">
	<cfargument name="proxied" hint="whether or not the data is being proxied" type="boolean" required="No" default="false">

	<cfscript>
		var iterator = arguments.object.getPropertyIterator();
		var property = 0;
		var manytomany = 0;
		var manytoone = 0;
		var onetomany = 0;
		var parentOneToMany = 0;
		var primaryKey = arguments.object.getPrimaryKey();
		var composite = 0;
		var args = 0;

		//if we have visited here before, return the columnArray
		if(arguments.visitedClasses.contains(arguments.object.getClassName() & ":" & arguments.compositionName))
		{
			/*
				Throw an exception at this point to
				show that lazy loading should be used,
				so as tables don't refer back to themselves
			*/
			throw("transfer.RecursiveCompositionException",
				"The structure of your configuration file causes an infinite loop",
				"The object '#arguments.object.getClassName()#' has a recursive link back to itself through composition '#arguments.compositionName#'.
				You will need to set one of the elements in this chain to lazy='true' for it to work.");
		}

		//add in this object as visited
		arrayAppend(arguments.visitedClasses, arguments.object.getClassName() & ":" & arguments.compositionName);

		//list properties
		if(NOT StructKeyExists(arguments.columnStruct, arguments.object.getTable()))
		{
			arguments.columnStruct[arguments.object.getTable()] = ArrayNew(1);
		}

		//add in the primary key, even if it's composite, as we will add it later
		if(NOT primaryKey.getIsComposite())
		{
			ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(primaryKey));
		}
		else if(arguments.lazyLoaded)
		{
			appendCompositeKeyForeignKeys(arguments.object, arguments.columnStruct);
		}

		//if proxied, we don't need anything else underneath it
		if(arguments.proxied)
		{
			appendProxiedColumns(arguments.columnstruct, arguments.object);

			return arguments.columnStruct;
		}

		//add properties
		while(iterator.hasNext())
		{
			property = iterator.next();
			ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(property));
		}

		//do external one to many links
		iterator = arguments.object.getParentOneToManyIterator();
		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			composite = getObjectManager().getObject(parentOneToMany.getLink().getTo());

			ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(composite.getPrimaryKey(), parentOneToMany.getLink().getColumn()));
		}

		//now follow out many to one
		iterator = arguments.object.getManyToOneIterator();
		while(iterator.hasNext())
		{
			manytoone = iterator.next();

			//if the id is composite, and it contains this manytoone as a composite element, add it to the selected list
			//so that we can use it to generate the key to store this TransferObject under.
			if(primaryKey.getIsComposite() AND primaryKey.containsManyToOneByName(manytoone.getName()))
			{
				composite = getObjectManager().getObject(manytoone.getLink().getTo());

				ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(composite.getPrimaryKey(), manytoone.getLink().getColumn()));
			}

			if(NOT manytoone.getIsLazy())
			{
				//punch it out to the next object
				buildColumnStruct(manytoone.getLink().getToObject(), false, arguments.columnStruct, arguments.visitedClasses, manytoone.getName(), manytoone.getIsProxied());
			}
		}

		//now follow out many to many's
		iterator = arguments.object.getManyToManyIterator();
		while(iterator.hasNext())
		{
			manytomany = iterator.next();

			if(NOT manytomany.getIsLazy())
			{
				args = StructNew();
				args.object = manytomany.getLinkTo().getToObject();
				args.columnStruct = arguments.columnStruct;
				args.visitedClasses = arguments.visitedClasses;
				args.compositionName = manytomany.getName();
				args.proxied = manytomany.getIsProxied();

				//punch it out to the next object
				buildColumnStruct(argumentCollection=args);
			}
		}

		//now follow out to one to many's
		iterator = arguments.object.getOneToManyIterator();
		while(iterator.hasNext())
		{
			onetomany = iterator.next();

			if(NOT onetomany.getIsLazy())
			{
				args = StructNew();
				args.object = onetomany.getLink().getToObject();
				args.columnStruct = arguments.columnStruct;
				args.visitedClasses = arguments.visitedClasses;
				args.compositionName = onetomany.getName();
				args.proxied = onetomany.getIsProxied();

				//punch it out to the next object
				buildColumnStruct(argumentCollection=args);
			}
		}

		return arguments.columnStruct;
	</cfscript>
</cffunction>

<cffunction name="appendCompositeKeyForeignKeys" hint="appending composite foreign keys to the object, particularly for lazy loading" access="private" returntype="void" output="false">
	<cfargument name="object" hint="The BO of the object to build the list to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="columnStruct" hint="Struct of Arrays defining tables and their columns" type="struct" required="Yes">
	<cfscript>
		var manyToOne = 0;
		var parentOneToMany = 0;
		var primaryKey = arguments.object.getPrimaryKey();
		var iterator = primaryKey.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();

			if(NOT arguments.object.containsManyToOne(manytoone.getName()))
			{
				ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(manytoone.getLink().getToObject().getPrimaryKey(), manytoone.getLink().getColumn()));
			}
		}

		iterator = primaryKey.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			if(NOT arguments.object.containsParentOneToMany(parentOneToMany.getLink().getTo()))
			{
				ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(parentOneToMany.getLink().getToObject().getPrimaryKey(), parentOneToMany.getLink().getColumn()));
			}
		}
	</cfscript>
</cffunction>

<cffunction name="appendProxiedColumns" hint="add the columns we need for proxied collections for ordering and struct values, and composite keys" access="private" returntype="void" output="false">
	<cfargument name="columnStruct" hint="Struct of Arrays defining tables and their columns" type="struct" required="Yes">
	<cfargument name="object" hint="The BO of the object to build the list to" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var iterator = arguments.object.getParentOneToManyIterator();
		var parentOneToMany = 0;
		var parentManyToMany = 0;
		var propertyName = 0;
		var property = 0;
		var manytoone = 0;
		var	addedProperties = StructNew();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			propertyName = appendCollectionColumn(arguments.columnStruct, arguments.object, parentOneToMany.getCollection());

			addedProperties[propertyName] = 1;
		}

		iterator = arguments.object.getParentManyToManyIterator();

		while(iterator.hasNext())
		{
			parentManyToMany = iterator.next();

			propertyName = appendCollectionColumn(arguments.columnStruct, arguments.object, parentManyToMany.getCollection());

			addedProperties[propertyName] = 1;
		}

		//add in composite key, if there is one
		if(arguments.object.getPrimarykey().getIsComposite())
		{
			iterator = arguments.object.getPrimaryKey().getPropertyIterator();

			while(iterator.hasNext())
			{
				property = iterator.next();
				if(NOT StructKeyExists(addedProperties, property.getName()))
				{
					ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(property));
				}
			}

			iterator = arguments.object.getPrimaryKey().getManyToOneIterator();

			while(iterator.hasNext())
			{
				manytoone = iterator.next();

				ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(manytoone.getLink().getToObject().getPrimaryKey(), manytoone.getLink().getColumn()));
			}

			iterator = arguments.object.getPrimaryKey().getParentOneToManyIterator();

			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();

				ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(parentOneToMany.getLink().getToObject().getPrimaryKey(), parentOneToMany.getLink().getColumn()));
			}
		}
	</cfscript>
</cffunction>

<cffunction name="appendCollectionColumn" hint="appends a collection column if it has a key or an order. returns the property name, if one is added, otherwise return ''"
			access="private" returntype="string" output="false">
	<cfargument name="columnStruct" hint="Struct of Arrays defining tables and their columns" type="struct" required="Yes">
	<cfargument name="object" hint="The BO of the object to build the list to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="collection" hint="the collection meta data" type="transfer.com.object.Collection" required="Yes">
	<cfscript>
		var property = 0;

		if(arguments.collection.hasKey())
		{
			property = arguments.object.getPropertyByName(arguments.collection.getKey().getProperty());
		}
		else if(arguments.collection.hasOrder())
		{
			property = arguments.object.getPropertyByName(arguments.collection.getOrder().getProperty());
		}

		if(isObject(property))
		{
			ArrayAppend(arguments.columnStruct[arguments.object.getTable()], createColumnMeta(property));
			return property.getName();
		}

		return "";
	</cfscript>
</cffunction>


<cffunction name="setRequiredProperty" hint="sets the required property argument" access="private" returntype="void" output="false">
	<cfargument name="args" hint="the argument collection" type="struct" required="Yes">
	<cfargument name="isProxied" hint="whether or not the composition is proxied" type="boolean" required="Yes">
	<cfargument name="collection" hint="the collection to look at" type="transfer.com.object.Collection" required="Yes">
	<cfscript>
		if(arguments.isProxied)
		{
			if(arguments.collection.hasKey())
			{
				arguments.args.requiredProperty = arguments.collection.getKey().getProperty();
			}
			else if(arguments.collection.hasOrder())
			{
				arguments.args.requiredProperty = arguments.collection.getOrder().getProperty();
			}
		}
	</cfscript>
</cffunction>

<cffunction name="containsCompositeID" hint="do I have a composite id inside the object" access="private" returntype="boolean" output="false">
	<cfargument name="object" hint="The BO of the object to build the list to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="visitedClasses" hint="Array of class names that have been visited" type="array" required="No" default="#arrayNew(1)#">
	<cfscript>
		var iterator = 0;
		var manytomany = 0;
		var manytoone = 0;
		var onetomany = 0;
		var composite = 0;
		var primaryKey = arguments.object.getPrimaryKey();

		//if we have visited here before, return false
		if(arguments.visitedClasses.contains(arguments.object.getClassName()))
		{
			return false;
		}

		//add in this object as visited
		arrayAppend(arguments.visitedClasses, arguments.object.getClassName());

		//add in the primary key, even if it's composite, as we will add it later
		if(primaryKey.getIsComposite())
		{
			return true;
		}

		//now follow out many to one
		iterator = arguments.object.getManyToOneIterator();
		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			composite = getObjectManager().getObject(manytoone.getLink().getTo());

			if(containsCompositeID(composite, visitedClasses))
			{
				return true;
			}
		}

		//now follow out many to many's
		iterator = arguments.object.getManyToManyIterator();
		while(iterator.hasNext())
		{
			manytomany = iterator.next();
			if(manytomany.getLinkFrom().getTo() eq arguments.object.getClassName())
			{
				composite = getObjectManager().getObject(manytomany.getLinkFrom().getTo());
			}
			else
			{
				composite = getObjectManager().getObject(manytomany.getLinkTo().getTo());
			}

			if(containsCompositeID(composite, visitedClasses))
			{
				return true;
			}
		}

		//now follow out to one to many's
		iterator = arguments.object.getOneToManyIterator();
		while(iterator.hasNext())
		{
			onetomany = iterator.next();

			composite = getObjectManager().getObject(onetomany.getLink().getTo());

			if(containsCompositeID(composite, visitedClasses))
			{
				return true;
			}
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="createColumnMeta" hint="Builds the Column meta data. Struct returned with column name (column), and type (type)" access="private" returntype="struct" output="false">
	<cfargument name="property" hint="The property to get the type from" type="transfer.com.object.Property" required="Yes">
	<cfargument name="column" hint="The column to set" type="string" required="No" default="#arguments.property.getColumn()#">
	<cfscript>
		var part = StructNew();
		part.column = arguments.column;
		part.type = arguments.property.getType();

		return part;
	</cfscript>
</cffunction>

<cffunction name="buildInitialFromSQL" hint="Builds the initial from SQL" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The BO of the object to build FROM from" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		//we know it's 1
		return arguments.object.getTable() & " " & createTableName(arguments.object, 1);
	</cfscript>
</cffunction>

<cffunction name="buildSQL" hint="Builds the SQL via a stringBuffer" access="private" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="object" hint="The BO of the object to build the list to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="query" hint="the query object" type="transfer.com.sql.Query" required="Yes">
	<cfargument name="columnStruct" hint="Struct of Arrays that defines tables and columns" type="struct" required="Yes">
	<cfargument name="fromSQL" hint="String that contains the from statement" type="string" required="Yes">
	<cfargument name="whereSQL" hint="The WHERE clause of the SQL" type="string" required="no" default="">
	<cfargument name="originalObject" hint="the original object being searched for" type="transfer.com.object.Object" required="no" default="#arguments.object#">
	<cfargument name="parentCompositeName" hint="The paren't composite name" type="string" required="no" default="">
	<cfargument name="parentObject" hint="The parent object to set the item to" type="transfer.com.object.Object" required="No" default="#arguments.object#">
	<cfargument name="parentParentClass" hint="parent class 2 levels up" type="string" required="no" default="">
	<cfargument name="visitedClasses" hint="Array of class names that have been visited" type="array" required="No" default="#arrayNew(1)#">
	<cfargument name="orderIndex" hint="The order index of this select" type="numeric" required="No" default="1">
	<cfargument name="compositeName" hint="The name of the composite structure" type="string" required="No" default="">
	<cfargument name="isArray" hint="is this memento part of an array?" type="boolean" required="No" default="false">
	<cfargument name="orderBuffer" hint="java.land.StringBuffer that tracks order by statement" type="any" required="no" default="#createObject('Java', 'java.lang.StringBuffer').init(' ORDER BY transfer_orderIndex ASC')#">
	<cfargument name="hasCompositeID" hint="whether there is a composite id in the tree" type="boolean" required="No" default="#containsCompositeID(arguments.object)#">
	<cfargument name="isProxied" hint="whether or not it is proxied" type="boolean" required="No" default="false">

	<cfscript>
		var iterator = arguments.object.getPropertyIterator();
		var property = 0;
		var manytomany = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var onetomany = 0;
		var primaryKey = 0;
		var composite = 0;
		var parentClassName = "";
		var nextOrderIndex = arguments.orderIndex + 1;
		var where = 0;
		var isFirst = true;

		//if we have visited here before, return the columnArray
		if(arguments.visitedClasses.contains(arguments.compositeName & ":" & arguments.object.getClassName()))
		{
			return arguments.buffer;
		}

		//add in this object as visited
		arrayAppend(arguments.visitedClasses, arguments.compositeName & ":" & arguments.object.getClassName());

		//set up some values
		//if(arguments.parentObject.getClassName() neq arguments.object.getClassName())
		if(arguments.orderIndex neq 1)
		{
			parentClassName = arguments.parentObject.getClassName();

			//end with UNION ALL
			arguments.query.appendSQL(" UNION ALL ");
		}

		//start with SELECT
		arguments.query.appendSQL("SELECT ");

		buildSelect(arguments.query, arguments.object, arguments.parentObject, arguments.columnStruct, arguments.orderIndex, arguments.hasCompositeID);

		arguments.query.appendSQL(arguments.orderIndex & " as transfer_orderIndex,");
		arguments.query.appendSQL("'" & arguments.object.getClassName() & "' as transfer_className,");

		arguments.query.appendSQL("'" & parentClassName & "' as transfer_parentClassName,");

		arguments.query.appendSQL("'" & arguments.parentParentClass & "' as transfer_parentParentClassName,");

		arguments.query.appendSQL("'" & arguments.parentCompositeName & "' as transfer_parentCompositeName,");

		arguments.query.appendSQL("'" & arguments.isArray & "' as transfer_isArray,");

		arguments.query.appendSQL("'" & arguments.compositeName & "' as transfer_compositeName, ");
		arguments.query.appendSQL("'" & arguments.isProxied & "' as transfer_isProxied");

		//add from
		arguments.query.appendSQL(" FROM ");

		arguments.query.appendSQL(arguments.fromSQL);

		//WHERE
		arguments.query.appendSQL(" WHERE ");

		//we know it's 1, b/c it's the original
		mapPrimaryKey(query=arguments.query, object=arguments.originalObject, table=createTableName(arguments.originalObject, 1));

		primaryKey = arguments.object.getPrimaryKey();

		//if the primary key is not composite, remove all null references to it's rows.
		if(NOT primaryKey.getIsComposite())
		{
			arguments.query.appendSQL(" AND ");
			arguments.query.appendSQL(createTableName(arguments.object, arguments.orderIndex) & "." & primaryKey.getColumn() & " IS NOT NULL ");
		}

		if(Len(arguments.whereSQL))
		{
			arguments.query.appendSQL(" AND ");
			arguments.query.appendSQL(arguments.whereSQL);
		}

		/*
			if we are proxied, there is no reason to
			continue travelling down the graph
		*/
		if(arguments.isProxied)
		{
			return arguments.query;
		}

		//follow out out to many to ones
		iterator = arguments.object.getManyToOneIterator();
		while(iterator.hasNext())
		{
			manytoone = iterator.next();

			composite = getObjectManager().getObject(manytoone.getLink().getTo());

			if(NOT manytoone.getIsLazy())
			{

				//punch it out to the next object
				buildSQL(composite,
							arguments.query,
							arguments.columnStruct,
							buildManyToOneFromSQL(arguments.object, composite, manytoone,arguments.fromSQL, nextOrderIndex), //build from sql
							arguments.whereSQL,
							arguments.originalObject,
							arguments.compositeName,
							arguments.object,
							parentClassName,
							arguments.visitedClasses,
							nextOrderIndex,
							manytoone.getName(),
							false,
							arguments.orderBuffer,
							arguments.hasCompositeID,
							manytoone.getIsProxied()
							);
			}
		}

		//follow out the one to many
		iterator = arguments.object.getOneToManyIterator();
		while(iterator.hasNext())
		{
			onetomany = iterator.next();

			if(NOT onetomany.getIsLazy())
			{
				composite = getObjectManager().getObject(onetomany.getLink().getTo());

				buildOrder(arguments.orderBuffer, onetoMany.getCollection(), composite);

				where = arguments.whereSQL;
				if(onetomany.getCollection().hasCondition())
				{
					where = buildConditionSQL(composite, onetomany.getCollection().getCondition(), nextOrderIndex);
					if(Len(arguments.whereSQL))
					{
						where = where & " AND " & arguments.whereSQL;
					}
				}

				//punch it out to the next object
				buildSQL(composite,
							arguments.query,
							arguments.columnStruct,
							buildOneToManyFromSQL(arguments.object, composite, onetomany, arguments.fromSQL, nextOrderIndex), //build from sql
							where,
							arguments.originalObject,
							arguments.compositeName,
							arguments.object,
							parentClassName,
							arguments.visitedClasses,
							nextOrderIndex,
							onetomany.getName(),
							true,
							arguments.orderBuffer,
							arguments.hasCompositeID,
							onetomany.getIsProxied()
							);
			}

		}

		//now follow out many to many's
		iterator = arguments.object.getManyToManyIterator();
		while(iterator.hasNext())
		{
			manytomany = iterator.next();

			if(NOT manytomany.getIsLazy())
			{
				composite = getObjectManager().getObject(manytomany.getLinkTo().getTo());

				buildOrder(arguments.orderBuffer, manyToMany.getCollection(), composite);

				where = arguments.whereSQL;
				if(manytomany.getCollection().hasCondition())
				{
					where = buildConditionSQL(composite, manytomany.getCollection().getCondition(), nextOrderIndex);
					if(Len(arguments.whereSQL))
					{
						where = where & " AND " & arguments.whereSQL;
					}
				}

				//punch it out to the next object
				buildSQL(composite,
							arguments.query,
							arguments.columnStruct,
							buildManyToManyFromSQL(arguments.object, composite, manyToMany, arguments.fromSQL, nextOrderIndex), //build from sql
							where,
							arguments.originalObject,
							arguments.compositeName,
							arguments.object,
							parentClassName,
							arguments.visitedClasses,
							nextOrderIndex,
							manytomany.getName(),
							true,
							arguments.orderBuffer,
							arguments.hasCompositeID,
							manytomany.getIsProxied()
							);
			}
		}

		if(arguments.orderIndex eq 1) //is first, so will be added last
		{
			//drop off the last UNION ALL (9 chars)
			//arguments.buffer.delete(javaCast("int", arguments.buffer.length() - 10), arguments.buffer.length());

			//add the order by
			arguments.query.appendSQL(arguments.orderBuffer.toString());
		}

		return arguments.query;
	</cfscript>
</cffunction>

<cffunction name="buildSelect" hint="Builds the column list part of the SELECT for a given object" access="private" returntype="void" output="false">
	<cfargument name="query" hint="The sql query object" type="transfer.com.sql.Query" required="Yes">
	<cfargument name="object" hint="The BO of the object to build the list to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="parentObject" hint="The parent object to set the item to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="columnStruct" hint="Struct of Arrays defining the columns" type="struct" required="yes">
	<cfargument name="orderIndex" hint="The order index of this select" type="numeric" required="Yes">
	<cfargument name="hasCompositeID" hint="if it has a composite id in the tree" type="boolean" required="Yes">
	<cfscript>
		//lets loop around the column Struct
		var table = 0;
		var column = 0;
		var flatColumnArray = flattenColumnStruct(arguments.columnStruct);

		var currentTableColumns = arguments.columnStruct[arguments.object.getTable()];
		var currentTableName = createTableName(arguments.object, arguments.orderIndex);

		var len = ArrayLen(flatColumnArray);
		var counter = 1;

		for(table in arguments.columnStruct)
		{
			for(; counter lte len; counter = counter + 1)
			{
				column = flatColumnArray[counter];

				if(tableContainsColumnName(currentTableColumns, column.column))
				{
					arguments.query.appendSQL(currentTableName & ".");
				}
				else
				{
					arguments.query.appendSQL(writeNULL(column.column, column.type) & " as ");
				}

				arguments.query.appendSQL(column.column & ", ");
			}
		}

		if(arguments.hasCompositeID)
		{
			//if there is a composite key, return the unique ident resolved, for memento building
			if(arguments.object.getPrimaryKey().getIsComposite())
			{
				arguments.query.appendSQL(buildCompositeKeyValue(currentTableName, arguments.object));
				arguments.query.appendSQL(" as transfer_compositeid,");
			}
			else
			{
				arguments.query.appendSQL("'' as transfer_compositeid,");
			}
		}

		//if(arguments.object.getClassName() neq arguments.parentObject.getClassName())
		if(arguments.orderIndex neq 1)
		{
			if(arguments.parentObject.getPrimaryKey().getIsComposite())
			{

				arguments.query.appendSQL(castValue(buildCompositeKeyValue(createTableName(arguments.parentObject, arguments.orderIndex -1), arguments.parentObject), "varchar"));
			}
			else
			{
				arguments.query.appendSQL(castValue(createTableName(arguments.parentObject, arguments.orderIndex -1) & "." & arguments.parentObject.getPrimaryKey().getColumn(), "varchar"));
			}

			arguments.query.appendSQL(" as transfer_parentKey");
		}
		else
		{
			arguments.query.appendSQL(writeNULL(arguments.parentObject.getPrimaryKey().getColumn(), "string"));
			arguments.query.appendSQL(" as transfer_parentKey");
		}
		arguments.query.appendSQL(", ");
	</cfscript>
</cffunction>

<cffunction name="tableContainsColumnName" hint="if the table contains this column" access="private" returntype="boolean" output="false">
	<cfargument name="table" hint="the table meta data" type="array" required="Yes">
	<cfargument name="column" hint="the name of the column" type="string" required="Yes">
	<cfscript>
		var len = ArrayLen(arguments.table);
		var counter = 1;
		var tableColumn = 0;

		for(; counter lte len; counter = counter + 1)
		{
			tableColumn = arguments.table[counter];

			if(tableColumn.column eq arguments.column)
			{
				return true;
			}
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="flattenColumnStruct" hint="returns a flat array of column names, without duplicates" access="private" returntype="array" output="false">
	<cfargument name="columnStruct" hint="Struct of Arrays defining the columns" type="struct" required="yes">
	<cfscript>
		var flatColumns = createObject("java","java.util.HashSet").init();
		var table = 0;

		for(table in arguments.columnStruct)
		{
			flatColumns.addAll( arguments.columnStruct[table] );
		}

		return flatColumns.toArray();
	</cfscript>
</cffunction>

<cffunction name="buildOneToManyFromSQL" hint="Builds the from SQL for a One to Many SQL" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The original object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="composite" hint="The composite object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="oneToMany" hint="The one to many connector" type="transfer.com.object.OneToMany" required="Yes">
	<cfargument name="fromSQL" hint="The from SQL already written" type="string" required="Yes">
	<cfargument name="orderIndex" hint="The order index of this select" type="numeric" required="Yes">

	<cfscript>
		var buffer = createObject("Java", "java.lang.StringBuffer").init(arguments.fromSQL);
		var compositeTable = createTableName(arguments.composite, arguments.orderIndex);
		var objectTable = createTableName(arguments.object, arguments.orderIndex - 1);

		buffer.append(" INNER JOIN " & arguments.composite.getTable() & " " & compositeTable);
		buffer.append(" ON " & objectTable & "." & arguments.object.getPrimaryKey().getColumn());
		buffer.append(" = " & compositeTable & "." & arguments.onetomany.getLink().getColumn());

		return buffer.toString();
	</cfscript>
</cffunction>

<cffunction name="buildManyToOneFromSQL" hint="Builds the from SQL for many to one composition" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The original object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="composite" hint="The composite object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="manyToOne" hint="The many to many connector" type="transfer.com.object.ManyToOne" required="Yes">
	<cfargument name="fromSQL" hint="The from SQL already written" type="string" required="Yes">
	<cfargument name="orderIndex" hint="The order index of this select" type="numeric" required="Yes">

	<cfscript>
		var buffer = createObject("Java", "java.lang.StringBuffer").init(arguments.fromSQL);
		var compositeTable = createTableName(arguments.composite, arguments.orderIndex);
		var objectTable = createTableName(arguments.object, arguments.orderIndex - 1);

		buffer.append(" INNER JOIN " & arguments.composite.getTable() & " " & compositeTable);
		buffer.append(" ON " & objectTable & "." & arguments.manyToOne.getLink().getColumn());
		buffer.append(" = " & compositeTable & "." & arguments.composite.getPrimaryKey().getColumn());

		return buffer.toString();
	</cfscript>
</cffunction>

<cffunction name="buildManyToManyFromSQL" hint="Builds the from SQL from a many to many composition" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The original object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="composite" hint="The composite object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="manyToMany" hint="The many to many connector" type="transfer.com.object.ManyToMany" required="Yes">
	<cfargument name="fromSQL" hint="The from SQL already written" type="string" required="Yes">
	<cfargument name="orderIndex" hint="The order index of this select" type="numeric" required="Yes">

	<cfscript>
		var buffer = createObject("Java", "java.lang.StringBuffer").init(arguments.fromSQL);
		var compositeTable = createTableName(arguments.composite, arguments.orderIndex);
		var objectTable = createTableName(arguments.object, arguments.orderIndex - 1);
		var manytomanyTable = createTableName(arguments.manytomany, arguments.orderIndex);

		//first part
		buffer.append(" INNER JOIN " & arguments.manytomany.getTable() & " " & manytomanyTable);
		buffer.append(" ON " & objectTable & "." & arguments.object.getPrimaryKey().getColumn());
		buffer.append(" = " & manytomanyTable & "." & arguments.manyToMany.getLinkFrom().getColumn());

		//second part
		buffer.append(" INNER JOIN ");
		buffer.append(arguments.composite.getTable() & " " & compositeTable);
		buffer.append(" ON " & manytomanyTable & "." & manyToMany.getLinkTo().getColumn());
		buffer.append(" = " & compositeTable & "." & arguments.composite.getPrimaryKey().getColumn());

		return buffer.toString();
	</cfscript>
</cffunction>

<cffunction name="buildConditionSQL" hint="Builds the where statement for a condition" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The Object that is being created in the collection" type="transfer.com.object.Object" required="Yes">
	<cfargument name="condition" hint="The condition" type="transfer.com.object.Condition" required="Yes">
	<cfargument name="orderIndex" hint="The order index" type="numeric" required="Yes">
	<cfscript>
		var table = createTableName(arguments.object, arguments.orderIndex);

		if(arguments.condition.hasProperty())
		{
			return table & "." & arguments.object.getPropertyByName(arguments.condition.getProperty()).getColumn() & " = '" & arguments.condition.getValue() & "'";
		}

		return getTQLConverter().replaceProperties(arguments.object, arguments.condition.getWhere(), table);
	</cfscript>
</cffunction>

<cffunction name="buildOrder" hint="Builds the ORDER BY part of the sql" access="private" returntype="string" output="false">
	<cfargument name="orderBuffer" hint="The java.util.StringBuffer for order bys" type="any" required="Yes">
	<cfargument name="collection" hint="The collection that is being created" type="transfer.com.object.Collection" required="Yes">
	<cfargument name="object" hint="The Object that is being created in the collection" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var property = 0;
		if(arguments.collection.hasOrder())
		{
			property = arguments.object.getPropertyByName(arguments.collection.getOrder().getProperty());

			//make sure we're not already ordering by it
			if(NOT FindNoCase(" " & property.getColumn() & " ", arguments.orderBuffer.toString()))
			{
				arguments.orderBuffer.append(", " & property.getColumn() & " " & arguments.collection.getOrder().getOrder());
			}
		}
	</cfscript>
</cffunction>

<cffunction name="buildCompositeKeyValue" hint="builds the sql for a composite parent key" access="private" returntype="string" output="false">
	<cfargument name="tableName" hint="the name of the table to build against" type="string" required="Yes">
	<cfargument name="object" hint="the parent object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var primaryKey = arguments.object.getPrimaryKey();
		var iterator = primaryKey.getPropertyIterator();
		var property = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var isFirst = true;
		var pipe = "'|'";
		var buffer = createObject("java", "java.lang.StringBuffer").init();

		buffer.append(writeStartConcat());

		while(iterator.hasNext())
		{
			property = iterator.next();

			isFirst = concatSeperator(buffer, isFirst);

			appendCompositeKeyValue(buffer, arguments.tableName, property.getColumn());
			buffer.append(writeConcat());
			buffer.append(pipe);
		}

		iterator = primaryKey.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();

			isFirst = concatSeperator(buffer, isFirst);
			appendCompositeKeyValue(buffer, arguments.tableName, manytoone.getLink().getColumn());
			buffer.append(writeConcat());
			buffer.append(pipe);
		}

		iterator = primaryKey.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			isFirst = concatSeperator(buffer, isFirst);
			appendCompositeKeyValue(buffer, arguments.tableName, parentOneToMany.getLink().getColumn());
			buffer.append(writeConcat());
			buffer.append(pipe);
		}

		buffer.append(writeEndConcat());

		return buffer.toString();
	</cfscript>
</cffunction>

<cffunction name="appendCompositeKeyValue" hint="appends the composite key value to the buffer" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="the string buffer" type="any" required="Yes">
	<cfargument name="table" hint="the name of the table" type="string" required="Yes">
	<cfargument name="column" hint="the column to add" type="string" required="Yes">
	<cfscript>
		arguments.buffer.append(arguments.table & ".");
		arguments.buffer.append(arguments.column);
	</cfscript>
</cffunction>

<cffunction name="concatSeperator" hint="seperates values with commas" access="private" returntype="boolean" output="false">
	<cfargument name="buffer" hint="the stringbuffer object object" type="any" required="Yes">
	<cfargument name="isFirst" hint="if this is the first request to for the comma" type="boolean" required="Yes">
	<cfscript>
		if(NOT arguments.isFirst)
		{
			arguments.buffer.append(writeConcat());
		}
		return false;
	</cfscript>
</cffunction>

<cffunction name="createTableName" hint="Creates a table name from the table and hte orderindex" access="private" returntype="string" output="false">
	<cfargument name="object" hint="The object whose table we need" type="any" required="Yes">
	<cfargument name="orderIndex" hint="The order Index" type="numeric" required="Yes">
	<cfscript>
		var name = 0;

		if(arguments.object.hasTableAlias())
		{
			name = arguments.object.getTableAlias();
		}
		else
		{
			name = arguments.object.getTable();
		}

		//name = rereplaceNoCase(name, "[\.\-]", "_", "all");
		//name = rereplaceNoCase(name, "[\[\]]", "", "all");
		name = replaceList(name, ".,-,[,]", "_,_");

		return name & "_" & arguments.orderIndex;
	</cfscript>
</cffunction>

<cffunction name="writeNULL" hint="Overwrite to implement database specific NULL string text." access="private" returntype="string" output="false">
	<cfargument name="column" hint="The column to write the 'NULL' for" type="string" required="Yes">
	<cfargument name="type" hint="The type to write the 'NULL' for" type="string" required="Yes">
	<cfreturn "NULL">
</cffunction>

<cffunction name="writeConcat" hint="writes concat seperator" access="private" returntype="string" output="false">
	<cfreturn "||"/>
</cffunction>


<cffunction name="writeStartConcat" hint="writes the start concat seperator" access="private" returntype="string" output="false">
	<cfreturn ""/>
</cffunction>

<cffunction name="writeEndConcat" hint="writes the end concat seperator" access="private" returntype="string" output="false">
	<cfreturn ""/>
</cffunction>


<cffunction name="getTQLConverter" access="private" returntype="transfer.com.sql.TQLConverter" output="false">
	<cfreturn instance.TQLConverter />
</cffunction>

<cffunction name="setTQLConverter" access="private" returntype="void" output="false">
	<cfargument name="TQLConverter" type="transfer.com.sql.TQLConverter" required="true">
	<cfset instance.TQLConverter = arguments.TQLConverter />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>