<!--- Document Information -----------------------------------------------------

Title:      ObjectWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes out Transfer object defintions

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		15/07/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="ObjectWriter" hint="Object That writes out the definitions">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="ObjectWriter" output="false">
	<cfargument name="definitionPath" hint="Path to where the definitions are kept" type="string" required="Yes">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes">

	<cfscript>
		setDefinitionPath(arguments.definitionPath);

		setInitWriter(createObject("component", "transfer.com.dynamic.definition.InitWriter").init(arguments.objectManager));
		setLazyLoadWriter(createObject("component", "transfer.com.dynamic.definition.LazyLoadWriter").init(arguments.objectManager));
		setPropertyWriter(createObject("component", "transfer.com.dynamic.definition.PropertyWriter").init(arguments.objectManager));
		setSetMementoWriter(createObject("component", "transfer.com.dynamic.definition.SetMementoWriter").init(arguments.objectManager));
		setGetMementoWriter(createObject("component", "transfer.com.dynamic.definition.GetMementoWriter").init(arguments.objectManager));
		setEventActionWriter(createObject("component", "transfer.com.dynamic.definition.EventActionWriter").init(arguments.objectManager));
		setCollectionWriter(createObject("component", "transfer.com.dynamic.definition.CollectionWriter").init(arguments.objectManager));
		setCustomFunctionWriter(createObject("component", "transfer.com.dynamic.definition.CustomFunctionWriter").init(arguments.objectManager));
		setEqualsWriter(createObject("component", "transfer.com.dynamic.definition.EqualsWriter").init(arguments.objectManager));
		setCopyValuesToWriter(createObject("component", "transfer.com.dynamic.definition.CopyValuesToWriter").init(arguments.objectManager));
		setValidateCacheStateWriter(createObject("component", "transfer.com.dynamic.definition.ValidateCacheStateWriter").init(arguments.objectManager));

		setWrittenFileCache(StructNew());

		return this;
	</cfscript>
</cffunction>

