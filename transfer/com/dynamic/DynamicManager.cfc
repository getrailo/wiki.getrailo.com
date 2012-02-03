<!--- Document Information -----------------------------------------------------

Title:      DynamicManager.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Manages dynamic aspects of the Transfer lib

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		10/08/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="DynamicManager" hint="Manages dynamic aspects of the Transfer lib">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="DynamicManager" output="false">
	<cfargument name="dynamicFactory" hint="the dynamic factory" type="transfer.com.dynamic.DynamicFactory" required="Yes" _factoryMethod="getDynamicFactory">
	<cfscript>
		setTransferBuilder(arguments.dynamicFactory.getTransferBuilder());
		setDecoratorBuilder(arguments.dynamicFactory.getDecoratorBuilder());
		setTransferCleaner(arguments.dynamicFactory.getTransferCleaner());
		setKeyRationalise(arguments.dynamicFactory.getKeyRationalise());
		setTransferPopulator(arguments.dynamicFactory.getTransferPopulator());
		setTransferRefresher(arguments.dynamicFactory.getTransferRefresher());
		setObjectTreeWalker(arguments.dynamicFactory.getObjectTreeWalker());


		return this;
	</cfscript>
</cffunction>

<cffunction name="createTransferObject" hint="creates an empty Transfer Object" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="object" hint="The Object business Object" type="transfer.com.object.Object" required="Yes">
	<cfreturn getTransferBuilder().createTransferObject(arguments.object)>
</cffunction>

<cffunction name="createDecorator" hint="creates an empty Transfer Object" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="object" hint="The object def, as the transfer won't know it's class yet" type="transfer.com.object.Object" required="Yes">
	<cfargument name="transfer" hint="The transfer object to decorate" type="transfer.com.TransferObject" required="Yes">
	<cfreturn getDecoratorBuilder().createDecorator(arguments.object, arguments.transfer)>
</cffunction>

<cffunction name="rationaliseKey" hint="rationlises the key, depending on type, to a string" access="public" returntype="string" output="false">
	<cfargument name="class" hint="The name of the class" type="string" required="Yes">
	<cfargument name="key" hint="The key for the id of the data" type="any" required="Yes">
	<cfreturn getKeyRationalise().rationaliseKey(arguments.class, arguments.key) />
</cffunction>

<cffunction name="buildCompositeKeyMapFromQuery" hint="builds a composite key from the query" access="public" returntype="struct" output="false">
	<cfargument name="compositeKey" hint="the composite key obejct" type="transfer.com.object.CompositeKey" required="Yes">
	<cfargument name="query" hint="the query to pull data from, assumed single row" type="query" required="Yes">
	<cfreturn getKeyRationalise().buildCompositeKeyMapFromQuery(arguments.compositeKey, arguments.query) />
</cffunction>

<cffunction name="populate" hint="Populates a Transfer object with query data" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object to populate" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="key" hint="Key for the BO" type="any" required="Yes">
	<cfscript>
		getTransferPopulator().populate(arguments.transfer, arguments.key);
	</cfscript>
</cffunction>

<cffunction name="populateManyToOne" hint="populates many to one data into the object for lazy load" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the manytoone to load" type="string" required="Yes">
	<cfscript>
		if(arguments.transfer.getIsPersisted())
		{
			getTransferPopulator().populateManyToOne(arguments.transfer, arguments.name);
		}
	</cfscript>
</cffunction>

<cffunction name="populateOneToMany" hint="populates onetomany data into the object for lazy load" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the manytoone to load" type="string" required="Yes">
	<cfscript>
		if(arguments.transfer.getIsPersisted())
		{
			getTransferPopulator().populateOneToMany(arguments.transfer, arguments.name);
		}
	</cfscript>
</cffunction>

<cffunction name="populateManyToMany" hint="populates manytomany data into the object for lazy load" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the manytoone to load" type="string" required="Yes">
	<cfscript>
		if(arguments.transfer.getIsPersisted())
		{
			getTransferPopulator().populateManyToMany(arguments.transfer, arguments.name);
		}
	</cfscript>
</cffunction>

<cffunction name="populateParentOneToMany" hint="populates parent onetomany data into the object for lazy load" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer to load into" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="name" hint="The name of the external onetomany to load" type="string" required="Yes">
	<cfscript>
		if(arguments.transfer.getIsPersisted())
		{
			getTransferPopulator().populateParentOneToMany(arguments.transfer, arguments.name);
		}
	</cfscript>
</cffunction>

<cffunction name="cleanTransfer" hint="Takes a transfer, and prepares it for repopulation (resistance in futile)" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="transfer" hint="The transferObject to be cleaned" type="transfer.com.TransferObject" required="Yes">
	<cfreturn getTransferCleaner().cleanTransfer(arguments.transfer)>
