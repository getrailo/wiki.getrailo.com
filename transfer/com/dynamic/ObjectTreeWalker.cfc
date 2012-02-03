<cfcomponent hint="Allows for traversal of object graphs" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="ObjectTreeWalker" output="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="methodInvoker" hint="The method invoker" type="transfer.com.dynamic.MethodInvoker" required="Yes"  _autocreate="false">
	<cfscript>
		setObjectManager(arguments.objectManager);
		setMethodInvoker(arguments.methodInvoker);
		setSystem(createObject("java", "java.lang.System"));

		return this;
	</cfscript>
</cffunction>

<cffunction name="visit" hint="visit each of the objects in the graph" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="the starting object to visit" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="visitor" hint="the visitor object" type="any" required="Yes">
	<cfargument name="visitingMethod" hint="the name of the method that is being visited" type="string" required="Yes">
	<cfargument name="visitArgs" hint="visiting arguments, if there are any" type="struct" required="Yes">
	<cfargument name="depth" hint="the max depth to go to" type="numeric" required="no" default="0">
	<cfargument name="topDown" hint="travel top down, rather than bottom up" type="boolean" required="No" default="true">
	<cfargument name="forceLoading" hint="if not loaded, force loading" type="boolean" required="No" default="false">
	<cfscript>
		traverse(arguments.transfer,
				arguments.visitor,
				arguments.visitingMethod,
				arguments.visitArgs,
				arguments.depth,
				arguments.topDown,
				arguments.forceLoading);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="traverse" hint="traverses the object graph" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="the starting object to visit" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="visitor" hint="the visitor object" type="any" required="Yes">
	<cfargument name="visitingMethod" hint="the name of the method that is being visited" type="string" required="Yes">
	<cfargument name="visitArgs" hint="visiting arguments, if there are any" type="struct" required="Yes">
	<cfargument name="maxDepth" hint="the max depth to go to" type="numeric" required="yes">
	<cfargument name="topDown" hint="travel top down, rather than bottom up" type="boolean" required="yes">
	<cfargument name="forceLoading" hint="if not loaded, force loading" type="boolean" required="yes">
	<cfargument name="currentDepth" hint="the max depth to go to" type="numeric" required="no" default="0">
	<cfargument name="visitedHashs" hint="A struct of the identity hash codes, so we know what has been hit" type="struct" required="No" default="#StructNew()#">
	<cfscript>
		var object = 0;
		var localTransfer = arguments.transfer;
		var iterator = 0;
		var manytomany = 0;
		var manytoone = 0;
		var onetomany = 0;
		var parentOneToMany = 0;
		var name = 0;
		var ident = getSystem().identityHashCode(arguments.transfer);

		if(arguments.maxDepth neq 0 AND arguments.currentDepth gte arguments.maxDepth)
		{
			//past current depth
			return;
		}
		else if(StructKeyExists(arguments.visitedHashs, ident))
		{

			//we've been here before, so don't do it again!
			return;
		}

		arguments.currentDepth = arguments.currentDepth + 1;

		object = getObjectManager().getObject(arguments.transfer.getClassName());

		if(arguments.topDown)
		{
			// --- top down ----

			//external parent
			iterator = object.getParentOneToManyIterator();
			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();
				traverseSingle(localTransfer, "parent" & parentOneToMany.getLink().getToObject().getObjectName(), arguments.forceLoading, arguments);
			}

			//many to one
			iterator = object.getManyToOneIterator();

			while(iterator.hasNext())
			{
				manytoone = iterator.next();
				traverseSingle(localTransfer, manytoone.getName(), arguments.forceLoading, arguments);
			}

			//many to many
			iterator = object.getManyToManyIterator();
			while(iterator.hasNext())
			{
				manytomany = iterator.next();
				traverseCollection(localTransfer, manytomany.getName(), arguments.forceLoading, arguments);
			}

			//object
			//double check we don't do this twice
			if(NOT StructKeyExists(arguments.visitedHashs, ident))
			{
				arguments.transfer = localTransfer;
				visitTransfer(argumentCollection=arguments);
				StructInsert(arguments.visitedHashs, ident, 1);
			}

			//one to many
			iterator = object.getOneToManyIterator();
			while(iterator.hasNext())
			{
				onetomany = iterator.next();
				traverseCollection(localTransfer, onetomany.getName(), arguments.forceLoading, arguments);
			}
		}
		else
		{
			// -- bottom up ---

			//one to many
			iterator = object.getOneToManyIterator();
			while(iterator.hasNext())
			{
				onetomany = iterator.next();
				traverseCollection(localTransfer, onetomany.getName(), arguments.forceLoading, arguments);
			}

			//many to many
			iterator = object.getManyToManyIterator();
			while(iterator.hasNext())
			{
				manytomany = iterator.next();
				traverseCollection(localTransfer, manytomany.getName(), arguments.forceLoading, arguments);
			}

			/*
			since bottom up only gets used for deletes, we have to force loading
			of m2o and parent o2m's before we delete the object, so that they are
			available to also delete.
			*/
			if(arguments.forceLoading)
			{
				//many to one
				iterator = object.getManyToOneIterator();
				while(iterator.hasNext())
				{
					manytoone = iterator.next();
					invokeHas(localTransfer, manytoone.getName());
				}

				//parent
				iterator = object.getParentOneToManyIterator();
				while(iterator.hasNext())
				{
					parentOneToMany = iterator.next();
					invokeHas(localTransfer, "parent" & parentOneToMany.getLink().getToObject().getObjectName());
				}
			}

			//object
			//double check we don't do this twice
			if(NOT StructKeyExists(arguments.visitedHashs, ident))
			{
				arguments.transfer = localTransfer;
				visitTransfer(argumentCollection=arguments);
				StructInsert(arguments.visitedHashs, ident, 1);
			}

			//many to one
			iterator = object.getManyToOneIterator();
			while(iterator.hasNext())
			{
				manytoone = iterator.next();
				traverseSingle(localTransfer, manytoone.getName(), arguments.forceLoading, arguments);
			}

			//parent
			iterator = object.getParentOneToManyIterator();
			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();
				traverseSingle(localTransfer, "parent" & parentOneToMany.getLink().getToObject().getObjectName(), arguments.forceLoading, arguments);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="traverseSingle" hint="traverses a single link to an object" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="the transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="the name of the collection" type="string" required="Yes">
	<cfargument name="forceLoading" hint="if not loaded, force loading" type="boolean" required="yes">
	<cfargument name="state" hint="the state of the traversal" type="struct" required="Yes">
	<cfscript>
		if((arguments.forceLoading OR getMethodInvoker().invokeMethod(arguments.transfer, "get" & arguments.name & "isLoaded"))
			AND invokeHas(argumentCollection=arguments))
		{
			arguments.state.transfer = getMethodInvoker().invokeMethod(arguments.transfer, "get" & arguments.name);
			traverse(argumentCollection=arguments.state);
		}
	</cfscript>
</cffunction>

<cffunction name="invokeHas" hint="checks to see if the object has a record for a single collection" access="private" returntype="boolean" output="false">
	<cfargument name="transfer" hint="the transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="the name of the collection" type="string" required="Yes">
	<cfscript>
		return getMethodInvoker().invokeMethod(arguments.transfer, "has" & arguments.name);
	</cfscript>
</cffunction>

<cffunction name="traverseCollection" hint="traverses a collection of objects" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="the transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="the name of the collection" type="string" required="Yes">
	<cfargument name="forceLoading" hint="if not loaded, force loading" type="boolean" required="yes">
	<cfargument name="state" hint="the state of the traversal" type="struct" required="Yes">
	<cfscript>
		var cIterator = 0;

		if(arguments.forceLoading OR getMethodInvoker().invokeMethod(arguments.transfer, "get" & arguments.name & "isLoaded"))
		{
			cIterator = getMethodInvoker().invokeMethod(arguments.transfer, "get" & arguments.name & "Iterator");

			while(cIterator.hasNext())
			{
				arguments.state.transfer = cIterator.next();
				traverse(argumentCollection=arguments.state);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="visitTransfer" hint="visit a single object with the method that is provided" access="private" returntype="void" output="false">
	<cfargument name="transfer" hint="the starting object to visit" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="visitor" hint="the visitor object" type="any" required="Yes">
	<cfargument name="visitingMethod" hint="the name of the method that is being visited" type="string" required="Yes">
	<cfargument name="visitArgs" hint="visiting arguments, if there are any" type="struct" required="Yes">
	<cfscript>
		arguments.visitArgs.transfer = arguments.transfer;

		getMethodInvoker().invokeMethod(arguments.visitor, arguments.visitingMethod, arguments.visitArgs);
	</cfscript>
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getMethodInvoker" access="private" returntype="transfer.com.dynamic.MethodInvoker" output="false">
	<cfreturn instance.methodInvoker />
</cffunction>

<cffunction name="setMethodInvoker" access="private" returntype="void" output="false">
	<cfargument name="methodInvoker" type="transfer.com.dynamic.MethodInvoker" required="true">
	<cfset instance.methodInvoker = arguments.methodInvoker />
</cffunction>

<cffunction name="getSystem" access="private" returntype="any" output="false">
	<cfreturn instance.System />
</cffunction>

<cffunction name="setSystem" access="private" returntype="void" output="false">
	<cfargument name="System" type="any" required="true">
	<cfset instance.System = arguments.System />
</cffunction>


</cfcomponent>