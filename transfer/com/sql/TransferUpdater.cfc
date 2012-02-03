<!--- Document Information -----------------------------------------------------

Title:      TransferUpdater.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Does the update of a transfer object on the DB

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		10/08/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="TransferUpdater" hint="Does the update of a transfer object on the DB" extends="AbstractBaseTransfer">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransferUpdater" output="false">
	<cfargument name="Datasource" hint="The datasource BO" type="transfer.com.sql.Datasource" required="Yes" _autocreate="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="nullable" hint="The nullable class" type="transfer.com.sql.Nullable" required="Yes" _autocreate="false">
	<cfargument name="tQLConverter" hint="Converter for {property} statements" type="transfer.com.sql.TQLConverter" required="Yes">
	<cfargument name="queryExecutionPool" hint="the query execution pool" type="transfer.com.sql.collections.QueryExecutionPool" required="Yes">
	<cfargument name="queryCache" hint="the query object cache" type="transfer.com.sql.collections.QueryCache" required="Yes">
	<cfargument name="transaction" type="transfer.com.sql.transaction.Transaction" required="true" _autocreate="false">
	<cfscript>
		super.init(argumentCollection=arguments);

		setNullable(arguments.nullable);
		setTQLConverter(arguments.tQLConverter);

		setMethodInvoker(createObject("component", "transfer.com.dynamic.MethodInvoker").init());

		return this;
	</cfscript>
</cffunction>

