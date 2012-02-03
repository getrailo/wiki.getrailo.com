<!--- Document Information -----------------------------------------------------

Title:      AbstractBaseTransfer.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Abstract base class for all TransferObject related CRUD SQL statements

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		07/08/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Abstract base class for all TransferObject related CRUD SQL statements" output="false">


<cfscript>
	static = StructNew();

	static.equals = " = ";
	static.is = " IS ";
	static.nullString = " NULL ";
</cfscript>
<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="init" hint="Constructor" access="private" returntype="void" output="false">
	<cfargument name="datasource" hint="The datasource BO" type="Datasource" required="Yes">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes">
	<cfargument name="queryExecutionPool" hint="the query execution pool" type="transfer.com.sql.collections.QueryExecutionPool" required="Yes">
	<cfargument name="queryCache" hint="the query object cache" type="transfer.com.sql.collections.QueryCache" required="Yes">
	<cfargument name="transaction" type="transfer.com.sql.transaction.Transaction" required="true" _autocreate="false">
	<cfscript>
		variables.instance = StructNew();

		setDataSource(arguments.datasource);
		setObjectManager(arguments.objectManager);
		setQueryExecutionPool(arguments.queryExecutionPool);
		setQueryCache(arguments.queryCache);
		setTransaction(arguments.transaction);
		setMethodInvoker(createObject("component", "transfer.com.dynamic.MethodInvoker").init());
	</cfscript>
</cffunction>

<cffunction name="invokeGetPrimaryKey" hint="Gets the primary key value from an object" access="private" returntype="any" output="false">
	<cfargument name="transfer" hint="The transfer object to insert" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.transfer.getClassName());

		return getMethodInvoker().invokeMethod(arguments.transfer, "get" & object.getPrimaryKey().getName());
	</cfscript>
</cffunction>

<cffunction name="mapPrimaryKey" hint="maps the primary key to the query" access="private" returntype="void" output="false">
	<cfargument name="query" hint="the query object" type="transfer.com.sql.Query" required="Yes">
	<cfargument name="object" hint="the object for the given transfer" type="transfer.com.object.Object" required="Yes">
	<cfargument name="column" hint="an overwriting column, other than the primary key" type="string" required="no">
	<cfargument name="table" hint="specifies a table" type="string" required="No">
	<cfargument name="ignoreColumn" hint="ignores the column, and just places the mapping" type="boolean" required="No" default="false">
	<cfscript>
		if(arguments.object.getPrimaryKey().getIsComposite())
		{
			mapCompositeKey(argumentCollection=arguments);
		}
		else
		{
			mapSingularKey(argumentCollection=arguments);
		}
	</cfscript>
</cffunction>

<cffunction name="mapSingularKey" hint="maps a singular key" access="private" returntype="void" output="false">
	<cfargument name="query" hint="the query object" type="transfer.com.sql.Query" required="Yes">
	<cfargument name="object" hint="the object for the given transfer" type="transfer.com.object.Object" required="Yes">
	<cfargument name="column" hint="an overwriting column, other than the primary key" type="string" required="no">
	<cfargument name="table" hint="specifies a table" type="string" required="No">
	<cfargument name="ignoreColumn" hint="ignores the column, and just places the mapping" type="boolean" required="No" default="false">
	<cfscript>
		var primaryKey = arguments.object.getPrimaryKey();

		if(NOT arguments.ignoreColumn)
		{
			if(StructKeyExists(arguments, "table"))
			{
				arguments.query.appendSQL(arguments.table);
				arguments.query.appendSQL(".");
			}

			if(StructKeyExists(arguments, "column"))
			{
				arguments.query.appendSQL(arguments.column);
			}
			else
			{
				arguments.query.appendSQL(primaryKey.getColumn());
			}

			//arguments.query.appendSQL(" = ");
		}

		arguments.query.mapParam("primaryKey:" & primaryKey.getName(), primaryKey.getType());
	</cfscript>
</cffunction>

