<!--- Document Information -----------------------------------------------------

Title:      LazyLoadWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes the code for lazy loading functionality

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		03/07/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="LazysWriter" hint="Writes the code for lazy loading functionality" extends="AbstractBaseWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="LazyLoadWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeLazyLoad" hint="Writes the lazy load functions" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var iterator = arguments.object.getManyToManyIterator();

		var manytomany = 0;
		var onetomany = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var parentObject = 0;

		while(iterator.hasNext())
		{
			manytomany = iterator.next();
			writeIsLoaded(arguments.buffer, manytomany.getName());
			writeLoadManyToMany(arguments.buffer, arguments.object, manytomany);
			writeUnLoadManyToMany(arguments.buffer, arguments.object, manytomany);
		}

		iterator = arguments.object.getOneToManyIterator();
		while(iterator.hasNext())
		{
			onetomany = iterator.next();
			writeIsLoaded(arguments.buffer, onetomany.getName());
			writeLoadOneToMany(arguments.buffer, arguments.object, onetomany);
			writeUnLoadOneToMany(arguments.buffer, arguments.object, onetomany);
		}

		iterator = arguments.object.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			writeIsLoaded(arguments.buffer, manytoone.getName());
			writeLoadManytoOne(arguments.buffer, arguments.object, manytoone);
			writeUnLoadManytoOne(arguments.buffer, arguments.object, manytoone);
		}

		iterator = arguments.object.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			parentObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());

			writeIsLoaded(arguments.buffer, "Parent" & parentObject.getObjectName());
			writeLoadExternalOnetoMany(arguments.buffer, arguments.object, parentObject.getObjectName());
			writeUnLoadExternalOnetoMany(arguments.buffer, arguments.object, parentObject.getObjectName());
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="writeLoadManyToOne" hint="Writes the lazy load functions" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="manytoone" hint="The one to many object" type="transfer.com.object.manytoone" required="Yes">
	<cfscript>
		writeLoad(arguments.buffer, arguments.object, arguments.manytoone.getName(), "loadManyToOne");
	</cfscript>
</cffunction>

<cffunction name="writeUnLoadManyToOne" hint="Writes the unload functions" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="manytoone" hint="The one to many object" type="transfer.com.object.manytoone" required="Yes">
	<cfscript>
		writeUnLoad(arguments.buffer, arguments.object, arguments.manytoone.getName(), false);
	</cfscript>
</cffunction>

<cffunction name="writeLoadOneToMany" hint="Writes the lazy load functions" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="onetomany" hint="The one to many object" type="transfer.com.object.onetomany" required="Yes">
	<cfscript>
		writeLoad(arguments.buffer, arguments.object, arguments.onetomany.getName(), "loadOneToMany");
	</cfscript>
</cffunction>

<cffunction name="writeUnLoadOneToMany" hint="Writes the unload functions" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="onetomany" hint="The one to many object" type="transfer.com.object.onetomany" required="Yes">
	<cfscript>
		writeUnLoad(arguments.buffer, arguments.object, arguments.onetomany.getName());
	</cfscript>
</cffunction>

<cffunction name="writeLoadManyToMany" hint="Writes the lazy load functions" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="manytomany" hint="The one to many object" type="transfer.com.object.manytomany" required="Yes">
	<cfscript>
		writeLoad(arguments.buffer, arguments.object, arguments.manytomany.getName(), "loadManyToMany");
	</cfscript>
</cffunction>

<cffunction name="writeUnLoadManyToMany" hint="Writes the unload functions" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="manytomany" hint="The one to many object" type="transfer.com.object.manytomany" required="Yes">
	<cfscript>
		writeUnLoad(arguments.buffer, arguments.object, arguments.manytomany.getName());
	</cfscript>
</cffunction>

<cffunction name="writeLoadExternalOnetoMany" hint="writes the lazy load function for external one to may" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="name" hint="The name of the external collection" type="string" required="Yes">
	<cfscript>
		writeLoad(arguments.buffer, arguments.object, "Parent" & arguments.name, "loadParentOneToMany");
	</cfscript>
</cffunction>

