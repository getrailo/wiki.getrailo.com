<!--- Document Information -----------------------------------------------------

Title:      TransferPopulator.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Populates a Transfer Object with Query Information

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		19/07/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="TransferPopulator" hint="Populates a Transfer Objects with Query information">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="TransferPopulator" output="false">
	<cfargument name="sqlManager" hint="The SQL Manager" type="transfer.com.sql.SQLManager" required="Yes">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		setSQLManager(arguments.sqlManager);
		setObjectManager(arguments.objectManager);
		setMethodInvoker(createObject("component", "transfer.com.dynamic.MethodInvoker").init());
		setJavaLoader(arguments.javaloader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="populate" hint="Populates a Transfer object with query data" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to populate" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="key" hint="Key for the BO" type="any" required="Yes">

	<cfscript>
		var object = getObjectManager().getObject(arguments.transfer.getClassName());

		//pass the object over to the query maker, and get back the result
		var qObject = getSQLManager().select(object, arguments.key);

		//create memento from the result
		var memento = buildMemento(qObject);

		//if key not found, it will return an empty object
		if(not StructIsEmpty(memento))
		{
			//setMemento on the transfer object
			arguments.transfer.setMemento(memento);
		}
	</cfscript>
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

<cffunction name="populateManyToOne" hint="populates many to one data into the object for lazy load" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the manytoone to load" type="string" required="Yes">
	<cfscript>
		var lazyObject = getObjectManager().getObjectLazyManyToOne(arguments.transfer.getClassName(), arguments.name);

		//get primary key
		var key = invokePrimarykey(arguments.transfer, lazyObject.getPrimaryKey());

		//pass the object over to the query maker, and get back the result
		var qObject = getSQLManager().select(lazyObject, key, arguments.name);
		var memento = buildMemento(qObject);
		var args = structNew();

		//build memento arguments
		args.memento = StructNew();

		if(StructKeyExists(memento, arguments.name))
		{
			args.memento = memento[arguments.name];
		}

		getMethodInvoker().invokeMethod(arguments.transfer, "set" & arguments.name & "Memento", args);
	</cfscript>
</cffunction>

<cffunction name="populateOneToMany" hint="populates onetomany data into the object for lazy load" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the manytoone to load" type="string" required="Yes">
	<cfscript>
		var lazyObject = getObjectManager().getObjectLazyOneToMany(arguments.transfer.getClassName(), arguments.name);

		//get primary key
		var key = invokePrimarykey(arguments.transfer, lazyObject.getPrimaryKey());

		//pass the object over to the query maker, and get back the result
		var qObject = getSQLManager().select(lazyObject, key, arguments.name);

		var memento = buildMemento(qObject);
		var args = structNew();

		//build memento arguments
		args.memento = ArrayNew(1);

		if(StructKeyExists(memento, arguments.name))
		{
			args.memento = memento[arguments.name];
		}

		getMethodInvoker().invokeMethod(arguments.transfer, "set" & arguments.name & "Memento", args);
	</cfscript>
</cffunction>

<cffunction name="populateManyToMany" hint="populates manytomany data into the object for lazy load" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the manytoone to load" type="string" required="Yes">
	<cfscript>
		var lazyObject = getObjectManager().getObjectLazyManyToMany(arguments.transfer.getClassName(), arguments.name);

		//get primary key
		var key = invokePrimarykey(arguments.transfer, lazyObject.getPrimaryKey());

		//pass the object over to the query maker, and get back the result
		var qObject = getSQLManager().select(lazyObject, key, arguments.name);

		var memento = buildMemento(qObject);
		var args = structNew();

		//build memento arguments
		args.memento = ArrayNew(1);

		if(StructKeyExists(memento, arguments.name))
		{
			args.memento = memento[arguments.name];
		}

		getMethodInvoker().invokeMethod(arguments.transfer, "set" & arguments.name & "Memento", args);
	</cfscript>
</cffunction>

<cffunction name="populateParentOneToMany" hint="populates parent onetomany data into the object for lazy load" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the external onetomany to load" type="string" required="Yes">
	<cfscript>
		var lazyObject = getObjectManager().getObjectLazyParentOneToMany(arguments.transfer.getClassName());

		//get primary key
		var key = invokePrimarykey(arguments.transfer, lazyObject.getPrimaryKey());

		//pass the object over to the query maker, and get back the result
		var qObject = getSQLManager().select(lazyObject, key, arguments.name);

		var args = structNew();

		//build memento arguments
		args.memento = buildMemento(qObject);

		getMethodInvoker().invokeMethod(arguments.transfer, "set" & arguments.name & "Memento", args);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="invokePrimarykey" hint="returns a primary key value for a given object" access="private" returntype="any" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="primaryKey" hint="the primary key" type="transfer.com.object.AbstractBaseKey" required="Yes">
	<cfscript>
		if(arguments.primaryKey.getIsComposite())
		{
			return invokeCompositeKey(arguments.transfer, arguments.primaryKey);
		}
		else
		{
			return getMethodInvoker().invokeMethod(arguments.transfer, "get" & arguments.primaryKey.getName());
		}
	</cfscript>
</cffunction>

<cffunction name="invokeCompositeKey" hint="returns a composite key for the given object" access="public" returntype="struct" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="primaryKey" hint="the primary key" type="transfer.com.object.CompositeKey" required="Yes">
	<cfscript>
		var key = StructNew();
		var property = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var iterator = primaryKey.getPropertyIterator();
		var value = 0;
		var composite = 0;
		var has = 0;
		var parentObject = 0;

		while(iterator.hasNext())
		{
			property = iterator.next();
			if(NOT (property.getIsNullable() AND getMethodInvoker().invokeMethod(arguments.transfer, "get" & property.getName() & "isNull")))
			{
				key[property.getName()] = getMethodInvoker().invokeMethod(arguments.transfer, "get" & property.getName());
			}
		}

		iterator = primaryKey.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			has = getMethodInvoker().invokeMethod(arguments.transfer, "has" & manytoone.getName());

			if(has)
			{
				composite = getMethodInvoker().invokeMethod(arguments.transfer, "get" & manytoone.getName());
				key[manytoone.getName()] = getMethodInvoker().invokeMethod(composite, "get" & manytoone.getLink().getToObject().getPrimaryKey().getName());
			}
		}

		iterator = primaryKey.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();
			parentObject = parentOneToMany.getLink().getToObject();

			has = getMethodInvoker().invokeMethod(arguments.transfer, "hasParent" & parentObject.getObjectName());

			if(has)
			{
				composite = getMethodInvoker().invokeMethod(arguments.transfer, "getParent" & parentObject.getObjectName());
				key["parent" & parentObject.getObjectName()] = getMethodInvoker().invokeMethod(composite, "get" & parentObject.getPrimaryKey().getName());
			}
		}

		return key;
	</cfscript>
