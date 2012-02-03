<!--- Document Information -----------------------------------------------------

Title:      TransferBuilder.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Builds Transfer Objects

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		15/07/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="TransferBuilder" hint="Builds Transfer Object">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransferBuilder" output="false">
	<cfargument name="definitionPath" hint="Path to where the definitions are kept" type="string" required="Yes">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfscript>
		setDefinitionPath(arguments.definitionPath);
		setTransferObjectPool(createObject("component", "transfer.com.dynamic.collections.TransferObjectPool").init(arguments.javaLoader));
		setMethodInjector(arguments.methodInjector);
		setObjectWriter(createObject("component", "transfer.com.dynamic.ObjectWriter").init(expandPath(getDefinitionPath()), arguments.objectManager));

		//setup mixin functions
		instance.mixin = StructNew();
		instance.mixin.buildTransferObject = variables.buildTransferObject;

		getMethodInjector().start(this);
		//remove it
		getMethodInjector().removeMethod(this, "buildTransferObject");

		getMethodInjector().stop(this);

		return this;
	</cfscript>
</cffunction>

<cffunction name="createTransferObject" hint="creates an empty Transfer Object" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="object" hint="The Object business Object" type="transfer.com.object.Object" required="Yes">

	<cfscript>
		//get an object out of the cache
		var transfer = getTransferObjectPool().getTransferObject();
		var injector = getMethodInjector();
	</cfscript>

	<!--- let's double lock this down, so we don't get two people trying to write files at the same time --->
	<cfif NOT getObjectWriter().hasDefinition(object)>
		<cflock name="transfer.writeDefinition.#arguments.object.getClassName()#" throwontimeout="yes" timeout="60">
		<cfscript>
			//make sure the defintion file has been written
			if(NOT getObjectWriter().hasDefinition(object))
			{
				//if not, write it
				getObjectWriter().writeDefinition(object);
			}
		</cfscript>
		</cflock>
	</cfif>

	<cfscript>
		//build the object
		injector.start(transfer);

		injector.injectMethod(transfer, instance.mixin.buildTransferObject);
		transfer.buildTransferObject(arguments.object, injector, getDefinitionPath() & getObjectWriter().getDefinitionFileName(object));

		injector.stop(transfer);

		return transfer;
	</cfscript>
</cffunction>


<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getTransferObjectPool" access="private" returntype="transfer.com.dynamic.collections.TransferObjectPool" output="false">
	<cfreturn variables.TransferObjectPool />
</cffunction>

<cffunction name="setTransferObjectPool" access="private" returntype="void" output="false">
	<cfargument name="TransferObjectPool" type="transfer.com.dynamic.collections.TransferObjectPool" required="true">
	<cfset variables.TransferObjectPool = arguments.TransferObjectPool />
</cffunction>

<cffunction name="getMethodInjector" access="private" returntype="MethodInjector" output="false">
	<cfreturn instance.MethodInjector />
</cffunction>

<cffunction name="setMethodInjector" access="private" returntype="void" output="false">
	<cfargument name="MethodInjector" type="MethodInjector" required="true">
	<cfset instance.MethodInjector = arguments.MethodInjector />
</cffunction>

<cffunction name="getObjectWriter" access="private" returntype="ObjectWriter" output="false">
	<cfreturn instance.ObjectWriter />
</cffunction>

<cffunction name="setObjectWriter" access="private" returntype="void" output="false">
	<cfargument name="ObjectWriter" type="ObjectWriter" required="true">
	<cfset instance.ObjectWriter = arguments.ObjectWriter />
</cffunction>

<!--- mixin functions --->
<cffunction name="buildTransferObject" hint="Mixin Function to build the transfer object" access="public" returntype="void" output="false">
	<cfargument name="Object" hint="The Object BO" type="transfer.com.object.Object" required="Yes">
	<cfargument name="methodInjector" hint="The method injector" type="methodInjector" required="Yes">
	<cfargument name="transferFileName" hint="The name the transfer file is" type="string" required="Yes">

	<cfscript>
		//init vars
		var key = 0;
		var item = 0;
	</cfscript>

	<!--- include the file --->
	<cftry>
		<cfinclude template="#arguments.transferFileName#">
		<cfcatch type="any">
			<cfthrow type="transfer.#cfcatch.type#" message="Error found in: #arguments.transferFileName#" detail="#cfcatch.message# : #cfcatch.detail#">
		</cfcatch>
	</cftry>

	<cfscript>
		/*
			let's get really lazy, because otherwise this going to get really complicated.
			loops around variables scope, if it's a UDF, inject it, if it's not
			leave it alone.
		*/

		for(key in variables)
		{
			item = variables[key];

			if(isCustomFunction(item))
			{
				arguments.methodInjector.injectMethod(this, item);
			}
		}

		//remove myself
		arguments.methodInjector.removeMethod(this, "buildTransferObject");
	</cfscript>
</cffunction>

<cffunction name="recycle" hint="Recycles an old Transfer object" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="A cleaned transfer object to be reused" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		getTransferObjectPool().recycleTransferObject(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="getDefinitionPath" access="private" returntype="string" output="false">
	<cfreturn instance.DefinitionPath />
</cffunction>

<cffunction name="setDefinitionPath" access="private" returntype="void" output="false">
	<cfargument name="DefinitionPath" type="string" required="true">
	<cfset instance.DefinitionPath = arguments.DefinitionPath />
</cffunction>

</cfcomponent>