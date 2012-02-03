<!--- Document Information -----------------------------------------------------

Title:      Transfer.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Main class of the transfer lib

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		11/07/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="Transfer" hint="Main class of the transfer lib">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="Transfer" output="false">
	<cfargument name="factory" hint="the global factory" type="transfer.com.factory.Factory" required="Yes">
	<cfscript>
		//init it
		arguments.factory.getCacheConfigManager();

		//resolve some ciruclar dependencies
		arguments.factory.setSingleton(this);

		setUtility(arguments.factory.getUtility());
		setObjectManager(arguments.factory.getObjectManager());

		//init it
		arguments.factory.getFacadeFactory();

		setEventManager(arguments.factory.getEventManager());

		setCacheManager(arguments.factory.getCacheManager());

		//di loop
		arguments.factory.getFacadeFactory().configure(getEventManager(), getCacheManager());

		setSQLManager(arguments.factory.getSQLManager());

		setTQLManager(arguments.factory.getTQLManager());

		setDynamicManager(arguments.factory.getDynamicManager());

		//these are here more to speed up object creations
		setTransaction(arguments.factory.getTransactionManager().getTransaction());

		setNullable(getSQLManager().getNullable());
		setDatasource(factory.getDatasource());

		return this;
	</cfscript>
</cffunction>

<cffunction name="new" hint="Creates a new, empty TransferObject decorated with the given classes methods" access="public" returntype="TransferObject" output="false">
	<cfargument name="class" hint="The name of the package and class (Case Sensitive)" type="string" required="Yes">
	<cfscript>
		//get the BO
		var object = getObjectManager().getObject(arguments.class);
		var transfer = 0;
		var decorator = 0;

		//lets build it
		transfer = getDynamicManager().createTransferObject(object);

		if(object.hasDecorator())
		{
			decorator = getDynamicManager().createDecorator(object, transfer);
			decorator = decorator.init(this, transfer, getUtility(), getNullable(), getDatasource(), getTransaction());

			getEventManager().fireAfterNewEvent(decorator);

			return decorator;
		}

		transfer = transfer.init(this, getUtility(), getNullable(), transfer);

		getEventManager().fireAfterNewEvent(transfer);

		return transfer;
	</cfscript>
</cffunction>

<cffunction name="get" hint="Retrieves a populated TransferObject of a given class and primary key. If no object exists for this key, an empty instance of the class is returned." access="public" returntype="TransferObject" output="false">
	<cfargument name="class" hint="The name of the package and class (Case Sensitive)" type="string" required="Yes">
	<cfargument name="key" hint="Primary key for the object in the DB, string if non composite, struct if composite" type="any" required="Yes">

	<cfscript>
		var transfer = 0;

		var rationalKey = rationaliseKey(arguments.class, arguments.key);
	</cfscript>

	<cftry>
		<!---
		double check lock it so that we only ever get one version of an object in the
		persistance scope
		 --->
		<cfif NOT isCached(arguments.class, rationalKey)>
			<cflock name="transfer.get.#arguments.class#.#rationalKey#" throwontimeout="true" timeout="60">
			<cfscript>
				//is in persistance manager
				if(NOT isCached(arguments.class, rationalKey))
				{
					//if not put it in
					transfer = new(arguments.class);

					//run the query
					getDynamicManager().populate(transfer, arguments.key);

					//set to non dirty, and persisted
					transfer.getOriginalTransferObject(true).setIsDirty(false);
					transfer.getOriginalTransferObject(true).setIsPersisted(true);

					//put it in persistance
					cache(transfer);

					cacheMiss(arguments.class);

					/*
					shoot it back out, in case it's a 'none' cached item,
					we don't want it looking for itself further down
					*/
					return transfer;
				}
			</cfscript>
			</cflock>
		</cfif>
		<cfscript>
			//get out of persistance and return
			transfer = getCacheManager().get(arguments.class, rationalKey);

			getCacheManager().hit(arguments.class);

			return transfer;
		</cfscript>

		<!--- if the cache actually got expired between, try again --->
		<cfcatch type="java.lang.Exception">
			<cfif cfcatch.Type eq "com.compoundtheory.objectcache.ObjectNotFoundException">
				<!--- missed! --->
				<cfset cacheMiss(arguments.class) />
				<!--- catch it if it gets removed along the way --->
				<cfreturn get(arguments.class, arguments.key) />
			<cfelse>
				<cfrethrow>
			</cfif>
		</cfcatch>
		<cfcatch type="transfer.EmptyQueryException">
			<cfscript>
				//missed!
				cacheMiss(arguments.class);
				//if not found, return a empty object
				return new(arguments.class);
			</cfscript>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="save" hint="If the object has yet to be instatiated, it is inserted into the db, otherwise it is updated" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to save" type="TransferObject" required="Yes">
	<cfargument name="useTransaction" hint="deprecated: use TransferFactory.getTransaction for transaction management. Whether or not to use an internal transaction block" type="boolean" required="No" default="true">
	<cfscript>
		//check and apply as required
		if(arguments.transfer.getIsPersisted())
		{
			update(arguments.transfer, arguments.useTransaction);
		}
		else
		{
			create(arguments.transfer, arguments.useTransaction);
		}
	</cfscript>