</cffunction>

<cffunction name="buildMemento" hint="Builds a memento from a object and query" access="private" returntype="struct" output="false">
	<cfargument name="qObject" hint="The query that has the data" type="query" required="Yes">
	<cfargument name="lazyLoad" hint="if this is a lazy load" type="boolean" required="No" default="false">
	<cfscript>
		var object = 0;
		var parentClassName = 0;
		var parentCompositeName = 0;
		var compositeName = 0;
		var isArray = 0;
		var parentKey = 0;
		var mementoPart = 0;
		var mementoBuilder = createObject("component", "transfer.com.dynamic.MementoBuilder").init(getObjectManager(),
																									arguments.qObject,
																									getJavaLoader());
		var primarykey = 0;
		var parentParentClassName = 0;
		var key = 0;
		var isComposite = 0;

		//throw exception if empty
		if(NOT arguments.qObject.recordCount)
		{
			throw("transfer.EmptyQueryException", "The query provided to populate this transfer is empty", "It is likely the ID that has been selected for this query no longer exists");
		}
	</cfscript>

	<cfloop query="arguments.qObject">
		<cfscript>
			object = getObjectManager().getObject(transfer_className);
			parentClassName = transfer_parentClassName;
			isArray = transfer_isArray;
			compositeName = transfer_compositeName;
			parentParentClassName = transfer_parentParentClassName;
			primarykey = object.getPrimaryKey();
			isComposite = primaryKey.getIsComposite();

			if(Len(parentClassName))
			{
				parentKey = transfer_parentKey;
				parentCompositeName = transfer_parentCompositeName;
			}

			mementoPart = createObject("java", "java.util.HashMap").init();

			/*
			We are using HashMaps, with StructInsert and StructFind, as it is
			the fastest way of building and retrieving data from mementos
			*/

			//tell it that it is not dirty, and is persisted
			StructInsert(mementoPart, "transfer_isDirty", false);
			StructInsert(mementoPart, "transfer_isPersisted", true);
			StructInsert(mementoPart, "transfer_isProxied", arguments.qObject.transfer_isProxied);

			//if it's a proxy, we don't need the extra pieces
			if(NOT StructFind(mementoPart, "transfer_isProxied"))
			{
				populatePropertyMemento(mementoPart, object, arguments.qObject);
				populateParentOneToManyMemento(mementoPart, object, arguments.qObject);
			}
			else
			{
				populateProxyPropertyMapMemento(mementoPart, object, arguments.qObject);
				if(isComposite)
				{
					populateCompositeParentOneToManyMemento(mementoPart, primaryKey, arguments.qObject);
				}
			}

			//do this last, so we can use what we already have in the memento
			if(isComposite)
			{
				key = arguments.qObject.transfer_compositeid[arguments.qObject.currentRow];
				buildCompositeKeyMemento(mementoPart, object, arguments.qObject);
			}
			else
			{
				//lets get the peices of the primary key
				key = getSQLManager().getPropertyColumnValue(arguments.qObject, object, object.getPrimaryKey());

				StructInsert(mementoPart,
							primaryKey.getName(),
							getSQLManager().getPropertyColumnValue(arguments.qObject, object, object.getPrimaryKey()));
			}

			//add the details to the memento objects
			mementoBuilder.add(compositeName, key, object.getClassName(), isArray, mementoPart, parentClassName, parentKey, parentCompositeName, parentParentClassName);
		</cfscript>
	</cfloop>
	<cfreturn mementoBuilder.getMementoStruct()>