<cffunction name="mapCompositeKey" hint="maps a composite key" access="private" returntype="void" output="false">
	<cfargument name="query" hint="the query object" type="transfer.com.sql.Query" required="Yes">
	<cfargument name="object" hint="the object for the given transfer" type="transfer.com.object.Object" required="Yes">
	<cfargument name="table" hint="specifies a table" type="string" required="No">
	<cfscript>
		var primaryKey = arguments.object.getPrimaryKey();
		var iterator = primaryKey.getPropertyIterator();
		var property = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var composite = 0;
		var isFirst = true;
		var prefix = "compositeKey:";

		while(iterator.hasNext())
		{
			property = iterator.next();

			isFirst = andSeperator(arguments.query, isFirst);

			if(StructKeyExists(arguments, "table"))
			{
				arguments.query.appendSQL(arguments.table);
				arguments.query.appendSQL(".");
			}

			arguments.query.appendSQL(property.getColumn());

			//arguments.query.appendSQL(" = ");

			arguments.query.mapParam(prefix & property.getName(), property.getType());
		}

		iterator = primaryKey.getmanytooneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			composite = getObjectManager().getObject(manytoone.getLink().getTo());

			isFirst = andSeperator(arguments.query, isFirst);

			if(StructKeyExists(arguments, "table"))
			{
				arguments.query.appendSQL(arguments.table);
				arguments.query.appendSQL(".");
			}

			arguments.query.appendSQL(manytoone.getLink().getColumn());
			//arguments.query.appendSQL(" = ");
			arguments.query.mapParam(prefix & manytoone.getName(), composite.getPrimaryKey().getType());
		}

		//give it the start of 'parent', as per composition methods.
		prefix = prefix & "parent";

		iterator = primaryKey.getParentOnetoManyIterator();
		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();
			composite = getObjectManager().getObject(parentOneToMany.getLink().getTo());

			isFirst = andSeperator(arguments.query, isFirst);

			if(StructKeyExists(arguments, "table"))
			{
				arguments.query.appendSQL(arguments.table);
				arguments.query.appendSQL(".");
			}

			arguments.query.appendSQL(parentOneToMany.getLink().getColumn());
			//arguments.query.appendSQL(" = ");
			arguments.query.mapParam(prefix & composite.getObjectName(), composite.getPrimaryKey().getType());
		}
	</cfscript>
</cffunction>

<cffunction name="setPrimaryKey" hint="sets the value of the primary key to the query execution" access="private" returntype="void" output="false">
	<cfargument name="queryExec" hint="the query object" type="transfer.com.sql.QueryExecution" required="Yes">
	<cfargument name="transfer" hint="the transfer object" type="transfer.com.TransferObject" required="No">
	<cfargument name="object" hint="The Object BO" type="transfer.com.object.Object" required="no">
	<cfargument name="key" hint="the key to set the primary key value to" type="any" required="no">
	<cfargument name="setOperator" hint="adds the equals operator" type="boolean" required="No" default="yes">
	<cfscript>
		var primaryKey = 0;

		if(structKeyExists(arguments, "transfer"))
		{
			arguments.object = getObjectManager().getObject(arguments.transfer.getClassName());
		}

		primaryKey = arguments.object.getPrimaryKey();

		if(primaryKey.getIsComposite())
		{
			//if there is a transfer object, we don't need ot check the data type.
			if(StructKeyExists(arguments, "transfer") OR isStruct(arguments.key))
			{
				return setCompositeKey(argumentCollection=arguments);
			}
			else
			{
				throw("transfer.IllegalKeyTypeException", "The key for this class should be a struct", "The key for class '#arguments.object.getClassName()#' should be a struct");
			}
		}
		else
		{
			//if there is a transfer object, we don't need ot check the data type.
			if(StructKeyExists(arguments, "transfer") OR isSimpleValue(arguments.key))
			{
				return setSingularKey(argumentCollection=arguments);
			}
			else
			{
				throw("transfer.IllegalKeyTypeException", "The key for this class should be a simple value", "The key for class '#arguments.object.getClassName()#' should be of simple value");
			}
		}
	</cfscript>
</cffunction>

<cffunction name="setSingularKey" hint="sets the singular key value" access="private" returntype="void" output="false">
	<cfargument name="queryExec" hint="the query object" type="transfer.com.sql.QueryExecution" required="Yes">
	<cfargument name="transfer" hint="the transfer object" type="transfer.com.TransferObject" required="No">
	<cfargument name="object" hint="The Object BO" type="transfer.com.object.Object" required="no">
	<cfargument name="key" hint="the key to set the primary key value to" type="string" required="no">
	<cfargument name="setOperator" hint="adds the equals operator" type="boolean" required="No" default="yes">
	<cfscript>
		var isNull = false;
		var args = StructNew();

		if(StructKeyExists(arguments, "transfer"))
		{
			arguments.object = getObjectManager().getObject(arguments.transfer.getClassName());
			arguments.key = invokeGetPrimaryKey(arguments.transfer);
		}

		args.name = "primaryKey:" & arguments.object.getPrimaryKey().getName();
		args.value = arguments.key;
		args.isNull = (NOT Len(arguments.key));

		if(arguments.setOperator)
		{
			args.operator = equalsString();
		}

		arguments.queryExec.setParam(argumentCollection=args);
	</cfscript>