<cffunction name="hasDefinition" hint="Checks to see if the defintion has been written" access="public" returntype="boolean" output="false">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">

	<cfif NOT StructKeyExists(getWrittenFileCache(), arguments.object.getClassName())>
		<cflock name="transfer.Objectcache.hasDefinition.#object.getClassName()#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT StructKeyExists(getWrittenFileCache(), arguments.object.getClassName()))
			{
				if(fileExists(getDefinitionPath() & getDefinitionFileName(arguments.object)))
				{
					//put in an arbitrary value
					StructInsert(getWrittenFileCache(), arguments.object.getClassName(), 1);

					return true;
				}
				else
				{
					return false;
				}
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn true />
</cffunction>

<cffunction name="getDefinitionFileName" hint="Creates the name that the file defition will be saved under" access="public" returntype="string" output="false">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		//used the $ symbol to look like UDF & CFC Java class name.
		return arguments.object.getClassName() & "$" & arguments.object.getHash() & ".transfer";
	</cfscript>
</cffunction>

<cffunction name="writeDefinition" hint="Writes the defintion to the .transfer file" access="public" returntype="void" output="false">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var buffer = createObject("component", "transfer.com.dynamic.definition.DefinitionBuffer").init();
		var fileWriter = createObject("component", "transfer.com.io.FileWriter").init(getDefinitionPath()& "/" & getDefinitionFileName(arguments.object));

		//init
		getInitWriter().writeInit(buffer, arguments.object);

		//equals
		getEqualsWriter().writeEquals(buffer, arguments.object);


		//observers (no more!)
		//getInitWriter().writeInitEvent(buffer, arguments.object);

		//id
		getPropertyWriter().writePrimaryKey(buffer, arguments.object);

		//properties
		getPropertyWriter().writeProperties(buffer, arguments.object);

		//loaders
		getLazyLoadWriter().writeLazyLoad(buffer, arguments.object);

		//write the setMemento
		getSetMementoWriter().writeSetMemento(buffer, arguments.object);

		//write the getMemento
		getGetMementoWriter().writeGetMemento(buffer, arguments.object);

		//copyValuesTo()
		getCopyValuesToWriter().writeCopyValuesTo(buffer, arguments.object);

		//many to one
		getCollectionWriter().writeManyToOne(buffer, arguments.object);

		//write many to many
		getCollectionWriter().writeManyToMany(buffer, arguments.object);

		//write one to many
		getCollectionWriter().writeOneToMany(buffer, arguments.object);

		//write the one to many that is hooked into this object
		getCollectionWriter().writeExternalOneToMany(buffer, arguments.object);

		//write custom functions
		getCustomFunctionWriter().writeCustomFunctions(buffer, arguments.object);

		//write the validate cache state
		getValidateCacheStateWriter().writeValidateCacheState(buffer, arguments.object);

		//write the event handlers
		getEventActionWriter().writeActionAfterCreateTransferEvent(buffer, arguments.object);

		getEventActionWriter().writeActionAfterDeleteTransferEvent(buffer, arguments.object);

		getEventActionWriter().writeActionAfterUpdateTransferEvent(buffer, arguments.object);

		getEventActionWriter().writeActionAfterDiscardTransferEvent(buffer, arguments.object);

		fileWriter.write(buffer.toDefintionString());

		//since we've written it, we can cache it
		StructInsert(getWrittenFileCache(), arguments.object.getClassName(), 1);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getDefinitionPath" access="private" returntype="string" output="false">
	<cfreturn instance.DefinitionPath />
</cffunction>

<cffunction name="setDefinitionPath" access="private" returntype="void" output="false">
	<cfargument name="DefinitionPath" type="string" required="true">
	<cfset instance.DefinitionPath = arguments.DefinitionPath />
</cffunction>

<cffunction name="getSetMementoWriter" access="private" returntype="transfer.com.dynamic.definition.SetMementoWriter" output="false">
	<cfreturn instance.SetMementoWriter />
</cffunction>

<cffunction name="setSetMementoWriter" access="private" returntype="void" output="false">
	<cfargument name="SetMementoWriter" type="transfer.com.dynamic.definition.SetMementoWriter" required="true">
	<cfset instance.SetMementoWriter = arguments.SetMementoWriter />
</cffunction>

<cffunction name="getGetMementoWriter" access="private" returntype="transfer.com.dynamic.definition.GetMementoWriter" output="false">
	<cfreturn instance.GetMementoWriter />
</cffunction>

<cffunction name="setGetMementoWriter" access="private" returntype="void" output="false">
	<cfargument name="GetMementoWriter" type="transfer.com.dynamic.definition.GetMementoWriter" required="true">
	<cfset instance.GetMementoWriter = arguments.GetMementoWriter />
</cffunction>

<cffunction name="getPropertyWriter" access="private" returntype="transfer.com.dynamic.definition.PropertyWriter" output="false">
	<cfreturn instance.PropertyWriter />
</cffunction>

<cffunction name="setPropertyWriter" access="private" returntype="void" output="false">
	<cfargument name="PropertyWriter" type="transfer.com.dynamic.definition.PropertyWriter" required="true">
	<cfset instance.PropertyWriter = arguments.PropertyWriter />
</cffunction>

<cffunction name="getEventActionWriter" access="private" returntype="transfer.com.dynamic.definition.EventActionWriter" output="false">
	<cfreturn instance.EventActionWriter />
</cffunction>

<cffunction name="setEventActionWriter" access="private" returntype="void" output="false">
	<cfargument name="EventActionWriter" type="transfer.com.dynamic.definition.EventActionWriter" required="true">
	<cfset instance.EventActionWriter = arguments.EventActionWriter />
</cffunction>

<cffunction name="getCustomFunctionWriter" access="private" returntype="transfer.com.dynamic.definition.CustomFunctionWriter" output="false">
	<cfreturn instance.CustomFunctionWriter />
</cffunction>

<cffunction name="setCustomFunctionWriter" access="private" returntype="void" output="false">
	<cfargument name="CustomFunctionWriter" type="transfer.com.dynamic.definition.CustomFunctionWriter" required="true">
	<cfset instance.CustomFunctionWriter = arguments.CustomFunctionWriter />
</cffunction>

<cffunction name="getCollectionWriter" access="private" returntype="transfer.com.dynamic.definition.CollectionWriter" output="false">
	<cfreturn instance.CollectionWriter />
</cffunction>

<cffunction name="setCollectionWriter" access="private" returntype="void" output="false">
	<cfargument name="CollectionWriter" type="transfer.com.dynamic.definition.CollectionWriter" required="true">
	<cfset instance.CollectionWriter = arguments.CollectionWriter />
</cffunction>

<cffunction name="getInitWriter" access="private" returntype="transfer.com.dynamic.definition.InitWriter" output="false">
	<cfreturn instance.InitWriter />
</cffunction>

<cffunction name="setInitWriter" access="private" returntype="void" output="false">
	<cfargument name="InitWriter" type="transfer.com.dynamic.definition.InitWriter" required="true">
	<cfset instance.InitWriter = arguments.InitWriter />
</cffunction>

<cffunction name="getLazyLoadWriter" access="private" returntype="transfer.com.dynamic.definition.LazyLoadWriter" output="false">
	<cfreturn instance.LazyLoadWriter />
</cffunction>

<cffunction name="setLazyLoadWriter" access="private" returntype="void" output="false">
	<cfargument name="LazyLoadWriter" type="transfer.com.dynamic.definition.LazyLoadWriter" required="true">
	<cfset instance.LazyLoadWriter = arguments.LazyLoadWriter />
</cffunction>

<cffunction name="getEqualsWriter" access="private" returntype="transfer.com.dynamic.definition.EqualsWriter" output="false">
	<cfreturn instance.EqualsWriter />
</cffunction>

<cffunction name="setEqualsWriter" access="private" returntype="void" output="false">
	<cfargument name="EqualsWriter" type="transfer.com.dynamic.definition.EqualsWriter" required="true">
	<cfset instance.EqualsWriter = arguments.EqualsWriter />
</cffunction>

<cffunction name="getCopyValuesToWriter" access="private" returntype="transfer.com.dynamic.definition.CopyValuesToWriter" output="false">
	<cfreturn instance.CopyValuesToWriter />
</cffunction>

<cffunction name="setCopyValuesToWriter" access="private" returntype="void" output="false">
	<cfargument name="CopyValuesToWriter" type="transfer.com.dynamic.definition.CopyValuesToWriter" required="true">
	<cfset instance.CopyValuesToWriter = arguments.CopyValuesToWriter />
</cffunction>

<cffunction name="getValidateCacheStateWriter" access="private" returntype="transfer.com.dynamic.definition.ValidateCacheStateWriter" output="false">
	<cfreturn instance.ValidateCacheStateWriter />
</cffunction>

<cffunction name="setValidateCacheStateWriter" access="private" returntype="void" output="false">
	<cfargument name="ValidateCacheStateWriter" type="transfer.com.dynamic.definition.ValidateCacheStateWriter" required="true">
	<cfset instance.ValidateCacheStateWriter = arguments.ValidateCacheStateWriter />
</cffunction>

<cffunction name="getWrittenFileCache" access="private" returntype="struct" output="false">
	<cfreturn instance.writtenFileCache />
</cffunction>

<cffunction name="setWrittenFileCache" access="private" returntype="void" output="false">
	<cfargument name="writtenFileCache" type="struct" required="true">
	<cfset instance.writtenFileCache = arguments.writtenFileCache />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>