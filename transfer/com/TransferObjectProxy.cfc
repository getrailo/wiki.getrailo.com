<!--- Document Information -----------------------------------------------------

Title:      TransferObjectProxy.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    a Proxy for Transfer Objects

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		27/06/2008		Created

------------------------------------------------------------------------------->

<cfcomponent hint="A Proxy for TransferObjects" extends="transfer.com.TransferObject" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransferObjectProxy" output="false">
	<cfargument name="className" hint="the class name of the proxy" type="string" required="Yes">
	<cfargument name="key" hint="the primary key value" type="any" required="Yes">
	<cfargument name="object" hint="the object that represents this Transfer Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="transfer" hint="the transfer lib" type="transfer.com.Transfer" required="Yes">
	<cfargument name="dynamicManager" hint="the dynamic manager" type="transfer.com.dynamic.DynamicManager" required="Yes">
	<cfargument name="propertyMap" hint="a property map of values that are stored for sorting, and structure keys" type="struct" required="Yes">
	<cfscript>
		setClassName(arguments.className);
		setKey(arguments.key);
		setTransfer(arguments.Transfer);
		setFlatKey(getTransfer().rationaliseKey(arguments.className, arguments.key));
		setSystem(createObject("java", "java.lang.System"));
		setDynamicManager(arguments.dynamicManager);
		setPropertyMap(arguments.propertyMap);

		setPrimaryKey(arguments.object.getPrimaryKey());
		setPrimaryKeyMethod("get" & getPrimaryKey().getName());

		setIsLoaded(false);
		setIsClone(false);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getIsPersisted" access="public" hint="If this object is stored in the database" returntype="boolean" output="false">
	<cfscript>
		if(getIsLoaded())
		{
			return proxy("getIsPersisted");
		}

		return true;
	</cfscript>
</cffunction>