</cffunction>

<cffunction name="setCompositeKey" hint="sets the composite key value to a query" access="private" returntype="void" output="false">
	<cfargument name="queryExec" hint="the query object" type="transfer.com.sql.QueryExecution" required="Yes">
	<cfargument name="transfer" hint="the transfer object" type="transfer.com.TransferObject" required="No">
	<cfargument name="object" hint="The Object BO" type="transfer.com.object.Object" required="no">
	<cfargument name="key" hint="the key to set the primary key value to" type="struct" required="no">
	<cfscript>
		var args = 0;
		var primaryKey = 0;
		var iterator = 0;
		var property = 0;
		var onetomany = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var composite = 0;
		var prefix = "compositeKey:";
		var ident = 0;

		if(StructKeyExists(arguments, "transfer"))
		{
			arguments.object = getObjectManager().getObject(arguments.transfer.getClassName());

			primaryKey = arguments.object.getPrimaryKey();

			iterator = primaryKey.getPropertyIterator();

			while(iterator.hasNext())
			{
				property = iterator.next();
				args = StructNew();

				//arguments.query.mapParam("compositeKey:" & property.getName(), property.getType());
				args.name = prefix & property.getName();
				ident = property.getName();

				if(property.getIsNullable())
				{
					args.isNull = getMethodInvoker().invokeMethod(arguments.transfer, "get" & property.getName() & "isNull");
				}
				else
				{
					args.isNull = false;
				}


				if(NOT args.isNull)
				{
					args.value = getMethodInvoker().invokeMethod(arguments.transfer, "get" & property.getName());
					args.operator = equalsString();
				}
				else
				{
					args.operator = isString();
					args.mapValueReplace = nullString();
				}

				arguments.queryExec.setParam(argumentCollection=args);
			}

			iterator = primaryKey.getmanytooneIterator();

			while(iterator.hasNext())
			{
				manytoone = iterator.next();
				args = StructNew();

				//arguments.query.mapParam("compositeKey:" & manytoone.getName(), composite.getPrimaryKey().getType());
				args.name = prefix & manytoone.getName();
				ident = manytoone.getName();

				args.isNull = NOT getMethodInvoker().invokeMethod(arguments.transfer, "has" & ident);

				if(NOT args.isNull)
				{
					args.value = invokeGetPrimaryKey(getMethodInvoker().invokeMethod(arguments.transfer, "get" & ident));
					args.operator = equalsString();
				}
				else
				{
					args.operator = isString();
					args.mapValueReplace = nullString();
				}

				arguments.queryExec.setParam(argumentCollection=args);
			}

			iterator = primaryKey.getParentOnetoManyIterator();

			//give the prefix of 'parent' to all parentOnetoMany's
			prefix = prefix & "parent";

			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();
				composite = getObjectManager().getObject(parentOneToMany.getLink().getTo());
				args = StructNew();

				//arguments.query.mapParam("compositeKey:parent" & composite.getObjectName(), composite.getPrimaryKey().getType());
				args.name = prefix & composite.getObjectName();
				ident = "parent" & composite.getObjectName();

				args.isNull = NOT getMethodInvoker().invokeMethod(arguments.transfer, "has" & ident);

				if(NOT args.isNull)
				{
					args.value = invokeGetPrimaryKey(getMethodInvoker().invokeMethod(arguments.transfer, "get" & ident));
					args.operator = equalsString();
				}
				else
				{
					args.operator = isString();
					args.mapValueReplace = nullString();
				}

				arguments.queryExec.setParam(argumentCollection=args);
			}

		}
		else
		{
			primaryKey = arguments.object.getPrimaryKey();

			iterator = primaryKey.getPropertyIterator();

			while(iterator.hasNext())
			{
				property = iterator.next();
				args = StructNew();

				//arguments.query.mapParam("compositeKey:" & property.getName(), property.getType());
				args.name = prefix & property.getName();
				ident = property.getName();

				if(StructKeyExists(arguments.key, ident))
				{
					args.value = arguments.key[ident];
					args.operator = equalsString();
				}
				else
				{
					//args.isNull = true;
					args.operator = isString();
					args.mapValueReplace = nullString();
				}

				arguments.queryExec.setParam(argumentCollection=args);
			}

			iterator = primaryKey.getmanytooneIterator();

			while(iterator.hasNext())
			{
				manytoone = iterator.next();
				args = StructNew();

				//arguments.query.mapParam("compositeKey:" & manytoone.getName(), composite.getPrimaryKey().getType());
				args.name = prefix & manytoone.getName();
				ident = manytoone.getName();

				if(StructKeyExists(arguments.key, ident))
				{
					args.value = arguments.key[ident];
					args.operator = equalsString();
				}
				else
				{
					//args.isNull = true;
					args.operator = isString();
					args.mapValueReplace = nullString();
				}

				arguments.queryExec.setParam(argumentCollection=args);
			}

			iterator = primaryKey.getParentOnetoManyIterator();

			//give the prefix of 'parent' to all parentOnetoMany's
			prefix = prefix & "parent";

			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();
				composite = getObjectManager().getObject(parentOneToMany.getLink().getTo());
				args = StructNew();

				//arguments.query.mapParam("compositeKey:parent" & composite.getObjectName(), composite.getPrimaryKey().getType());
				args.name = prefix & composite.getObjectName();
				ident = "parent" & composite.getObjectName();

				if(StructKeyExists(arguments.key, ident))
				{
					args.value = arguments.key[ident];
					args.operator = equalsString();
				}
				else
				{
					//args.isNull = true;
					args.operator = isString();
					args.mapValueReplace = nullString();
				}

				arguments.queryExec.setParam(argumentCollection=args);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="commaSeperator" hint="seperates values with commas" access="private" returntype="boolean" output="false">
	<cfargument name="query" hint="the query object" type="transfer.com.sql.Query" required="Yes">
	<cfargument name="isFirst" hint="if this is the first request to for the comma" type="boolean" required="Yes">
	<cfscript>
		if(NOT arguments.isFirst)
		{
			arguments.query.appendSQL(",");
		}
		return false;
	</cfscript>
</cffunction>

<cffunction name="andSeperator" hint="seperates mappings with AND" access="private" returntype="boolean" output="false">
	<cfargument name="query" hint="the query object" type="transfer.com.sql.Query" required="Yes">
	<cfargument name="isFirst" hint="if this is the first request to for the comma" type="boolean" required="Yes">
	<cfscript>
		if(NOT arguments.isFirst)
		{
			arguments.query.appendSQL(" AND ");
		}
		return false;
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

<cffunction name="getMethodInvoker" access="private" returntype="transfer.com.dynamic.MethodInvoker" output="false">
	<cfreturn instance.MethodInvoker />
</cffunction>

<cffunction name="setMethodInvoker" access="private" returntype="void" output="false">
	<cfargument name="MethodInvoker" type="transfer.com.dynamic.MethodInvoker" required="true">
	<cfset instance.MethodInvoker = arguments.MethodInvoker />
</cffunction>

<cffunction name="getQueryExecutionPool" access="private" returntype="transfer.com.sql.collections.QueryExecutionPool" output="false">
	<cfreturn instance.QueryExecutionPool />
</cffunction>

<cffunction name="setQueryExecutionPool" access="private" returntype="void" output="false">
	<cfargument name="QueryExecutionPool" type="transfer.com.sql.collections.QueryExecutionPool" required="true">
	<cfset instance.QueryExecutionPool = arguments.QueryExecutionPool />
</cffunction>

<cffunction name="getQueryCache" access="private" returntype="transfer.com.sql.collections.QueryCache" output="false">
	<cfreturn instance.QueryCache />
</cffunction>

<cffunction name="setQueryCache" access="private" returntype="void" output="false">
	<cfargument name="QueryCache" type="transfer.com.sql.collections.QueryCache" required="true">
	<cfset instance.QueryCache = arguments.QueryCache />
</cffunction>

<cffunction name="getTransaction" access="private" returntype="transfer.com.sql.transaction.Transaction" output="false">
	<cfreturn instance.transaction />
</cffunction>

<cffunction name="setTransaction" access="private" returntype="void" output="false">
	<cfargument name="transaction" type="transfer.com.sql.transaction.Transaction" required="true">
	<cfset instance.transaction = arguments.transaction />
</cffunction>

<cffunction name="equalsString" hint="returns ' = '" access="private" returntype="string" output="false">
	<cfreturn static.equals/>
</cffunction>

<cffunction name="isString" hint="returns ' IS '" access="private" returntype="string" output="false">
	<cfreturn static.is/>
</cffunction>

<cffunction name="nullString" hint="returns ' NULL '" access="private" returntype="string" output="false">
	<cfreturn static.nullString />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>