<cffunction name="update" hint="Updates the Transfer in the DB" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="useTransaction" hint="Whether or not to use an internal transaction block" type="boolean" required="true">
	<cfscript>
		if(arguments.useTransaction)
		{
			getTransaction().execute(this, "updateBlock", arguments);
		}
		else
		{
			updateBlock(arguments.transfer);
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="updateBlock" hint="run the update" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		updateBasic(arguments.transfer);

		updateManyToMany(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="updateBasic" hint="Updates the single table portion of the transfer element table" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var query = buildUpdateBasic(arguments.transfer);
		var queryExec = query.createExecution();
		var object = getObjectManager().getObject(arguments.transfer.getClassName());
		var iterator = object.getPropertyIterator();
		var property = 0;
		var args = 0;
		var manytoone = 0;
		var parentonetomany = 0;
		var composite = 0;
		var linkObject = 0;

		//properties
		while(iterator.hasNext())
		{
			property = iterator.next();

			if(NOT property.getIgnoreUpdate())
			{
				args = StructNew();

				args.name = "property:" & property.getName();
				args.value = getMethodInvoker().invokeMethod(arguments.transfer, "get" & property.getName());

				if(property.getIsNullable())
				{
					args.isNull = getNullable().checkNullValue(arguments.transfer, property, args.value);
				}
				queryExec.setParam(argumentCollection=args);
			}
		}

		//many to one
		iterator = object.getManyToOneIterator();
		while(iterator.hasNext())
		{
			manytoone = iterator.next();

			args = StructNew();
			args.name = "manytoone:" & manytoone.getName();
			args.isNull = NOT getMethodInvoker().invokeMethod(arguments.transfer, "has" & manyToOne.getName());

			if(NOT args.isNull)
			{
				composite = getMethodInvoker().invokeMethod(transfer, "get" & manyToOne.getName());

				if(not composite.getIsPersisted())
				{
					throw("transfer.ManyToOneNotCreatedException",
						  "The ManyToOne TransferObject is not persisted.",
						  "In TransferObject '"& object.getClassName() &"' manytoone '"& composite.getClassName() &"' has not been persisted in the database.");
				}

				args.value = invokeGetPrimaryKey(composite);
			}
			queryExec.setParam(argumentCollection=args);
		}

		//parent one to many
		iterator = object.getParentOnetoManyIterator();

		while(iterator.hasNext())
		{
			parentonetomany = iterator.next();
			linkObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());

			args = StructNew();

			args.name = "parentonetomany:" & linkObject.getObjectName();
			args.isNull = NOT getMethodInvoker().invokeMethod(arguments.transfer, "hasParent" & linkObject.getObjectName());

			if(NOT args.isNull)
			{
				composite = getMethodInvoker().invokeMethod(arguments.transfer, "getParent" & linkObject.getObjectName());

				//make sure it's in the DB
				if(not composite.getIsPersisted())
				{
					throw("transfer.ParentOneToManyNotCreatedException",
						  "The Parent OneToMany TransferObject is not persisted.",
						  "In TransferObject '"& object.getClassName() &"' onetomany parent '"& composite.getClassName() &"' has not been persisted in the database.");
				}

				args.value = invokeGetPrimaryKey(composite);
			}
			queryExec.setParam(argumentCollection=args);
		}

		setPrimaryKey(queryExec, arguments.transfer);

		queryExec.execute();

		getQueryExecutionPool().recycle(queryExec);
	</cfscript>
</cffunction>

<cffunction name="buildUpdateBasic" hint="builds the query for the basic update" access="private" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var object = 0;
		var key = "basic.update." & arguments.transfer.getClassName();
		var iterator = 0;
		var isFirst = true;
		var property = true;
		var manytoone = 0;
		var parentOneToMany = 0;
		var composite = 0;
		var validUpdate = false;
		var query = 0;
	</cfscript>
	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT getQueryCache().hasQuery(key))
			{
				object = getObjectManager().getObject(arguments.transfer.getClassName());

				query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());
				query.start();

				query.appendSQL("UPDATE ");
				query.appendSQL(object.getTable());
				query.appendSQL(" SET ");

				//do properties
				iterator = object.getPropertyIterator();

				while(iterator.hasNext())
				{
					property = iterator.next();

					//ignore any property that has ignore-update='true'
					if(NOT property.getIgnoreUpdate())
					{
						isFirst = commaSeperator(query, isFirst);
						query.appendSQL(property.getColumn());
						query.appendSQL(" = ");
						query.mapParam("property:" & property.getName(), property.getType());

						validUpdate = true;
					}
				}

				//many to one
				iterator = object.getManyToOneIterator();
				while(iterator.hasNext())
				{
					manytoone = iterator.next();
					composite = getObjectManager().getObject(manyToOne.getLink().getTo());

					isFirst = commaSeperator(query, isFirst);

					query.appendSQL(manytoone.getLink().getColumn());
					query.appendSQL(" = ");
					query.mapParam("manytoone:" & manytoone.getName(), composite.getPrimaryKey().getType());

					validUpdate = true;
				}

				//parent one to many
				iterator = object.getParentOnetoManyIterator();

				while(iterator.hasNext())
				{
					parentOneToMany = iterator.next();
					composite = getObjectManager().getObject(parentOneToMany.getLink().getTo());
					isFirst = commaSeperator(query, isFirst);

					query.appendSQL(parentOneToMany.getLink().getColumn());
					query.appendSQL(" = ");
					query.mapParam("parentonetomany:" & composite.getObjectName(), composite.getPrimaryKey().getType());

					validUpdate = true;
				}

				query.appendSQL(" WHERE ");

				mapPrimaryKey(query, object);

				query.stop();

				if(validUpdate)
				{
					getQueryCache().addQuery(key, query);
				}
				else
				{
					query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());
					getQueryCache().addQuery(key, query);
				}
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn getQueryCache().getQuery(key) />
</cffunction>