</cffunction>

<cffunction name="recycle" hint="Recycles an old Transfer object" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="A cleaned transfer object to be reused" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		getTransferBuilder().recycle(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="refreshInsert" hint="refresh after an insert" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		getTransferRefresher().refreshInsert(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="refreshUpdate" hint="refresh after an insert" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="The transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		getTransferRefresher().refreshUpdate(arguments.transfer);
	</cfscript>
</cffunction>

<cffunction name="visitObjectGraph" hint="visit each of the objects in the graph, calling 'visit({transfer:transferObject, visitArgs1...})' on the visitor for each TransferObject in the graph" access="public" returntype="void" output="false">
	<cfargument name="transfer" hint="the starting object to visit" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="visitor" hint="the visitor object" type="any" required="Yes">
	<cfargument name="visitingMethod" hint="the name of the method that is being visited" type="string" required="Yes">
	<cfargument name="visitArgs" hint="visiting arguments, if there are any" type="struct" required="Yes">
	<cfargument name="depth" hint="the max depth to go to" type="numeric" required="no" default="0">
	<cfargument name="topDown" hint="travel top down, rather than bottom up" type="boolean" required="No" default="true">
	<cfargument name="forceLoading" hint="if not loaded, force loading" type="boolean" required="No" default="false">
	<cfscript>
		getObjectTreeWalker().visit(argumentCollection=arguments);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getTransferBuilder" access="private" returntype="transfer.com.dynamic.TransferBuilder" output="false">
	<cfreturn instance.TransferBuilder />
</cffunction>

<cffunction name="setTransferBuilder" access="private" returntype="void" output="false">
	<cfargument name="TransferBuilder" type="transfer.com.dynamic.TransferBuilder" required="true">
	<cfset instance.TransferBuilder = arguments.TransferBuilder />
</cffunction>

<cffunction name="getDecoratorBuilder" access="private" returntype="transfer.com.dynamic.DecoratorBuilder" output="false">
	<cfreturn instance.DecoratorBuilder />
</cffunction>

<cffunction name="setDecoratorBuilder" access="private" returntype="void" output="false">
	<cfargument name="DecoratorBuilder" type="transfer.com.dynamic.DecoratorBuilder" required="true">
	<cfset instance.DecoratorBuilder = arguments.DecoratorBuilder />
</cffunction>

<cffunction name="getTransferCleaner" access="private" returntype="transfer.com.dynamic.TransferCleaner" output="false">
	<cfreturn instance.TransferCleaner />
</cffunction>

<cffunction name="setTransferCleaner" access="private" returntype="void" output="false">
	<cfargument name="TransferCleaner" type="transfer.com.dynamic.TransferCleaner" required="true">
	<cfset instance.TransferCleaner = arguments.TransferCleaner />
</cffunction>

<cffunction name="getTransferPopulator" access="private" returntype="transfer.com.dynamic.TransferPopulator" output="false">
	<cfreturn instance.TransferPopulator />
</cffunction>

<cffunction name="setTransferPopulator" access="private" returntype="void" output="false">
	<cfargument name="TransferPopulator" type="transfer.com.dynamic.TransferPopulator" required="true">
	<cfset instance.TransferPopulator = arguments.TransferPopulator />
</cffunction>

<cffunction name="getTransferRefresher" access="private" returntype="transfer.com.dynamic.TransferRefresher" output="false">
	<cfreturn instance.TransferRefresher />
</cffunction>

<cffunction name="setTransferRefresher" access="private" returntype="void" output="false">
	<cfargument name="TransferRefresher" type="transfer.com.dynamic.TransferRefresher" required="true">
	<cfset instance.TransferRefresher = arguments.TransferRefresher />
</cffunction>

<cffunction name="getKeyRationalise" access="private" returntype="transfer.com.dynamic.KeyRationalise" output="false">
	<cfreturn instance.KeyRationalise />
</cffunction>

<cffunction name="setKeyRationalise" access="private" returntype="void" output="false">
	<cfargument name="KeyRationalise" type="transfer.com.dynamic.KeyRationalise" required="true">
	<cfset instance.KeyRationalise = arguments.KeyRationalise />
</cffunction>

<cffunction name="getObjectTreeWalker" access="private" returntype="transfer.com.dynamic.ObjectTreeWalker" output="false">
	<cfreturn instance.objectTreeWalker />
</cffunction>

<cffunction name="setObjectTreeWalker" access="private" returntype="void" output="false">
	<cfargument name="objectTreeWalker" type="transfer.com.dynamic.ObjectTreeWalker" required="true">
	<cfset instance.objectTreeWalker = arguments.objectTreeWalker />
</cffunction>

</cfcomponent>