</cffunction>

<cffunction name="create" hint="Creates a new transfer in the DB. Sets the transfer's ID, and persists the object." access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to create in the DB" type="TransferObject" required="Yes">
	<cfargument name="useTransaction" hint="deprecated: use TransferFactory.getTransaction for transaction management. Whether or not to use an internal transaction block" type="boolean" required="No" default="true">
	<cfscript>
		//check to make sure it's not been created before
		if(arguments.transfer.getIsPersisted())
		{
			throw("ObjectAlreadyCreatedException", "Transfer Object has already been created", "The Transfer Object of type '"& arguments.transfer.getClassName() &"' has already been created in the database.");
		}

		getEventManager().fireBeforeCreateEvent(arguments.transfer);

		getSQLManager().create(arguments.transfer.getOriginalTransferObject(), arguments.useTransaction);

		//refresh
		getDynamicManager().refreshInsert(arguments.transfer);

		//set to non dirty, and persistant
		arguments.transfer.getOriginalTransferObject().setIsDirty(false);

		//if not valid, don't cache it
		if(arguments.transfer.getOriginalTransferObject().validateCacheState())
		{
			cache(arguments.transfer);
		}

		//if we are in an outer transaction, then put the object into a queue.
		if(getTransaction().getInTransaction())
		{
			getCacheManager().appendTransactionQueue(arguments.transfer);
		}

		arguments.transfer.getOriginalTransferObject().setIsPersisted(true);

		getEventManager().fireAfterCreateEvent(arguments.transfer);

		//handle transaction based caching
		if(getCacheManager().isTransactionScoped(arguments.transfer))
		{
			discard(arguments.transfer);
		}
	</cfscript>
</cffunction>

