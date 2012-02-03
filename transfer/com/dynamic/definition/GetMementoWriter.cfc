<!--- Document Information -----------------------------------------------------

Title:      GetMementoWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes the setMemento part of the Defintion

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		05/04/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="GetMementoWriter" hint="Writes the memento part of the Defintion" extends="AbstractBaseWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="GetMementoWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeGetMemento" hint="Writes the getMemento function" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var primaryKey = arguments.object.getPrimaryKey();
		var property = 0;
		var manytoone = 0;
		var onetomany = 0;
		var manytomany = 0;
		var linkObject = 0;
		var parentOneToMany = 0;
		var parentObject = 0;
		var iterator = 0;

		arguments.buffer.writeCFFunctionOpen("getMemento", "public", "struct", "Returns the memento for all non-lazy members of this object");
		arguments.buffer.cfscript(true);

		//start it off
		arguments.buffer.writeLine('var memento = createObject("java", "java.util.HashMap").init();');
		if(primaryKey.getIsComposite())
		{
			arguments.buffer.writeLine('var compositeKey = createObject("java", "java.util.HashMap").init();');
		}

		//do id
		primaryKey = arguments.object.getPrimaryKey();
		if(NOT primaryKey.getIsComposite())
		{
			arguments.buffer.writeLine('StructInsert(memento, "'& primaryKey.getName() &'", get'& primaryKey.getName() &'());');
		}

		//do if its persisted or dirty
		arguments.buffer.writeLine('StructInsert(memento, "transfer_isDirty", getIsDirty());');
		arguments.buffer.writeLine('StructInsert(memento, "transfer_isPersisted", getIsPersisted());');
		arguments.buffer.writeLine('StructInsert(memento, "transfer_isProxied", false);');

		arguments.buffer.writeLine("StructAppend(memento, getPropertyMemento());");

		//do many to one
		iterator = arguments.object.getManyToOneIterator();
		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			if(NOT manytoone.getIsLazy())
			{
				arguments.buffer.writeLine('StructInsert(memento, "'& manytoone.getName() &'", get'& manytoone.getName() &'Memento());');
			}
		}

		//do many to many
		iterator = arguments.object.getManyToManyIterator();
		while(iterator.hasNext())
		{
			manytomany = iterator.next();

			if(NOT manytomany.getIsLazy())
			{
				arguments.buffer.writeLine('StructInsert(memento, "'& manytomany.getName() &'", get'& manytomany.getName() &'Memento());');
			}
		}

		//do one to many
		iterator = arguments.object.getOneToManyIterator();
		while(iterator.hasNext())
		{
			onetomany = iterator.next();

			if(NOT onetomany.getIsLazy())
			{
				arguments.buffer.writeLine('StructInsert(memento, "'& onetomany.getName() &'", get'& onetomany.getName() &'Memento());');
			}
		}

		//need the id of the composite id's in external parents
		if(primaryKey.getIsComposite())
		{
			//do external one to many's
			iterator = arguments.object.getParentOneToManyIterator();

			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();

				if(primaryKey.containsParentOneToManyByName(parentOneToMany.getName()))
				{
					arguments.buffer.writeLine("StructAppend(memento, getParent"& parentOneTomany.getLink().getToObject().getObjectName() & "Memento());");
				}
			}

			iterator = primaryKey.getPropertyIterator();

			while(iterator.hasNext())
			{
				property = iterator.next();
				arguments.buffer.writeLine('StructInsert(compositeKey, "'& property.getName() &'", get'& property.getName() &'());');
			}

			iterator = primaryKey.getManyToOneIterator();

			while(iterator.hasNext())
			{
				manytoone = iterator.next();
				arguments.buffer.writeLine("if(has"& manytoone.getName() &"())");
				arguments.buffer.writeLine("{");
					arguments.buffer.append('StructInsert(compositeKey, "'& manytoone.getName() &'", ');
					arguments.buffer.writeLine('get'& manytoone.getName() &'().get'& manytoone.getLink().getToObject().getPrimaryKey().getName() &'());');
				arguments.buffer.writeLine("}");
			}

			iterator = primaryKey.getParentOneToManyIterator();

			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();
				parentObject = parentOneToMany.getLink().getToObject();

				arguments.buffer.writeLine("if(hasParent"& parentObject.getObjectName() &"())");
				arguments.buffer.writeLine("{");
					arguments.buffer.append('StructInsert(compositeKey, "parent'& parentObject.getObjectName() &'", ');
					arguments.buffer.writeLine('getParent'&parentObject.getObjectName() &'().get' & parentObject.getPrimaryKey().getName() & '());');
				arguments.buffer.writeLine("}");
			}

			arguments.buffer.writeLine('StructInsert(memento, "'& primaryKey.getName() &'", compositeKey);');
		}

		arguments.buffer.writeLine("return memento;");

		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();

		//property memento
		writePropertyMemento(arguments.buffer, arguments.object);

		/* external one to many links */
		iterator = arguments.object.getParentOneToManyIterator();
		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			parentObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());

			writeExternalOneToManyMemento(arguments.buffer, parentObject);
		}

		//do many to one
		iterator = arguments.object.getManyToOneIterator();
		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			writeManyToOneMemento(arguments.buffer, manytoone);
		}

		//do many to many
		iterator = arguments.object.getManyToManyIterator();
		while(iterator.hasNext())
		{
			manytomany = iterator.next();
			writeManyToManyMemento(arguments.buffer, arguments.object, manytomany);
		}

		//do one to many
		iterator = arguments.object.getOneToManyIterator();
		while(iterator.hasNext())
		{
			onetomany = iterator.next();
			writeOneToManyMemento(arguments.buffer, arguments.object, onetomany);
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="writePropertyMemento" hint="Writes the memento for just properties" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="The object that is the parent" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var iterator = arguments.object.getPropertyIterator();
		var property = 0;

		arguments.buffer.writeCFFunctionOpen("getPropertyMemento", "public", "struct", "returns the memento for properties");
		arguments.buffer.cfscript(true);

		arguments.buffer.writeLine('var memento = createObject("java", "java.util.HashMap").init();');

		//properties
		while(iterator.hasNext())
		{
			property = iterator.next();
			arguments.buffer.writeLine('StructInsert(memento, "'& property.getName() &'", get'& property.getName() &'());');
		}

		//no duplicate is required, as the assignment operator provides a copy by value
		arguments.buffer.writeLine("return memento;");

		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeManyToOneMemento" hint="writes the one to many memento setter" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="manytoone" hint="The one to many object" type="transfer.com.object.manytoone" required="Yes">
	<cfscript>
		var composite = getObjectManager().getObject(arguments.manytoone.getLink().getTo());

		arguments.buffer.writeCFFunctionOpen("get" & arguments.manytoone.getName() & "Memento", "public", "struct", "returns the memento for manytoone " & arguments.manytoone.getName());
		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine('var memento = createObject("java", "java.util.HashMap").init();');

		arguments.buffer.writeLine("if(has"& arguments.manytoone.getName() &"())");
		arguments.buffer.writeLine("{");
		arguments.buffer.writeLine('memento = get'& arguments.manytoone.getName() &'().getMemento();');
		arguments.buffer.writeLine("}");

		arguments.buffer.writeLine("return memento;");

		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeManyToManyMemento" hint="writes the one to many memento setter" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="The parent object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="manytomany" hint="The manytomany object" type="transfer.com.object.manytomany" required="Yes">
	<cfscript>
		var composite = getObjectManager().getObject(arguments.manytomany.getLinkTo().getTo());

		arguments.buffer.writeCFFunctionOpen("get" & arguments.manytomany.getName() & "Memento", "public", "array", "returns the memento for the manytomany " & arguments.manytomany.getName());
		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine('var memento = createObject("java", "java.util.ArrayList").init();');
		arguments.buffer.writeLine("var iterator = get" & arguments.manytomany.getName() & "Iterator();");
		arguments.buffer.writeLine("var item = 0;");

		arguments.buffer.writeLine("while(iterator.hasNext())");
		arguments.buffer.writeLine("{");
			arguments.buffer.writeLine("item = iterator.next();");
			arguments.buffer.writeLine("ArrayAppend(memento, item.getMemento());");
		arguments.buffer.writeLine("}");

		arguments.buffer.writeLine("return memento;");

		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeOneToManyMemento" hint="writes the one to many memento setter" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="The parent object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="onetomany" hint="The onetomany object" type="transfer.com.object.onetomany" required="Yes">
	<cfscript>
		var composite = getObjectManager().getObject(arguments.onetomany.getLink().getTo());

		arguments.buffer.writeCFFunctionOpen("get" & arguments.onetomany.getName() & "Memento", "public", "array", "returns the memento for the onetomany " & arguments.onetomany.getName());
		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine('var memento = createObject("java", "java.util.ArrayList").init();');
		arguments.buffer.writeLine("var iterator = get" & arguments.onetomany.getName() & "Iterator();");
		arguments.buffer.writeLine("var item = 0;");

		arguments.buffer.writeLine("while(iterator.hasNext())");
		arguments.buffer.writeLine("{");
			arguments.buffer.writeLine("item = iterator.next();");
			arguments.buffer.writeLine("ArrayAppend(memento, item.getMemento());");
		arguments.buffer.writeLine("}");

		arguments.buffer.writeLine("return memento;");

		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeExternalOneToManyMemento" hint="Writes the memento for external manytoones" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="parentObject" hint="The parent object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var primaryKey = arguments.parentObject.getPrimaryKey();

		arguments.buffer.writeCFFunctionOpen("getParent" & arguments.parentObject.getObjectName() & "Memento", "public", "struct", "returns the memento for the parent onetomany " & arguments.parentObject.getClassName());
		arguments.buffer.cfscript(true);

		arguments.buffer.writeLine('var memento = createObject("java", "java.util.HashMap").init();');

		arguments.buffer.writeLine("if(hasParent" & arguments.parentObject.getObjectName() & "())");
		arguments.buffer.writeLine("{");
			arguments.buffer.append('StructInsert(memento, "parent'& arguments.parentObject.getObjectName() &'_'& primaryKey.getName() &'", ');
			arguments.buffer.writeLine('getParent'& arguments.parentObject.getObjectName() &'().get'& primaryKey.getName() &'());');

		arguments.buffer.writeLine("}");

		arguments.buffer.writeLine("return memento;");

		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

</cfcomponent>