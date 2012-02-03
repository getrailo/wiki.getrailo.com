<!--- Document Information -----------------------------------------------------

Title:      InitWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes the Init function for the definition

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		05/04/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="InitWriter" hint="Writes the Init function for the definition" extends="AbstractBaseWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="InitWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeInit" hint="Writes an Init function" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var iterator = arguments.object.getPropertyIterator();
		var property = 0;
		var manytomany = 0;
		var onetoMany = 0;
		//var qObjects = getObjectManager().getClass NameByOneToManyLinkTo(arguments.object.getClassName());
		var parentObject = 0;
		var primaryKey = arguments.object.getPrimaryKey();

		/* have the mappings now, so can set it specifically */
		arguments.buffer.writeCFFunctionOpen("init", "public", "transfer.com.TransferObject", "Constructor for Transfer class #arguments.object.getClassName()#");
		arguments.buffer.writeCFArgument("transfer", "transfer.com.Transfer", "The Transfer library", true);
		arguments.buffer.writeCFArgument("utility", "transfer.com.util.Utility", "The Utility object", true);
		arguments.buffer.writeCFArgument("nullable", "transfer.com.sql.Nullable", "The Nullable lookup object", true);
		arguments.buffer.writeCFArgument("thisObject", "transfer.com.TransferObject", "What is determined to be the base 'this' object for this TransferObject", true);

		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine("instance = StructNew();");

		//set thisObject
		arguments.buffer.writeLine("setThisObject(arguments.thisObject);");

		//set transfer
		arguments.buffer.writeLine("setTransfer(arguments.transfer);");

		//set util
		arguments.buffer.writeLine("setUtility(arguments.utility);");

		arguments.buffer.writeLine("setSystem(createObject("& q() &"java"& q() &", "& q() &"java.lang.System"& q() &"));");

		//set nullable
		arguments.buffer.writeLine("setNullable(arguments.nullable);");

		arguments.buffer.writeLine("setClassName("& q() & object.getClassName() & q() &");");

		arguments.buffer.writeLine("setIsDirty(true);");
		arguments.buffer.writeLine("setIsPersisted(false);");
		arguments.buffer.writeLine("setIsClone(false);");

		if(NOT primaryKey.getIsComposite())
		{
			writePrimaryKeyDefault(buffer, primaryKey);
		}

		while(iterator.hasNext())
		{
			property = iterator.next();
			arguments.buffer.append("set" & property.getName() & "(");
			switch(property.getType())
			{
				case "string":
					arguments.buffer.append(q() & q());
				break;
				case "numeric":
					arguments.buffer.append("0");
				break;
				case "date":
					arguments.buffer.append("Now()");
				break;
				case "boolean":
					arguments.buffer.append("false");
				break;
				case "uuid":
					arguments.buffer.append("CreateUUID()");
				break;
				case "guid":
					arguments.buffer.append("getUtility().createGUID()");
				break;
				case "binary":
					arguments.buffer.append("getUtility().getEmptyByteArray()");
				break;

				default:
					throw("InvalidPropertyTypeException", "A Property can only be on the types 'string', 'numeric', 'date', 'UUID', 'GUID'", "The current value of '#property.getType()#' is invalid.");
				break;
			}
			arguments.buffer.writeLine(");");
		}

		writeLazyInit(arguments.buffer, arguments.object);

		//do many to many sets
		iterator = arguments.object.getManyToManyIterator();
		while(iterator.hasNext())
		{
			manyToMany = iterator.next();
			writeInitCollection(arguments.buffer, manyToMany.getName(), manyToMany.getCollection());
		}

		//do many to many sets
		iterator = arguments.object.getOneToManyIterator();
		while(iterator.hasNext())
		{
			oneToMany = iterator.next();
			writeInitCollection(arguments.buffer, oneToMany.getName(), oneToMany.getCollection());
		}

		//configure command
		writeConfigureRun(arguments.buffer);

		arguments.buffer.writeLine("return this;");
		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="writeInitCollection" hint="Writes the collection part of the Init" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="name" hint="The name of the collection" type="string" required="Yes">
	<cfargument name="collection" hint="The collection in question" type="transfer.com.object.Collection" required="Yes">

	<cfscript>
		switch(arguments.collection.getType())
		{
			case "array":
				arguments.buffer.writeLine("set" & arguments.name & "Collection(ArrayNew(1));");
				arguments.buffer.writeLine("set" & arguments.name & "IDCollection(StructNew());");
			break;

			case "struct":
				arguments.buffer.writeLine("set" & arguments.name & "Collection(StructNew());");
			break;

			default:
				throw("InvalidCollectionTypeException", "Invalid Collection Type set.", "Valid collection types are only 'struct' or 'array'.");
			break;
		}
	</cfscript>