<cffunction name="getIsDirty" access="public" hint="If this object's data is differnt from that stored in the DB." returntype="boolean" output="false">
	<cfscript>
		if(getIsLoaded())
		{
			return proxy("getIsDirty");
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="clone" hint="Get a deep clone of this object" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfscript>
		return proxy("clone");
	</cfscript>
</cffunction>

<cffunction name="getOriginalTransferObject" hint="Returns the underlying TransferObject, will never return the proxy, or the decorator (forces a load)" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="returnProxyOnNotLoaded" hint="if the proxied object is not loaded, force a return of the proxy instead.  This is used for setIsDirty, setIsPersisted and setIsClone"
				type="boolean" required="No" default="false">
	<cfscript>
		if(arguments.returnProxyOnNotLoaded AND NOT getIsLoaded())
		{
			return this;
		}

		return proxy("getOriginalTransferObject");
	</cfscript>
</cffunction>

<cffunction name="getIsProxy" hint="returns whether or not this is a proxy object" access="public" returntype="boolean" output="false">
	<cfreturn true />
</cffunction>

<cffunction name="getIsLoaded" access="public" hint="Whether or not the proxy has loaded the the object its proxying" returntype="boolean" output="false">
	<cfreturn instance.isLoaded />
</cffunction>

<cffunction name="getLoadedObject" hint="Returns the proxied object.  This will force a loading of the object" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfscript>
		if(NOT getIsLoaded())
		{
			return proxy("getLoadedObject");
		}

		return getTransferObject();
	</cfscript>
</cffunction>

<cffunction	name="onMissingMethod" access="public" returntype="any" output="false" hint="wires the invocation to the tranfserObject proxy">
	<cfargument	name="missingMethodName" type="string"	required="true"	hint=""	/>
	<cfargument	name="missingMethodArguments" type="struct" required="true"	hint=""/>
	<cfscript>
		if(NOT getIsLoaded())
		{
			if(arguments.missingMethodName.startsWith("get") AND StructKeyExists(getPropertyMap(), ReplaceNoCase(arguments.missingMethodName, "get", "")))
			{
				return StructFind(getPropertyMap(), ReplaceNoCase(arguments.missingMethodName, "get", ""));
			}
		}

		if(arguments.missingMethodName eq getPrimaryKeyMethod())
		{
			return getFlatKey();
		}
		else
		{
			return proxy(arguments.missingMethodName, arguments.missingMethodArguments);
		}
	</cfscript>
</cffunction>

<cffunction name="getMemento" hint="If not loaded, returns the proxy memento, else, proxy's the method" access="public" returntype="struct" output="false">
	<cfscript>
		if(getIsLoaded())
		{
			return proxy("getMemento");
		}
		else
		{
			return getProxyMemento();
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<cffunction name="setIsClone" access="package" returntype="void" output="false">
	<cfargument name="isClone" type="boolean" required="true">
	<cfscript>
		if(getIsLoaded())
		{
			//do it this way, as package method protection would stop us otherwise
			getOriginalTransferObject().setIsClone(argumentCollection=arguments);
		}
		else
		{
			super.setIsClone(arguments.isClone);
		}
	</cfscript>
</cffunction>

<cffunction name="setIsPersisted" access="package" returntype="void" output="false">
	<cfargument name="isPersisted" type="boolean" required="true">
	<cfscript>
		if(NOT (getIsLoaded() OR arguments.isPersisted))
		{
			//do it this way, as package method protection would stop us otherwise
			getOriginalTransferObject().setIsPersisted(argumentCollection=arguments);
		}
	</cfscript>
</cffunction>

<cffunction name="setIsDirty" access="package" returntype="void" output="false">
	<cfargument name="isDirty" type="boolean" required="true">
	<cfscript>
		if((getIsLoaded() OR arguments.isDirty))
		{
			//do it this way, as package method protection would stop us otherwise
			getOriginalTransferObject().setIsDirty(argumentCollection=arguments);
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getProxyMemento" hint="returns the memento for this proxy" access="private" returntype="struct" output="false">
	<cfscript>
		var memento = createObject("java", "java.util.HashMap").init();

		StructInsert(memento, "transfer_isPersisted", true);
		StructInsert(memento, "transfer_isDirty", false);
		StructInsert(memento, "transfer_isProxied", true);
		StructInsert(memento, getPrimaryKey().getName(), getKey());

		StructInsert(memento, "propertyMap", getPropertyMap());

		return memento;
	</cfscript>
</cffunction>

<cffunction name="proxy" hint="proxy a method, and arguments" access="private" returntype="any" output="false">
	<cfargument name="methodName" hint="the method name" type="string" required="Yes">
	<cfargument name="args" hint="the arguments" type="struct" required="No" default="#StructNew()#">

	<cfset var local = StructNew() />

	<cfif NOT getIsLoaded()>
		<cflock name="transfer.transferObjectProxy.load.#getSystem().identityHashcode(this)#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT getIsLoaded())
			{
				local.transferObject = getTransfer().new(getClassName());

				//populate the object
				getDynamicManager().populate(local.transferObject, getKey());

				//set to non dirty, and persisted
				local.transferObject.getOriginalTransferObject().setIsDirty(false);
				local.transferObject.getOriginalTransferObject().setIsPersisted(true);
				local.transferObject.getOriginalTransferObject().setIsClone(getIsClone());

				setTransferObject(local.transferObject);

				setIsLoaded(true);

				//clean up a bit of memory
				StructDelete(instance, "propertyMap");
				StructDelete(instance, "key");
			}
		</cfscript>
		</cflock>
	</cfif>

	<cfinvoke component="#getTransferObject()#" method="#arguments.methodName#" argumentcollection="#arguments.args#" returnvariable="local.return">

	<cfif StructKeyExists(local, "return")>
		<cfreturn local.return />
	</cfif>
</cffunction>

<cffunction name="setIsLoaded" access="private" returntype="void" output="false">
	<cfargument name="isLoaded" type="boolean" required="true">
	<cfset instance.isLoaded = arguments.isLoaded />
</cffunction>

<cffunction name="getPrimaryKeyMethod" access="private" returntype="string" output="false">
	<cfreturn instance.PrimaryKeyMethod />
</cffunction>

<cffunction name="setPrimaryKeyMethod" access="private" returntype="void" output="false">
	<cfargument name="PrimaryKeyMethod" type="string" required="true">
	<cfset instance.PrimaryKeyMethod = arguments.PrimaryKeyMethod />
</cffunction>

<cffunction name="getTransferObject" access="private" returntype="transfer.com.TransferObject" output="false">
	<cfreturn instance.transferObject />
</cffunction>

<cffunction name="setTransferObject" access="private" returntype="void" output="false">
	<cfargument name="TransferObject" type="transfer.com.TransferObject" required="true">
	<cfset instance.transferObject = arguments.transferObject />
</cffunction>

<cffunction name="getKey" access="private" returntype="any" output="false">
	<cfreturn instance.key />
</cffunction>

<cffunction name="setKey" access="private" returntype="void" output="false">
	<cfargument name="key" type="any" required="true">
	<cfset instance.key = arguments.key />
</cffunction>

<cffunction name="getFlatKey" access="private" returntype="string" output="false">
	<cfreturn instance.flatKey />
</cffunction>

<cffunction name="setFlatKey" access="private" returntype="void" output="false">
	<cfargument name="flatKey" type="string" required="true">
	<cfset instance.flatKey = arguments.flatKey />
</cffunction>

<cffunction name="getDynamicManager" access="private" returntype="transfer.com.dynamic.DynamicManager" output="false">
	<cfreturn instance.dynamicManager />
</cffunction>

<cffunction name="setDynamicManager" access="private" returntype="void" output="false">
	<cfargument name="dynamicManager" type="transfer.com.dynamic.DynamicManager" required="true">
	<cfset instance.dynamicManager = arguments.dynamicManager />
</cffunction>

<cffunction name="getPropertyMap" access="private" returntype="struct" output="false">
	<cfreturn instance.propertyMap />
</cffunction>

<cffunction name="setPropertyMap" access="private" returntype="void" output="false">
	<cfargument name="propertyMap" type="struct" required="true">
	<cfset instance.propertyMap = arguments.propertyMap />
</cffunction>

<cffunction name="getPrimaryKey" access="private" returntype="transfer.com.object.AbstractBaseKey" output="false">
	<cfreturn instance.PrimaryKey />
</cffunction>

<cffunction name="setPrimaryKey" access="private" returntype="void" output="false">
	<cfargument name="PrimaryKey" type="transfer.com.object.AbstractBaseKey" required="true">
	<cfset instance.PrimaryKey = arguments.PrimaryKey />
</cffunction>

</cfcomponent>