</cffunction>

<cffunction name="buildCompositeKeyMemento" hint="builds the composite key memento" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="the memento to append to" type="struct" required="Yes">
	<cfargument name="object" hint="the object BO" type="transfer.com.object.Object" required="Yes">
	<cfargument name="query" hint="the query that the data is coming from" type="query" required="Yes">
	<cfscript>
		var key = createObject("java", "java.util.HashMap").init();
		var primaryKey = arguments.object.getPrimaryKey();
		var property = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var iterator = primaryKey.getPropertyIterator();
		var value = 0;
		var composite = 0;

		while(iterator.hasNext())
		{
			property = iterator.next();
			StructInsert(key, property.getName(), arguments.memento[property.getName()]);
		}

		iterator = primaryKey.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();

			value = arguments.query[manytoone.getLink().getColumn()][arguments.query.currentRow];
			if(Len(value))
			{
				StructInsert(key, manytoone.getName(), value);
			}
		}

		iterator = primaryKey.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();
			composite = parentOneToMany.getLink().getToObject();

			value = arguments.memento["parent"& composite.getObjectName() & "_" & composite.getPrimaryKey().getName()];
			if(len(value))
			{
				StructInsert(key, "parent" & composite.getObjectName(), value);
			}
		}

		StructInsert(arguments.memento, object.getPrimaryKey().getName(), key);
	</cfscript>
</cffunction>

<cffunction name="populatePropertyMemento" hint="populates the memento with property values" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="the memento to be set" type="struct" required="Yes">
	<cfargument name="object" hint="the object meta data" type="transfer.com.object.Object" required="Yes">
	<cfargument name="qObject" hint="the query for teh object" type="query" required="Yes">
	<cfscript>
		//loop throough properties
		var iterator = arguments.object.getPropertyIterator();
		var property = 0;

		while(iterator.hasNext())
		{
			property = iterator.next();

			StructInsert(arguments.memento,
						property.getName(),
						getSQLManager().getPropertyColumnValue(arguments.qObject, arguments.object, property));
		}
	</cfscript>
</cffunction>

<cffunction name="populateParentOneToManyMemento" hint="populates the memento with parent one to many values" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="the memento to be set" type="struct" required="Yes">
	<cfargument name="object" hint="the object meta data" type="transfer.com.object.Object" required="Yes">
	<cfargument name="qObject" hint="the query for teh object" type="query" required="Yes">
	<cfscript>
		//loop through parents
		var iterator = arguments.object.getParentOneToManyIterator();

		populateParentOneToManyMementoByIterator(arguments.memento, iterator, arguments.qObject);
	</cfscript>
</cffunction>

<cffunction name="populateCompositeParentOneToManyMemento" hint="populates the memento with parent one to many values, from a composite. Used for proxies" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="the memento to be set" type="struct" required="Yes">
	<cfargument name="compositeKey" hint="the composite id" type="transfer.com.object.CompositeKey" required="Yes">
	<cfargument name="qObject" hint="the query for teh object" type="query" required="Yes">
	<cfscript>
		//loop through parents
		var iterator = arguments.compositeKey.getParentOneToManyIterator();

		populateParentOneToManyMementoByIterator(arguments.memento, iterator, arguments.qObject);
	</cfscript>