<cffunction name="writeUnLoadExternalOnetoMany" hint="writes the unload function for external one to may" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="name" hint="The name of the external collection" type="string" required="Yes">
	<cfscript>
		writeUnLoad(arguments.buffer, arguments.object, "Parent" & arguments.name, false);
	</cfscript>
</cffunction>

<cffunction name="writeLoad" hint="Generic load() function writer" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="name" hint="The name of the compostion" type="string" required="Yes">
	<cfargument name="loadMethod" hint="The method to call to load from Transfer.cfc" type="string" required="Yes">
	<cfscript>
		//make this package, so I can call it from within things, without the extra overhead of loading it into an array or something similar.
		arguments.buffer.writeCFFunctionOpen("load" & arguments.name, "package", "void", "Lazy load composition '#arguments.name#'");

			writeOpenLoadLock(arguments.buffer, arguments.object, arguments.name);
			arguments.buffer.cfscript(true);

				arguments.buffer.writeLine("getTransfer().#arguments.loadMethod#(getThisObject(), "& q()& arguments.name & q()&");");

			arguments.buffer.cfscript(false);
			arguments.buffer.writeDoubleCheckLockClose();

		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeUnLoad" hint="Writes the unload functions" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="name" hint="The name of the compostion" type="string" required="Yes">
	<cfargument name="collection" hint="if it's a collection" type="boolean" required="no" default="true">
	<cfscript>
		arguments.buffer.writeCFFunctionOpen("unLoad" & arguments.name, "private", "void", "unload lazy load composition '#arguments.name#'");

			writeOpenLoadLock(arguments.buffer, arguments.object, arguments.name, true);
			arguments.buffer.cfscript(true);

				//should go first, so that nothing can load in the empty collection
				arguments.buffer.writeSetIsLoaded(arguments.name, false);

				//if collection configure
				if(arguments.collection)
				{
					arguments.buffer.writeLine("empty" & arguments.name & "();");
				}
				else
				{
					arguments.buffer.writeLine('StructDelete(instance, "'& arguments.name &'");');
				}

			arguments.buffer.cfscript(false);
			arguments.buffer.writeDoubleCheckLockClose();

		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeOpenLoadLock" hint="writes the loading double check lock lock" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="name" hint="The name of the compostion" type="string" required="Yes">
	<cfargument name="isLoaded" hint="check the lock if it's loaded, or not" type="boolean" required="No" default="false">
	<cfscript>
		var check = "get" & arguments.name & "isLoaded()";

		if(NOT arguments.isLoaded)
		{
			check = "NOT " & check;
		}

		arguments.buffer.writeDoubleCheckLockOpen(check,
				"transfer.load." & arguments.object.getClassName() & "." & arguments.name & ".##getSystem().identityHashCode(this)##");
	</cfscript>
</cffunction>

<cffunction name="writeIsLoaded" hint="Writes the set of get/set IsLoaded Methods" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="name" hint="The name of the collection" type="string" required="Yes">

	<cfscript>
		arguments.buffer.writeCFFunctionOpen("get" & arguments.name & "isLoaded", "public", "boolean", "Whether or not the composition '#arguments.name#' has been loaded yet");
		arguments.buffer.cfscript("true");
		arguments.buffer.writeLine("if(NOT StructKeyExists(getLoaded(), " & q() & arguments.name & q() &"))");
		arguments.buffer.writeLine("{");
		arguments.buffer.writeLine("set" & arguments.name & "isLoaded(false);");
		arguments.buffer.writeLine("}");
		arguments.buffer.writeline("return StructFind(getLoaded(), " & q() & arguments.name & q() &");");
		arguments.buffer.cfscript("false");
		arguments.buffer.writeCFFunctionClose();


		arguments.buffer.writeCFFunctionOpen("set" & arguments.name & "isLoaded", "private" ,"void", "Set the loaded state of composition 'arguments.name'");
		arguments.buffer.writeCFArgument("loaded", "boolean", "Whether or not this composition has been loaded" ,true);
		arguments.buffer.cfScript(true);
		arguments.buffer.writeLine("StructInsert(getLoaded(), " & q() & arguments.name & q() &", arguments.loaded, true);");
		arguments.buffer.cfScript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

</cfcomponent>