</cffunction>

<cffunction name="writeLazyInit" hint="Writes the initialisation of lazy loading" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">

	<cfscript>
		var iterator = arguments.object.getManyToManyIterator();

		var manytomany = 0;
		var onetomany = 0;
		var manytoone = 0;
		var parentonetomany = 0;

		var parentObject = 0;

		arguments.buffer.writeLine("setLoaded(StructNew());");

		while(iterator.hasNext())
		{
			manytomany = iterator.next();
			arguments.buffer.writeSetIsLoaded(manytomany.getName(), true);
		}

		iterator = arguments.object.getOneToManyIterator();
		while(iterator.hasNext())
		{
			onetomany = iterator.next();
			arguments.buffer.writeSetIsLoaded(onetomany.getName(), true);
		}

		iterator = arguments.object.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			arguments.buffer.writeSetIsLoaded(manytoone.getName(), true);
		}

		iterator = arguments.object.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			parentObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());
			arguments.buffer.writeSetIsLoaded("Parent" & parentObject.getObjectName(), true);

		}
	</cfscript>
</cffunction>

<cffunction name="writePrimaryKeyDefault" hint="Writes the default values for the primary keys" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="primaryKey" hint="The primary key to set to default" type="transfer.com.object.PrimaryKey" required="Yes">
	<cfscript>
		//write primary key initialisation
		switch(arguments.primaryKey.getType())
		{
			case "numeric":
				arguments.buffer.writeLine("set" & arguments.primaryKey.getName() & "(getNullable().getNullNumeric(getClassName(), " &q()& arguments.primarykey.getName() &q()& "));");
			break;
			case "uuid":
				arguments.buffer.writeLine("set" & arguments.primaryKey.getName() & "(getNullable().getNullUUID(getClassName(), " &q()& arguments.primarykey.getName() &q()& "));");
			break;
			case "guid":
				arguments.buffer.writeLine("set" & arguments.primaryKey.getName() & "(getNullable().getNullGUID(getClassName(), " &q()& arguments.primarykey.getName() &q()& "));");
			break;
			case "boolean":
				arguments.buffer.writeLine("set" & arguments.primaryKey.getName() & "(getNullable().getNullBoolean(getClassName(), " &q()& arguments.primarykey.getName() &q()& "));");
			break;
			case "date":
				arguments.buffer.writeLine("set" & arguments.primaryKey.getName() & "(getNullable().getNullDate(getClassName(), " &q()& arguments.primarykey.getName() &q()& "));");
			break;
			default:
				arguments.buffer.writeLine("set" & arguments.primaryKey.getName() & "(getNullable().getNullString(getClassName(), " &q()& arguments.primarykey.getName() &q()& "));");
		}
	</cfscript>
</cffunction>

<cffunction name="writeConfigureRun" hint="Writes the code that checks to see if there is a 'configure' function, and runs it after the init" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">

	<cfscript>
		arguments.buffer.writeLine("if(StructKeyExists(this, " & q() & "configure" & q() & ") OR StructKeyExists(variables, " & q() & "configure" & q() & "))");
		arguments.buffer.writeLine("{");
		arguments.buffer.writeLine("configure();");
		arguments.buffer.writeLine("}");
	</cfscript>
</cffunction>

</cfcomponent>