<cffunction name="update" hint="Updates the record of a Transfer object in the database" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="TransferObject" required="Yes">
	<cfargument name="useTransaction" hint="deprecated: use TransferFactory.getTransaction for transaction management. Whether or not to use an internal transaction block" type="boolean" required="No" default="true">
	<cfscript>
		var cachedObject = 0;

		//check to make sure it's not been created before
		if(NOT arguments.transfer.getIsPersisted())
		{
			throw("ObjectNotCreatedException", "Transfer Object has already not been created", "The Transfer Object of type '"& arguments.transfer.getClassName() &"' has not been created in the database.");
		}

		if(arguments.transfer.getIsDirty())
		{
			cachedObject = getCacheManager().synchronise(arguments.transfer);

			//queue it regardless, in case something goes wrong in the update
			getCacheManager().appendTransactionQueue(cachedObject);

			getEventManager().fireBeforeUpdateEvent(cachedObject);

			getSQLManager().update(cachedObject.getOriginalTransferObject(), arguments.useTransaction);

			//refresh
			getDynamicManager().refreshUpdate(cachedObject);

			//set to non dirty
			cachedObject.getOriginalTransferObject().setIsDirty(false);

			//do it on the original just in case
			arguments.transfer.getOriginalTransferObject().setIsDirty(false);

			//if not valid, discard it
			if(NOT cachedObject.getOriginalTransferObject().validateCacheState())
			{
				discard(cachedObject);
			}

			getEventManager().fireAfterUpdateEvent(cachedObject);

			//handle transaction based caching
			if(getCacheManager().isTransactionScoped(cachedObject))
			{
				discard(cachedObject);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="delete" hint="Deletes a transfer from the database and discard it from persistance." access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to delete" type="TransferObject" required="Yes">
	<cfargument name="useTransaction" hint="deprecated: use TransferFactory.getTransaction for transaction management. Whether or not to use an internal transaction block" type="boolean" required="No" default="true">
	<cfscript>
		var cachedObject = 0;

		//only run if it's in the DB
		if(arguments.transfer.getIsPersisted())
		{
			cachedObject = getCacheManager().synchronise(arguments.transfer);

			//queue it regardless, in case something goes wrong in the update
			getCacheManager().appendTransactionQueue(cachedObject);

			getEventManager().fireBeforeDeleteEvent(cachedObject);

			getSQLManager().delete(cachedObject, arguments.useTransaction);

			//set the cached object
			cachedObject.getOriginalTransferObject(true).setIsDirty(true);
			cachedObject.getOriginalTransferObject(true).setIsPersisted(false);

			//do the original one too
			arguments.transfer.getOriginalTransferObject(true).setIsDirty(true);
			arguments.transfer.getOriginalTransferObject(true).setIsPersisted(false);

			getEventManager().fireAfterDeleteEvent(cachedObject);

			discard(cachedObject);
		}
	</cfscript>
</cffunction>

<cffunction name="cascadeCreate" hint="does a cascade down the object hierarchy, calling create() as it goes" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to create" type="TransferObject" required="Yes">
	<cfargument name="depth" hint="the number of levels in which to cascade, 0 is unlimited" type="numeric" required="No" default="0">
	<cfargument name="useTransaction" hint="deprecated: use TransferFactory.getTransaction for transaction management. Whether or not to use an internal transaction block" type="boolean" required="No" default="true">
	<cfscript>
		arguments.visitor = this;
		arguments.visitingMethod = "create";
		arguments.visitArgs.useTransaction = arguments.useTransaction;

		if(arguments.useTransaction)
		{
			getTransaction().execute(getDynamicManager(), "visitObjectGraph", arguments);
		}
		else
		{
			visitObjectGraph(argumentCollection=arguments);
		}
	</cfscript>
</cffunction>

<cffunction name="cascadeUpdate" hint="does a cascade down the object hierarchy, calling update() as it goes" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="TransferObject" required="Yes">
	<cfargument name="depth" hint="the number of levels in which to cascade, 0 is unlimited" type="numeric" required="No" default="0">
	<cfargument name="useTransaction" hint="deprecated: use TransferFactory.getTransaction for transaction management. Whether or not to use an internal transaction block" type="boolean" required="No" default="true">
	<cfscript>
		arguments.visitor = this;
		arguments.visitingMethod = "update";
		arguments.visitArgs.useTransaction = arguments.useTransaction;

		if(arguments.useTransaction)
		{
			getTransaction().execute(getDynamicManager(), "visitObjectGraph", arguments);
		}
		else
		{
			visitObjectGraph(argumentCollection=arguments);
		}
	</cfscript>
</cffunction>

<cffunction name="cascadeSave" hint="does a cascade down the object hierarchy, calling save() as it goes" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to create" type="TransferObject" required="Yes">
	<cfargument name="depth" hint="the number of levels in which to cascade, 0 is unlimited" type="numeric" required="No" default="0">
	<cfargument name="useTransaction" hint="deprecated: use TransferFactory.getTransaction for transaction management. Whether or not to use an internal transaction block" type="boolean" required="No" default="true">
	<cfscript>
		arguments.visitor = this;
		arguments.visitingMethod = "save";
		arguments.visitArgs.useTransaction = arguments.useTransaction;

		if(arguments.useTransaction)
		{
			getTransaction().execute(getDynamicManager(), "visitObjectGraph", arguments);
		}
		else
		{
			visitObjectGraph(argumentCollection=arguments);
		}
	</cfscript>
</cffunction>

<cffunction name="cascadeDelete" hint="does a cascade down the object hierarchy, calling delete() as it goes" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to create" type="TransferObject" required="Yes">
	<cfargument name="depth" hint="the number of levels in which to cascade, 0 is unlimited" type="numeric" required="No" default="0">
	<cfargument name="useTransaction" hint="deprecated: use TransferFactory.getTransaction for transaction management. Whether or not to use an internal transaction block" type="boolean" required="No" default="true">
	<cfscript>
		arguments.visitor = this;
		arguments.visitingMethod = "delete";
		arguments.visitArgs.useTransaction = arguments.useTransaction;
		arguments.topDown = false;
		arguments.forceLoading = true;

		if(arguments.useTransaction)
		{
			getTransaction().execute(getDynamicManager(), "visitObjectGraph", arguments);
		}
		else
		{
			visitObjectGraph(argumentCollection=arguments);
		}
	</cfscript>
</cffunction>

<cffunction name="visitObjectGraph" hint="visit each of the objects in the graph, calling 'visit({transfer:transferObject, visitArgs1...})' on the visitor for each TransferObject in the graph" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="the starting object to visit" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="visitor" hint="the visitor object" type="any" required="Yes">
	<cfargument name="visitingMethod" hint="the name of the method that is being visited" type="string" required="Yes">
	<cfargument name="visitArgs" hint="visiting arguments, if there are any" type="struct" required="No" default="#StructNew()#">
	<cfargument name="depth" hint="the max depth to go to" type="numeric" required="no" default="0">
	<cfargument name="topDown" hint="travel top down, rather than bottom up" type="boolean" required="No" default="true">
	<cfargument name="forceLoading" hint="if not loaded, force loading" type="boolean" required="No" default="false">
	<cfscript>
		getDynamicManager().visitObjectGraph(argumentCollection=arguments);
	</cfscript>
</cffunction>

<cffunction name="discard" hint="Discard the object from the cache" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to delete" type="TransferObject" required="Yes">
	<cfscript>
		//_log("transfer - discard: #arguments.transfer.getClassName()# :: #instance.sys.identityHashCode(arguments.transfer)#");

		getCacheManager().discard(arguments.transfer);

		getEventManager().fireAfterDiscardEvent(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="discardByClassAndKey" hint="Discards an Object by its class and its key, if it exists" access="public" returntype="void" output="false">
	<cfargument name="className" hint="The class name of the object to discard" type="string" required="Yes">
	<cfargument name="key" hint="The primary key value for the object" type="any" required="Yes">
	<cfscript>
		var transfer = 0;
		arguments.key = rationaliseKey(arguments.className, arguments.key);
	</cfscript>

	<cfif getCacheManager().have(arguments.className, arguments.key)>
		<cftry>
			<cfscript>
				transfer = getCacheManager().get(arguments.className, arguments.key);
				discard(transfer);
			</cfscript>
			<cfcatch type="java.lang.Exception">
				<cfswitch expression="#cfcatch.Type#">
					<!--- catch it if it gets removed along the way --->
					<cfcase value="com.compoundtheory.objectcache.ObjectNotFoundException">
						<!--- do nothing --->
					</cfcase>
					<cfdefaultcase>
						<cfrethrow>
					</cfdefaultcase>
				</cfswitch>
			</cfcatch>
		</cftry>
	</cfif>
</cffunction>

<cffunction name="discardByClassAndKeyArray" hint="Discards an Object by its class and each key in an array, if it exists" access="public" returntype="void" output="false">
	<cfargument name="className" hint="The class name of the object to discard" type="string" required="Yes">
	<cfargument name="keyArray" hint="The primary key values for the object" type="array" required="Yes">
	<cfscript>
		var iterator = arguments.keyArray.iterator();

		while(iterator.hasNext())
		{
			discardByClassAndKey(arguments.className, iterator.next());
		}
	</cfscript>
</cffunction>

<cffunction name="discardByClassAndKeyQuery" hint="Discards an Object by its class and each key in an array, if it exists" access="public" returntype="void" output="false">
	<cfargument name="className" hint="The class name of the object to discard" type="string" required="Yes">
	<cfargument name="keyQuery" hint="The primary key values for the object" type="query" required="Yes">
	<cfargument name="columnName" hint="The name of the column the the id is in" type="string" required="Yes">
	<cfscript>
		var key = 0;
	</cfscript>

	<cfloop query="arguments.keyQuery">
		<cfscript>
			key = arguments.keyQuery[arguments.columnName][arguments.keyQuery.currentRow];

			discardByClassAndKey(arguments.className, key);
		</cfscript>
	</cfloop>
</cffunction>

<cffunction name="discardAll" hint="Discards all objects from the cache. Generally for development purposes."
			access="public" returntype="void" output="false">
	<cfscript>
		getCacheManager().discardAll();
	</cfscript>
</cffunction>

<cffunction name="recycle" hint="Recycle an TransferObject for reuse by the system later on. This is good for performance. Only do this once a TransferObject has been deleted or discarded, and is not stored in any shared scopes, as the object's state is reset" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to delete" type="TransferObject" required="Yes">
	<cfscript>
		//remove, as we're losing state here
		getCacheManager().removeTransactionQueue(arguments.transfer);
		//let's clean and recycle
		getDynamicManager().recycle(getDynamicManager().cleanTransfer(arguments.transfer.getOriginalTransferObject()));
	</cfscript>
</cffunction>

<!--- Meta Data --->

<cffunction name="getTransferMetaData" hint="Returns the Object meta data for a given transferobject class" access="public" returntype="transfer.com.object.Object" output="false">
	<cfargument name="className" hint="The class name of the transfer object" type="string" required="Yes">
	<cfreturn getObjectManager().getObject(arguments.className)>
</cffunction>

<!--- Get a query --->

<cffunction name="createQuery" hint="creates a query object for TQL interpretation" access="public" returntype="transfer.com.tql.Query" output="false">
	<cfargument name="tql" hint="The Transfer Query Language query" type="string" required="Yes">
	<cfreturn getTQLManager().createQuery(arguments.tql) />
</cffunction>

<!--- gateway functions --->

<cffunction name="list" hint="Lists a series of object values" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="No" default="">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="No" default="true">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="no" default="true">

	<cfscript>
		return getSQLManager().list(arguments.className, arguments.orderProperty, arguments.orderASC, arguments.useAliases);
	</cfscript>
</cffunction>

<cffunction name="listByProperty" hint="Lists a series of values, filtered by a given value" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to filter by" type="string" required="Yes">
	<cfargument name="propertyValue" hint="The value to filter by (only simple values)" type="any" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="No" default="">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="No" default="true">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="no" default="true">

	<cfscript>
		return getSQLManager().listByProperty(arguments.className,
												arguments.propertyName,
												arguments.propertyValue,
												false,
												arguments.orderProperty,
												arguments.orderASC,
												arguments.useAliases);
	</cfscript>
</cffunction>

<cffunction name="listByPropertyMap" hint="Lists values, filtered by a Struct of Property : Value properties" access="public" returntype="query" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="propertyMap" hint="Struct with keys that match to properties, and values to filter by" type="struct" required="Yes">
	<cfargument name="orderProperty" hint="The property to order by" type="string" required="No" default="">
	<cfargument name="orderASC" hint="Boolean whether to order by ASC, otherwise order by DESC" type="boolean" required="No" default="true">
	<cfargument name="useAliases" hint="Boolean as to whether or not to alias columns with the transfer property names" type="boolean" required="no" default="true">

	<cfscript>
		return getSQLManager().listByPropertyMap(arguments.className,
													arguments.propertyMap,
													false,
													arguments.orderProperty,
													arguments.orderASC,
													arguments.useAliases);
	</cfscript>
</cffunction>

<cffunction name="listByQuery" hint="List by a TQL Query" access="public" returntype="query" output="false">
	<cfargument name="query" hint="A TQL Query object" type="transfer.com.tql.Query" required="Yes">

	<cfscript>
		return getTQLManager().evaluateQuery(arguments.query);
	</cfscript>
</cffunction>

<!--- readBy methods --->

<cffunction name="readByProperty" hint="retrieve an object by it's unique property. Throws an Exception if more than one object found" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="className" hint="The class of the objects to find" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to find" type="string" required="Yes">
	<cfargument name="propertyValue" hint="The value to find (only simple values)" type="any" required="Yes">

	<cfscript>
		var qResults = getSQLManager().listByProperty(className=arguments.className,
														propertyName=arguments.propertyName,
														propertyValue=arguments.propertyValue,
														onlyRetrievePrimaryKey=true,
														useAliases=false);

		return read(arguments.className, qResults);
	</cfscript>
</cffunction>

<cffunction name="readByPropertyMap" hint="retrieve and object by a set of unique properties.  Throws an Exception if more than one object found" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="className" hint="The class of the objects to list" type="string" required="Yes">
	<cfargument name="propertyMap" hint="Struct with keys that match to properties, and values to filter by" type="struct" required="Yes">
	<cfscript>
		var qResults = getSQLManager().listByPropertyMap(className=arguments.className,
															propertyMap=arguments.propertyMap,
															onlyRetrievePrimaryKey=true,
															useAliases=false);

		return read(arguments.className, qResults);
	</cfscript>
</cffunction>

<cffunction name="readByQuery" hint="retrieve an object by a TQL query.  The query must either start with 'from' or only have one column in its result" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="className" hint="The class of the objects to find" type="string" required="Yes">
	<cfargument name="query" hint="TQL Query object" type="transfer.com.tql.Query" required="Yes">
	<cfscript>
		var qResults = 0;
		arguments.query.setAliasColumns(false);

		qResults = getTQLManager().evaluateQuery(arguments.query, true, arguments.className);

		return read(arguments.className, qResults);
	</cfscript>
</cffunction>

<!--- add observer functions --->

<cffunction name="addBeforeCreateObserver" hint="Adds an object as a observer of before create events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().addBeforeCreateObserver(getEventManager().getObjectAdapter(arguments.observer));
	</cfscript>
</cffunction>

<cffunction name="addAfterCreateObserver" hint="Adds an object as a observer of after create events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().addAfterCreateObserver(getEventManager().getObjectAdapter(arguments.observer));
	</cfscript>
</cffunction>

<cffunction name="addBeforeUpdateObserver" hint="Adds an object as a observer of before update events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().addBeforeUpdateObserver(getEventManager().getObjectAdapter(arguments.observer));
	</cfscript>
</cffunction>

<cffunction name="addAfterUpdateObserver" hint="Adds an object as a observer of after update events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().addAfterUpdateObserver(getEventManager().getObjectAdapter(arguments.observer));
	</cfscript>
</cffunction>

<cffunction name="addBeforeDeleteObserver" hint="Adds an object as a observer of before delete events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().addBeforeDeleteObserver(getEventManager().getObjectAdapter(arguments.observer));
	</cfscript>
</cffunction>

<cffunction name="addAfterDeleteObserver" hint="Adds an object as a observer of after delete events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().addAfterDeleteObserver(getEventManager().getObjectAdapter(arguments.observer));
	</cfscript>
</cffunction>

<cffunction name="addAfterNewObserver" hint="Adds an object as a observer of after new events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().addAfterNewObserver(getEventManager().getObjectAdapter(arguments.observer));
	</cfscript>
</cffunction>

<!--- remove observer functions --->

<cffunction name="removeBeforeCreateObserver" hint="removes an observer of before create events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().removeBeforeCreateObserver(arguments.observer);
	</cfscript>
</cffunction>

<cffunction name="removeAfterCreateObserver" hint="removes an observer of after create events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().removeAfterCreateObserver(arguments.observer);
	</cfscript>
</cffunction>

<cffunction name="removeBeforeUpdateObserver" hint="removes an observer of before update events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().removeBeforeUpdateObserver(arguments.observer);
	</cfscript>
</cffunction>

<cffunction name="removeAfterUpdateObserver" hint="removes an observer of after update events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().removeAfterUpdateObserver(arguments.observer);
	</cfscript>
</cffunction>

<cffunction name="removeBeforeDeleteObserver" hint="removes an observer of Before Delete events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().removeBeforeDeleteObserver(arguments.observer);
	</cfscript>
</cffunction>

<cffunction name="removeAfterDeleteObserver" hint="removes an observer of after Delete events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().removeAfterDeleteObserver(arguments.observer);
	</cfscript>
</cffunction>

<cffunction name="removeAfterNewObserver" hint="removes an observer of after new events" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer" type="any" required="Yes">
	<cfscript>
		getEventManager().removeAfterNewObserver(arguments.observer);
	</cfscript>
</cffunction>

<!--- Cache Monitoring --->

<cffunction name="getCacheMonitor" hint="returns the cache monitor" access="public" returntype="transfer.com.cache.CacheMonitor" output="false">
	<cfreturn getCacheManager().getCacheMonitor() />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!--- these functions are for transferObjects --->

<cffunction name="cache" hint="Adds the object to the cache manager" access="package" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to cache" type="TransferObject" required="Yes">
	<cfscript>
		var softRef = 0;

		softRef = getCacheManager().register(arguments.transfer);

		setTransferObjectEventListeners(softRef, arguments.transfer.getClassName());

		getCacheManager().add(softRef);
	</cfscript>
</cffunction>

<cffunction name="isCached" hint="Check if a transfer of a particular class is cached" access="package" returntype="boolean" output="false">
	<cfargument name="class" hint="The name of the class" type="string" required="Yes">
	<cfargument name="key" hint="The key for the id of the data" type="string" required="Yes">
	<cfscript>
		return getCacheManager().have(arguments.class, arguments.key);
	</cfscript>
</cffunction>

<cffunction name="rationaliseKey" hint="rationlises the key, depending on type, to a string" access="package" returntype="string" output="false">
	<cfargument name="class" hint="The name of the class" type="string" required="Yes">
	<cfargument name="key" hint="The key for the id of the data" type="any" required="Yes">
	<cfreturn getDynamicManager().rationaliseKey(arguments.class, arguments.key) />
</cffunction>

<cffunction name="loadManyToOne" hint="LazyLoads the required manytone data into an object" access="package" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the manytoone to load" type="string" required="Yes">
	<cfscript>
		try
		{
			getDynamicManager().populateManyToOne(arguments.transfer, arguments.name);
		}
		catch(transfer.EmptyQueryException exc)
		{
			//do nothing
		}
	</cfscript>
</cffunction>

<cffunction name="loadOneToMany" hint="LazyLoads the required onetomany data into an object" access="package" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the onetomany to load" type="string" required="Yes">
	<cfscript>
		try
		{
			getDynamicManager().populateOneToMany(arguments.transfer, arguments.name);
		}
		catch(transfer.EmptyQueryException exc)
		{
			//do nothing
		}
	</cfscript>
</cffunction>

<cffunction name="loadManyToMany" hint="LazyLoads the required manytomany data into an object" access="package" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the manytomany to load" type="string" required="Yes">
	<cfscript>
		try
		{
			getDynamicManager().populateManyToMany(arguments.transfer, arguments.name);
		}
		catch(transfer.EmptyQueryException exc)
		{
			//do nothing
		}
	</cfscript>
</cffunction>

<cffunction name="loadParentOneToMany" hint="LazyLoads the required external onetomany data into an object" access="package" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the manytomany to load" type="string" required="Yes">
	<cfscript>
		try
		{
			getDynamicManager().populateParentOneToMany(arguments.transfer, arguments.name);
		}
		catch(transfer.EmptyQueryException exc)
		{
			//do nothing
		}
	</cfscript>
</cffunction>

<cffunction name="validateIsCached" hint="validates if a TransferObject is the same one as in cache" access="package" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to syncronise" type="transfer.com.TransferObject" required="Yes">
	<cfreturn getCacheManager().validateIsCached(arguments.transfer) />
</cffunction>

<cffunction name="createTransferObjectProxy" hint="creates an object proxy for usage with composites" access="package" returntype="transfer.com.TransferObjectProxy" output="false">
	<cfargument name="className" hint="the class name of the To we're creating" type="string" required="Yes">
	<cfargument name="key" hint="the primary key value" type="any" required="Yes">
	<cfargument name="propertyMap" hint="the property map that has been set" type="struct" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.className);

		return createObject("component", "transfer.com.TransferObjectProxy").init(arguments.className,
																					arguments.key,
																					object,
																					this,
																					getDynamicManager(),
																					arguments.propertyMap);
	</cfscript>
</cffunction>

<cffunction name="cacheMiss" hint="add an extra count to this cache's value not being found" access="package" returntype="void" output="false">
	<cfargument name="className" hint="the className being missed" type="string" required="Yes">
	<cfscript>
		getCacheManager().miss(arguments.className);
	</cfscript>
</cffunction>


<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="read" hint="Retrieves an object from a simple row query" access="private" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="className" hint="The class of the objects to find" type="string" required="Yes">
	<cfargument name="query" hint="The query to retrieve from" type="query" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.className);
		var primaryKey = object.getPrimaryKey();

		if(arguments.query.recordcount gt 1)
		{
			throw("transfer.MultipleRecordsFoundException",					"The parameters provided resulted in more than one record",
					"The query for '#arguments.className#' resulted in #arguments.query.recordCount# records in the Query");
		}

		if(arguments.query.recordcount)
		{
			if(primaryKey.getIsComposite())
			{
				return get(arguments.className, getDynamicManager().buildCompositeKeyMapFromQuery(primaryKey, arguments.query));
			}
			else
			{
				if(ListLen(arguments.query.columnList) gt 1)
				{
					throw("transfer.MultipleColumnsFoundException",
							"Read operations for non composite id objects can only have one column in the results",
							"The query for '#arguments.className#' resulted in the following columns being present: #arguments.query.columnList#");
				}

				return get(arguments.classname, arguments.query[arguments.query.columnList][1]);
			}
		}

		return new(arguments.className);
	</cfscript>
</cffunction>

<cffunction name="setTransferObjectEventListeners" hint="configure the event listeners to add to a particular transfer object" access="private" returntype="void" output="false">
	<cfargument name="softRef" hint="the soft reference to the Transfer Object to cache" type="any" required="Yes">
	<cfargument name="className" hint="the classname of the object" type="string" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.className);

		var hasManyToMany = object.hasManyToMany();
		var hasOneToMany = object.hasOneToMany();
		var hasParentOneToMany = object.hasParentOneToMany();
		var hasManyToOne = object.hasManyToOne();
		var adapter = 0;

		if(hasManyToMany OR hasOneToMany OR hasParentOneToMany OR hasManyToOne)
		{
			adapter = getEventManager().getSoftReferenceAdapter(arguments.softRef);

			if(hasOneToMany)
			{
				getEventManager().addAfterCreateObserver(adapter);
			}

			if(hasOneToMany or hasManyToMany or hasParentOneToMany or hasManyToOne)
			{
				getEventManager().addAfterDeleteObserver(adapter);
			}

			if(hasManyToMany OR hasOneToMany)
			{
				getEventManager().addAfterUpdateObserver(adapter);
			}

			if(hasManyToMany OR hasOneToMany OR hasManyToOne OR hasParentOneToMany)
			{
				getEventManager().addAfterDiscardObserver(adapter);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getCacheManager" access="private" returntype="transfer.com.cache.CacheManager" output="false">
	<cfreturn instance.CacheManager />
</cffunction>

<cffunction name="setCacheManager" access="private" returntype="void" output="false">
	<cfargument name="CacheManager" type="transfer.com.cache.CacheManager" required="true">
	<cfset instance.CacheManager = arguments.CacheManager />
</cffunction>

<cffunction name="getDynamicManager" access="private" returntype="transfer.com.dynamic.DynamicManager" output="false">
	<cfreturn instance.DynamicManager />
</cffunction>

<cffunction name="setDynamicManager" access="private" returntype="void" output="false">
	<cfargument name="DynamicManager" type="transfer.com.dynamic.DynamicManager" required="true">
	<cfset instance.DynamicManager = arguments.DynamicManager />
</cffunction>

<cffunction name="getEventManager" access="private" returntype="transfer.com.events.EventManager" output="false">
	<cfreturn instance.EventManager />
</cffunction>

<cffunction name="setEventManager" access="private" returntype="void" output="false">
	<cfargument name="EventManager" type="transfer.com.events.EventManager" required="true">
	<cfset instance.EventManager = arguments.EventManager />
</cffunction>

<cffunction name="getUtility" access="private" returntype="transfer.com.util.Utility" output="false">
	<cfreturn instance.Utility />
</cffunction>

<cffunction name="setUtility" access="private" returntype="void" output="false">
	<cfargument name="Utility" type="transfer.com.util.Utility" required="true">
	<cfset instance.Utility = arguments.Utility />
</cffunction>

<cffunction name="getSQLManager" access="private" returntype="transfer.com.sql.SQLManager" output="false">
	<cfreturn instance.SQLManager />
</cffunction>

<cffunction name="setSQLManager" access="private" returntype="void" output="false">
	<cfargument name="SQLManager" type="transfer.com.sql.SQLManager" required="true">
	<cfset instance.SQLManager = arguments.SQLManager />
</cffunction>

<cffunction name="getTQLManager" access="private" returntype="transfer.com.tql.TQLManager" output="false">
	<cfreturn instance.TQLManager />
</cffunction>

<cffunction name="setTQLManager" access="private" returntype="void" output="false">
	<cfargument name="TQLManager" type="transfer.com.tql.TQLManager" required="true">
	<cfset instance.TQLManager = arguments.TQLManager />
</cffunction>

<cffunction name="getTransaction" access="private" returntype="transfer.com.sql.transaction.Transaction" output="false">
	<cfreturn instance.transaction />
</cffunction>

<cffunction name="setTransaction" access="private" returntype="void" output="false">
	<cfargument name="transaction" type="transfer.com.sql.transaction.Transaction" required="true">
	<cfset instance.transaction = arguments.transaction />
</cffunction>

<cffunction name="getDatasource" access="private" returntype="transfer.com.sql.Datasource" output="false">
	<cfreturn instance.Datasource />
</cffunction>

<cffunction name="setDatasource" access="private" returntype="void" output="false">
	<cfargument name="Datasource" type="transfer.com.sql.Datasource" required="true">
	<cfset instance.Datasource = arguments.Datasource />
</cffunction>

<cffunction name="getNullable" access="private" returntype="transfer.com.sql.Nullable" output="false">
	<cfreturn instance.Nullable />
</cffunction>

<cffunction name="setNullable" access="private" returntype="void" output="false">
	<cfargument name="Nullable" type="transfer.com.sql.Nullable" required="true">
	<cfset instance.Nullable = arguments.Nullable />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>