</cffunction>

<cffunction name="populateParentOneToManyMementoByIterator" hint="populates the memento with parent one to many values, with a passed in iterator" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="the memento to be set" type="struct" required="Yes">
	<cfargument name="iterator" hint="a java.util.Iterator containing ParentOneToMany" type="any" required="Yes">
	<cfargument name="qObject" hint="the query for teh object" type="query" required="Yes">
	<cfscript>
		//loop through parents
		var parentOneToMany = 0;
		var parentObject = 0;

		while(arguments.iterator.hasNext())
		{
			parentOneToMany = arguments.iterator.next();

			parentObject = parentOneToMany.getLink().getToObject();

			StructInsert(arguments.memento,
						"parent"& parentObject.getObjectName() & "_" & parentObject.getPrimaryKey().getName(),
						arguments.qObject[parentOneToMany.getLink().getColumn()][arguments.qObject.currentRow]);
		}
	</cfscript>
</cffunction>

<cffunction name="populateProxyPropertyMapMemento" hint="populates the memento with parent one to many values" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="the memento to be set" type="struct" required="Yes">
	<cfargument name="object" hint="the object meta data" type="transfer.com.object.Object" required="Yes">
	<cfargument name="qObject" hint="the query for teh object" type="query" required="Yes">
	<cfscript>
		//loop through qExternalObjects
		var iterator = object.getParentOneToManyIterator();
		var parentOneToMany = 0;
		var parentManyToMany = 0;

		//we want to set the propertyMap memento - have to use a Struct, so it's case insensitive
		StructInsert(arguments.memento, "propertyMap", StructNew());

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			populateCollectionProperty(arguments.memento, arguments.object, parentOneToMany.getCollection(), arguments.qObject);
		}

		iterator = arguments.object.getParentManyToManyIterator();

		while(iterator.hasNext())
		{
			parentManyToMany = iterator.next();

			populateCollectionProperty(arguments.memento, arguments.object, parentManyToMany.getCollection(), arguments.qObject);
		}
	</cfscript>
</cffunction>

<cffunction name="populateCollectionProperty" hint="populates the memento with the collection property value" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="the memento to be set" type="struct" required="Yes">
	<cfargument name="object" hint="the object meta data" type="transfer.com.object.Object" required="Yes">
	<cfargument name="collection" hint="the collection meta data" type="transfer.com.object.Collection" required="Yes">
	<cfargument name="qObject" hint="the query for teh object" type="query" required="Yes">
	<cfscript>
		var property = 0;
		var propertyMap = 0;

		if(arguments.collection.hasOrder())
		{
			property = arguments.object.getPropertyByName(arguments.collection.getOrder().getProperty());
		}
		else if(arguments.collection.hasKey())
		{
			property = arguments.object.getPropertyByName(arguments.collection.getKey().getProperty());
		}

		propertyMap = StructFind(arguments.memento, "propertyMap");

		if(isObject(property))
		{
			//may have already been set, due to cyclical referencing
			if(NOT StructKeyExists(propertyMap, property.getName()))
			{
				StructInsert(propertyMap,
							property.getName(),
							getSQLManager().getPropertyColumnValue(arguments.qObject, arguments.object, property));
			}
		}
	</cfscript>
</cffunction>

<cffunction name="getSQLManager" access="private" returntype="transfer.com.sql.SQLManager" output="false">
	<cfreturn instance.SQLManager />
</cffunction>

<cffunction name="setSQLManager" access="private" returntype="void" output="false">
	<cfargument name="SQLManager" type="transfer.com.sql.SQLManager" required="true">
	<cfset instance.SQLManager = arguments.SQLManager />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getMethodInvoker" access="private" returntype="transfer.com.dynamic.MethodInvoker" output="false">
	<cfreturn instance.MethodInvoker />
</cffunction>

<cffunction name="setMethodInvoker" access="private" returntype="void" output="false">
	<cfargument name="MethodInvoker" type="transfer.com.dynamic.MethodInvoker" required="true">
	<cfset instance.MethodInvoker = arguments.MethodInvoker />
</cffunction>

<cffunction name="getJavaLoader" access="private" returntype="transfer.com.util.JavaLoader" output="false">
	<cfreturn instance.JavaLoader />
</cffunction>

<cffunction name="setJavaLoader" access="private" returntype="void" output="false">
	<cfargument name="JavaLoader" type="transfer.com.util.JavaLoader" required="true">
	<cfset instance.JavaLoader = arguments.JavaLoader />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>