<cffunction name="updateManyToMany" hint="Updates the many to many portion of the transfer" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.transfer.getClassName());
		var manytomany = 0;
		var iterator = object.getManyToManyIterator();

		while(iterator.hasNext())
		{
			manytomany = iterator.next();

			//only do the update if it's been loaded
			if(getMethodInvoker().invokeMethod(arguments.transfer, "get" & manytomany.getName() & "isLoaded"))
			{
				deleteManyToMany(arguments.transfer, manytomany);

				insertManyToMany(arguments.transfer, manytomany);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="deleteManyToMany" hint="deletes all the many to many connections" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="manytomany" hint="the many to many to delete" type="transfer.com.object.ManyToMany" required="Yes">
	<cfscript>
		var query = buildDeleteManyToMany(arguments.transfer, arguments.manytomany);
		var queryExec = query.createExecution();
		var object = getObjectManager().getObject(arguments.transfer.getClassName());
		var collection = 0;
		var property = 0;
		var fromLink = 0;
		var toLink = 0;

		if(arguments.manytomany.getLinkFrom().getTo() eq arguments.transfer.getClassName())
		{
			fromLink = arguments.manytomany.getLinkFrom();
			toLink = arguments.manytomany.getLinkTo();
		}
		else
		{
			toLink = arguments.manytomany.getLinkFrom();
			fromLink = arguments.manytomany.getLinkTo();
		}

		collection = arguments.manytomany.getCollection();

		if(collection.hasCondition() AND NOT collection.getCondition().hasWhere())
		{
			property = toLink.getToObject().getPropertyByName(collection.getCondition().getProperty());
			queryExec.setParam("property:" & arguments.manytomany.getName() & ":" & property.getName(), arguments.manytomany.getCollection().getCondition().getValue());
		}

		setPrimaryKey(queryExec, arguments.transfer);

		queryExec.execute();

		getQueryExecutionPool().recycle(queryExec);
	</cfscript>
</cffunction>

<cffunction name="buildDeleteManyToMany" hint="builds the many to many delete" access="private" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="manytomany" hint="the many to many to delete" type="transfer.com.object.ManyToMany" required="Yes">
	<cfscript>
		var key = "delete.update.manytomany." & arguments.transfer.getClassName() & "." & arguments.manytomany.getName();
		var query = 0;
		var object = 0;
		var composite = 0;
		var fromLink = 0;
		var toLink = 0;
		var condition = 0;
		var property = 0;
	</cfscript>
	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT getQueryCache().hasQuery(key))
			{
				object = getObjectManager().getObject(arguments.transfer.getClassName());

				query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());

				if(arguments.manytomany.getLinkFrom().getTo() eq arguments.transfer.getClassName())
				{
					fromLink = arguments.manytomany.getLinkFrom();
					toLink = arguments.manytomany.getLinkTo();
				}
				else if(arguments.manytomany.getLinkTo().getTo() eq arguments.transfer.getClassName())
				{
					toLink = arguments.manytomany.getLinkFrom();
					fromLink = arguments.manytomany.getLinkTo();
				}
				else
				{
					throw("transfer.ManyToManyMisconfiguredException",
							  "There is a error in the ManyToMany configuration.",
							  "In TransferObject '"& object.getClassName() &"' manytomany '"& arguments.manytomany.getName() &"' does not link back to the containing object defintion.");
				}

				query.start();

				query.appendSQL("DELETE FROM ");
				query.appendSQL(arguments.manytomany.getTable());
				query.appendSQL(" WHERE ");

				mapPrimaryKey(query, object, fromLink.getColumn());

				if(arguments.manytomany.getCollection().hasCondition())
				{
					condition = arguments.manytomany.getCollection().getCondition();
					composite = getObjectManager().getObject(toLink.getTo());

					query.appendSQL(" AND ");
					query.appendSQL(arguments.manytomany.getLinkTo().getColumn());
					query.appendSQL(" IN ");
					query.appendSQL("(");
						query.appendSQL(" SELECT ");
						query.appendSQL(composite.getPrimaryKey().getColumn());
						query.appendSQL(" FROM ");
						query.appendSQL(composite.getTable());
						query.appendSQL(" WHERE ");

						if(condition.hasWhere())
						{
							query.appendSQL(getTQLConverter().replaceProperties(composite, condition.getWhere()));
						}
						else
						{
							property = composite.getPropertyByName(condition.getProperty());
							query.appendSQL(property.getColumn());
							query.appendSQL(" = ");
							query.mapParam("property:" & arguments.manytomany.getName() & ":" & property.getName(),property.getType());
						}

					query.appendSQL(")");
				}

				query.stop();

				getQueryCache().addQuery(key, query);
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn getQueryCache().getQuery(key) />
</cffunction>

<cffunction name="buildInsertManyToMany" hint="builds tehe query for inserting a many to many" access="public" returntype="transfer.com.sql.Query" output="false">
	<cfargument name="object" hint="the object that the insert is for" type="transfer.com.object.Object" required="Yes">
	<cfargument name="manytomany" hint="the many to many that is being inserted" type="transfer.com.object.ManyToMany" required="Yes">
	<cfscript>
		var query = 0;
		var key = "insert.update.manytomany." & arguments.object.getClassName() & "." & arguments.manytomany.getName();
		var composite = 0;
	</cfscript>
	<cfif NOT getQueryCache().hasQuery(key)>
		<cflock name="transfer.#key#" throwontimeout="true" timeout="60">
			<cfscript>
				if(NOT getQueryCache().hasQuery(key))
				{
					query = createObject("component", "transfer.com.sql.Query").init(getQueryExecutionPool());

					query.start();
					query.appendSQL("INSERT INTO ");
					query.appendSQL(arguments.manytomany.getTable());
					query.appendSQL(" ( ");
					query.appendSQL(arguments.manyToMany.getLinkFrom().getColumn());
					query.appendSQL(" , ");
					query.appendSQL(arguments.manyToMany.getLinkTo().getColumn());
					query.appendSQL(" ) ");
					query.appendSQL(" VALUES ");
					query.appendSQL(" ( ");

					composite = getObjectManager().getObject(arguments.manytomany.getLinkFrom().getTo());
					query.mapParam("from-key:" & composite.getClassName(), composite.getPrimaryKey().getType());

					query.appendSQL(" , ");

					composite = getObjectManager().getObject(arguments.manytomany.getLinkTo().getTo());
					query.mapParam("to-key:" & composite.getClassName(), composite.getPrimaryKey().getType());

					query.appendSQL(" ) ");
					query.stop();

					getQueryCache().addQuery(key, query);
				}
			</cfscript>
		</cflock>
	</cfif>
	<cfreturn getQueryCache().getQuery(key) />
</cffunction>

<cffunction name="insertManyToMany" hint="Updates the many to many portion of the transfer" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="The transferObject to update" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="manytomany" hint="the many to many to delete" type="transfer.com.object.ManyToMany" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.transfer.getClassName());
		var query = 0;
		var queryExec = 0;
		var collectionIterator = 0;
		var compositeObject = 0;

		query = buildInsertManyToMany(object, arguments.manytomany);

		queryExec = query.createExecution();

		collectionIterator = getMethodInvoker().invokeMethod(transfer, "get" & arguments.manyToMany.getName() & "Iterator");

		while(collectionIterator.hasNext())
		{
			compositeObject = collectionIterator.next();

			if(NOT compositeObject.getIsPersisted())
			{
				throw("transfer.ManyToManyNotCreatedException",
						  "A ManyToMany TransferObject child is not persisted.",
						  "In TransferObject '"& object.getClassName() &"' manytomany '"& compositeObject.getClassName() &"' has not been persisted in the database.");
			}

			if(arguments.manytomany.getLinkFrom().getTo() eq arguments.transfer.getClassName())
			{
				queryExec.setParam("from-key:" & arguments.transfer.getClassName(), invokeGetPrimaryKey(arguments.transfer));
				queryExec.setParam("to-key:" & compositeObject.getClassName(), invokeGetPrimaryKey(compositeObject));
			}
			else if(arguments.manytomany.getLinkTo().getTo() eq arguments.transfer.getClassName())
			{
				queryExec.setParam("to-key:" & arguments.transfer.getClassName(), invokeGetPrimaryKey(arguments.transfer));
				queryExec.setParam("from-key:" & compositeObject.getClassName(), invokeGetPrimaryKey(compositeObject));
			}
			else
			{
				throw("transfer.ManyToManyMisconfiguredException",
						  "There is a error in the ManyToMany configuration.",
						  "In TransferObject '"& object.getClassName() &"' arguments.manytomany '"& arguments.manytomany.getName() &"' does not link back to the containing object defintion.");
			}

			queryExec.execute();

		}

		getQueryExecutionPool().recycle(queryExec);
	</cfscript>
</cffunction>

<cffunction name="getNullable" access="private" returntype="Nullable" output="false">
	<cfreturn instance.Nullable />
</cffunction>

<cffunction name="setNullable" access="private" returntype="void" output="false">
	<cfargument name="Nullable" type="Nullable" required="true">
	<cfset instance.Nullable = arguments.Nullable />
</cffunction>

<cffunction name="getTQLConverter" access="private" returntype="transfer.com.sql.TQLConverter" output="false">
	<cfreturn instance.TQLConverter />
</cffunction>

<cffunction name="setTQLConverter" access="private" returntype="void" output="false">
	<cfargument name="TQLConverter" type="transfer.com.sql.TQLConverter" required="true">
	<cfset instance.TQLConverter = arguments.TQLConverter />
</cffunction>

</cfcomponent>
