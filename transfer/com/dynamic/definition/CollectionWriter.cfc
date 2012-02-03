<!--- Document Information -----------------------------------------------------

Title:      CollectionWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes out the collection/composition aspects of the defition

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		05/04/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="CollectionWriter" hint="Writes out the collection/composition aspects of the defition" extends="AbstractBaseWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="CollectionWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeManyToOne" hint="Writes the definition for Many to One." access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var iterator = arguments.object.getManyToOneIterator();
		var manyToOne = 0;

		while(iterator.hasNext())
		{
			manyToOne = iterator.next();

			//get
			arguments.buffer.writeCFFunctionOpen("get" & manyToOne.getName(), "public", "transfer.com.TransferObject", "Accessor for #manytoone.getName()#, #manytoone.getLink().getToObject().getClassName()#");
			arguments.buffer.cfscript(true);

			//lazy loading
			arguments.buffer.writeLazyLoad(manytoone.getName());

			arguments.buffer.writeLine("if(NOT structKeyExists(instance, " & q() & manyToOne.getName() & q() & "))");
			arguments.buffer.writeLine("{");
			arguments.buffer.writeLine(	"throw("& q() &"ManyToOneNotSetException"& q() &","&
										q() & "A ManyToOne TransferObject has not been initialised."& q() &","&
										q() & "In TransferObject '"& arguments.object.getClassName() &"' manytoone '"& manytoone.getLink().getTo() &"' does not exist, when calling get"& manytoone.getName() &"()"& q() &");");
			arguments.buffer.writeLine("}");
			arguments.buffer.writeLine("return instance." & manyToOne.getName() & ";");
			arguments.buffer.cfscript(false);
			arguments.buffer.writeCFFunctionClose();

			//set
			arguments.buffer.writeCFFunctionOpen("set" & manyToOne.getName(), "public", "void", "Mutator for #manytoone.getName()#, #manytoone.getLink().getToObject().getClassName()#");
			arguments.buffer.writeCFArgument("transfer", "transfer.com.TransferObject", "The #manytoone.getLink().getToObject().getClassName()# to set", true);
			arguments.buffer.cfscript(true);

			arguments.buffer.writeTransferClassCheck("arguments.transfer", manyToOne.getLink().getTo());
			//arguments.buffer.writeLine("if(NOT StructKeyExists(instance, " & q() & manyToOne.getName() & q() & ") OR NOT get" & manyToOne.getName() & "().equalsTransfer(arguments.transfer))");
			arguments.buffer.writeLine("if((NOT get" & manyToOne.getName() & "isLoaded()) OR (NOT (StructKeyExists(instance, " & q() & manyToOne.getName() & q() & ") AND get" & manyToOne.getName() & "().equalsTransfer(arguments.transfer))))");
			arguments.buffer.writeLine("{");
			arguments.buffer.writeLine("instance." & manyToOne.getName() & " = arguments.transfer;");
			arguments.buffer.writeSetIsDirty(true);
			arguments.buffer.writeSetIsLoaded(manyToOne.getName(), true);
			arguments.buffer.writeLine("}");
			arguments.buffer.cfscript(false);
			arguments.buffer.writeCFFunctionClose();

			arguments.buffer.writeCFFunctionOpen("has" & manyToOne.getName(), "public", "boolean", "Whether or not this object contains a #manytoone.getLink().getToObject().getClassName()#");
			arguments.buffer.cfscript(true);
			arguments.buffer.writeLazyLoad(manytoone.getName());
			arguments.buffer.writeLine("return StructKeyExists(instance," & q() & manyToOne.getName() &  q() & ");");
			arguments.buffer.cfscript(false);
			arguments.buffer.writeCFFunctionClose();

			arguments.buffer.writeCFFunctionOpen("remove" & manyToOne.getName(), "public", "void", "remove the instance of #manytoone.getLink().getToObject().getClassName()#");
			arguments.buffer.cfscript(true);
			arguments.buffer.writeLine("if(NOT get" & manyToOne.getName() & "isLoaded() OR has"& manyToOne.getName() &"())");
			arguments.buffer.writeLine("{");
			arguments.buffer.writeLine("StructDelete(instance," & q() & manyToOne.getName() &  q() & ");");
			arguments.buffer.writeSetIsDirty(true);
			arguments.buffer.writeSetIsLoaded(manyToOne.getName(), true);
			arguments.buffer.writeLine("}");
			arguments.buffer.cfscript(false);
			arguments.buffer.writeCFFunctionClose();
		}
	</cfscript>
</cffunction>

<cffunction name="writeManyToMany" hint="Writes the definition for Many to Many files" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var iterator = arguments.object.getManyToManyIterator();
		var manyToMany = 0;
		var linkObject = 0;

		while(iterator.hasNext())
		{
			manyToMany = iterator.next();
			linkObject = getObjectManager().getObject(manyToMany.getLinkTo().getTo());

			writeCollection(arguments.buffer, manyToMany.getName(), manyToMany.getCollection() ,linkObject);
			writeRemoveAddAndClear(arguments.buffer, arguments.object, manyToMany.getName(), manyToMany.getCollection() ,linkObject, "public");

			if(manytomany.getCollection().getType() eq "array")
			{
				writeSort(arguments.buffer, arguments.object, manytomany.getName(), manytomany.getLinkTo(), manytomany.getCollection());
			}
		}
	</cfscript>
</cffunction>

<cffunction name="writeOneToMany" hint="writes the defintion of One to Many files" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var iterator = arguments.object.getOneToManyIterator();
		var oneToMany = 0;
		var linkObject = 0;

		while(iterator.hasNext())
		{
			oneToMany = iterator.next();
			linkObject = getObjectManager().getObject(oneToMany.getLink().getTo());

			writeCollection(arguments.buffer, oneToMany.getName(), oneToMany.getCollection() ,linkObject);
			writeRemoveAddAndClear(arguments.buffer, arguments.object, oneToMany.getName(), oneToMany.getCollection() ,linkObject, "package");
			if(onetomany.getCollection().getType() eq "array")
			{
				writeSort(arguments.buffer, arguments.object, onetomany.getName(), onetomany.getLink(), onetomany.getCollection(), "public");
			}
		}
	</cfscript>
</cffunction>

<cffunction name="writeExternalOneToMany" hint="write the methods for where this object hook into a one to many" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var parentObject = 0;
		var primaryKey = 0;
		var iterator = arguments.object.getParentOneToManyIterator();
		var parentOneToMany = 0;

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			parentObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());
			primaryKey = parentObject.getPrimaryKey();

			arguments.buffer.writeCFFunctionOpen("getParent" & parentObject.getObjectName(), "public", "transfer.com.TransferObject", "Access for parent #arguments.object.getClassName()#");
			arguments.buffer.cfscript(true);
			arguments.buffer.writeLazyLoad("Parent" & parentObject.getObjectName());
			arguments.buffer.writeLine("if(NOT structKeyExists(instance, " & q() & parentObject.getObjectName() & q() & "))");
			arguments.buffer.writeLine("{");
			arguments.buffer.writeLine(	"throw("& q() &"OneToManyParentNotSetException"& q() &","&
										q() & "A OneToMany Parent TransferObject has not been initialised."& q() &","&
										q() & "In TransferObject '"& arguments.object.getClassName() &"' onetomany parent '"& parentObject.getClassName() &"' does not exist, when calling getParent"& parentObject.getObjectName() &"()"& q() &");");
			arguments.buffer.writeLine("}");
			arguments.buffer.writeLine("return instance." & parentObject.getObjectName() & ";");
			arguments.buffer.cfscript(false);
			arguments.buffer.writeCFFunctionClose();

			//set
			arguments.buffer.writeCFFunctionOpen("setParent" & parentObject.getObjectName(), "public", "void", "Mutator for parent #arguments.object.getClassName()#");
			arguments.buffer.writeCFArgument("transfer", "transfer.com.TransferObject", "the object to set as parent", true);
			arguments.buffer.writeCFArgument("loadChildren", "boolean", "Expert/Transfer use only: whether or not to load the children.", false, true);
			arguments.buffer.writeCFArgument("loadingFromMemento", "boolean", "Expert/Transfer use only: if this is loading from a memento or not", false, false);
			arguments.buffer.cfscript(true);

				arguments.buffer.writeTransferClassCheck("arguments.transfer", parentObject.getClassName());

				arguments.buffer.writeLine("if(NOT getParent" & parentObject.getObjectName() & "IsLoaded() OR NOT hasParent" & parentObject.getObjectName() & "() OR NOT getParent" & parentObject.getObjectName() & "().equalsTransfer(arguments.transfer))");
				arguments.buffer.writeLine("{");
					arguments.buffer.writeLine("if(getParent" & parentObject.getObjectName() & "IsLoaded() AND hasParent"  & parentObject.getObjectName() & "())");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("removeParent" & parentObject.getObjectName() & "();");
					arguments.buffer.writeLine("}");

					arguments.buffer.writeLine("instance." & parentObject.getObjectName() & " = arguments.transfer;");
					arguments.buffer.writeSetIsLoaded("Parent" & parentObject.getObjectName(), true);
					arguments.buffer.writeSetIsDirty(true);
				arguments.buffer.writeLine("}");
				arguments.buffer.writeLine("else if(NOT getParent" & parentObject.getObjectName() & "().sameTransfer(arguments.transfer))");
				arguments.buffer.writeLine("{");
					arguments.buffer.writeLine("instance." & parentObject.getObjectName() & " = arguments.transfer;");
				arguments.buffer.writeLine("}");

				arguments.buffer.append("if(arguments.loadChildren");
				arguments.buffer.writeLine(" AND NOT getParent" & parentObject.getObjectName() & "().getOriginalTransferObject().get"& parentOneToMany.getName() &"IsLoaded())");
				arguments.buffer.writeLine("{");
				/*
				just grab an aray (which we always have), so it loads. It's a bit iffy, but I'm happy with it.
				there were just too many issues with trying to boolean resolve so the contains would fire.
				This tells a better story
				*/

				arguments.buffer.writeLine("getParent" & parentObject.getObjectName() & "().getOriginalTransferObject().load"& parentOneToMany.getName() & "();");
				arguments.buffer.writeLine("}");

				//this may or may not be here, as it may be lazy loaded
				arguments.buffer.append("if(getParent" & parentObject.getObjectName() & "().getOriginalTransferObject().get"& parentOneToMany.getName() &"IsLoaded()");
				arguments.buffer.writeLine("AND NOT getParent" & parentObject.getObjectName() & "().getOriginalTransferObject().contains"& parentOneToMany.getName() &"(getThisObject(), arguments.loadingFromMemento))");
				arguments.buffer.writeLine("{");
					arguments.buffer.writeLine("getParent" & parentObject.getObjectName() & "().getOriginalTransferObject().add" & parentOneToMany.getName() & "(getThisObject());");
				arguments.buffer.writeLine("}");

			arguments.buffer.cfscript(false);
			arguments.buffer.writeCFFunctionClose();

			//has
			arguments.buffer.writeCFFunctionOpen("hasParent" & parentObject.getObjectName(), "public", "boolean", "Whether or not this object has a parent #arguments.object.getClassName()#");
			arguments.buffer.cfscript(true);
			arguments.buffer.writeLazyLoad("Parent" & parentObject.getObjectName());
			arguments.buffer.writeLine("return StructKeyExists(instance," & q() & parentObject.getObjectName() &  q() & ");");
			arguments.buffer.cfscript(false);
			arguments.buffer.writeCFFunctionClose();

			//remove
			arguments.buffer.writeCFFunctionOpen("removeParent" & parentObject.getObjectName(), "public", "void", "Remove the parent #arguments.object.getClassName()# from this object");
			arguments.buffer.cfscript(true);

			//arguments.buffer.writeLazyLoad("Parent" & parentObject.getObjectName());
			arguments.buffer.writeLine("if(getParent"& parentObject.getObjectName()  &"isLoaded() AND hasParent"& parentObject.getObjectName() &"())");
			arguments.buffer.writeLine("{");
				arguments.buffer.writeLine("getParent" & parentObject.getObjectName() & "().getOriginalTransferObject().remove" & parentOneToMany.getName() & "(getThisObject());");
			arguments.buffer.writeLine("}");
			/*
				with clone sync, it is possible that the setmemento() method will set the isLoaded from the parent
				to false,so the first set will fail, but the 2nd won't.
			*/
			arguments.buffer.writeLine('else if(StructKeyExists(instance, "'& parentObject.getObjectName() &'"))');
			arguments.buffer.writeLine("{");
				arguments.buffer.writeLine("instance." & parentObject.getObjectName() & ".getOriginalTransferObject().remove" & parentOneToMany.getName() & "(getThisObject());");
			arguments.buffer.writeLine("}");

			arguments.buffer.writeSetIsDirty(true);
			arguments.buffer.writeLine("StructDelete(instance," & q() & parentObject.getObjectName() &  q() & ");");
			arguments.buffer.writeSetIsLoaded("Parent" & parentObject.getObjectName(), true);

			arguments.buffer.cfscript(false);
			arguments.buffer.writeCFFunctionClose();
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="writeCollection" hint="Writes the methods for a collection" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="name" hint="The name of the collection" type="string" required="Yes">
	<cfargument name="collection" hint="The Collection of the composite type" type="transfer.com.object.Collection" required="Yes">
	<cfargument name="linkObject" hint="The Object the link points to" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		//getter and setter for the array/struct
		arguments.buffer.writeCFFunctionOpen("get" & arguments.name & "Collection", "private", arguments.collection.getType(),
											"Accessor for the internal collection for #arguments.name#");
		arguments.buffer.writeCFScriptBlock("return instance." & arguments.name & ";");
		arguments.buffer.writeCFFunctionClose();

		arguments.buffer.writeCFFunctionOpen("set" & arguments.name & "Collection", "private", "void",
											"Mutator for the internal collection for #arguments.name#");
		arguments.buffer.writeCFArgument(arguments.name, arguments.collection.getType(), "The #arguments.collection.getType()# to set", true);
		arguments.buffer.writeCFScriptBlock("instance." & arguments.name & " = arguments." & arguments.name & ";");
		arguments.buffer.writeCFFunctionClose();

		switch(arguments.collection.getType())
		{
			//do array functions
			case "array":
				//this is for keeping the id's of what is currently stored, for faster contain*() calls
				arguments.buffer.writeCFFunctionOpen("get" & arguments.name & "IDCollection", "private", "struct",
													"Accessor for internal id collection, for faster contain*() calls");
				arguments.buffer.writeLine("<cfreturn instance." & arguments.name & "IDCollection />");
				arguments.buffer.writeCFFunctionClose();

				arguments.buffer.writeCFFunctionOpen("set" & arguments.name & "IDCollection", "private", "void",
													"Mutator for internal id collection, for faster contain*() calls");
					arguments.buffer.writeCFArgument("collection", "struct", "the key for the id to be stored under", true);
					arguments.buffer.writeLine("<cfset instance." & arguments.name & "IDCollection = arguments.collection />");
				arguments.buffer.writeCFFunctionClose();

				//get
				arguments.buffer.writeCFFunctionOpen("get" & arguments.name, "public", "transfer.com.TransferObject",
													"Returns the #linkObject.getClassName()# object at the given index in the array");
				arguments.buffer.writeCFArgument("index", "numeric", "The index in the array to retrieve", true);
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLazyLoad(arguments.name);
					//have to subtract 1, as 0 indexed off the 'get'
					arguments.buffer.writeline("return get"& arguments.name&"Collection().get(JavaCast("& q() & "int" & q() &", arguments.index - 1));");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//get Array
				arguments.buffer.writeCFFunctionOpen("get" & arguments.name & "Array", "public", "array", "returns the entire array of #linkObject.getClassName()#");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLine("var array = ArrayNew(1);");
					arguments.buffer.writeLazyLoad(arguments.name);
					arguments.buffer.writeLine("array.addAll(get"& arguments.name&"Collection());");
					arguments.buffer.writeLine("return array;");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//iterator
				arguments.buffer.writeCFFunctionOpen("get" & arguments.name & "Iterator", "public", "any",
													"return a java.util.Iterator of #linkObject.getClassName()# objects");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLazyLoad(arguments.name);
					arguments.buffer.writeline("return get"& arguments.name&"Array().iterator();");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//contains
				arguments.buffer.writeCFFunctionOpen("contains" & arguments.name, "public", "boolean",
													"If this array contains a particular instance of #linkObject.getClassName()#");
				arguments.buffer.writeCFArgument("object", "transfer.com.TransferObject", "The object to look for", true);
				arguments.buffer.writeCFArgument("pkCheckOnly", "boolean", "Expert/Transfer use only: only checks primary keys", false, "false");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLine("var composite = 0;");
					arguments.buffer.writeLine("var array = get"& arguments.name & "Array();");
					arguments.buffer.writeLine("var counter = 1;");
					arguments.buffer.writeLine("var len = 0;");
					arguments.buffer.writeLine("var check = false;");
					arguments.buffer.writeLine("var idcollection = get" & arguments.name & "idCollection();");

					arguments.buffer.writeTransferClassCheck("arguments.object", arguments.linkObject.getClassName());

					arguments.buffer.writeLine("if(arguments.object.getIsPersisted() AND StructKeyExists(idcollection, "&q()&"pk:"&q()&" & arguments.object.get" & arguments.linkObject.getPrimaryKey().getName() & "()))");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("return true;");
					arguments.buffer.writeLine("}");

					//if we're only doing a pk check, this is because we're setting the memento, and we know all the data is persisted
					arguments.buffer.writeLine("if(arguments.pkCheckOnly)");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("return false;");
					arguments.buffer.writeLine("}");

					arguments.buffer.writeLine("if(StructKeyExists(idcollection, "&q()&"obj:"&q()&" & getSystem().identityHashCode(arguments.object)))");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("check = true;");
					arguments.buffer.writeLine("}");


					arguments.buffer.writeLine("if(NOT check)");
					arguments.buffer.writeLine("{");

						/*
						used the counter here, as it is faster, and this method is hit a lot on
						Transfer Events
						*/
						arguments.buffer.writeLine("len = ArrayLen(array);");
						arguments.buffer.writeLine("for(; counter lte len; counter = counter + 1)");
						arguments.buffer.writeLine("{");
							arguments.buffer.writeLine("composite = array[counter];");
							arguments.buffer.writeLine("if(composite.equalsTransfer(arguments.object))");
							arguments.buffer.writeLine("{");
								arguments.buffer.writeLine("check = true;");
								arguments.buffer.writeLine("break;");
							arguments.buffer.writeLine("}");
						arguments.buffer.writeLine("}");

					arguments.buffer.writeLine("}");

					arguments.buffer.writeLine("if(check AND arguments.object.getIsPersisted())");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("StructInsert(idcollection, "&q()&"pk:"&q()&" & arguments.object.get" & arguments.linkObject.getPrimaryKey().getName() & "(), 1, true);");
					arguments.buffer.writeLine("}");

					arguments.buffer.writeLine("return check;");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//find
				arguments.buffer.writeCFFunctionOpen("find" & arguments.name, "public", "numeric",
													"Find the index number that the given object is at in the Array. Returns -1 if it can't be found.'");
				arguments.buffer.writeCFArgument("object", "transfer.com.TransferObject", "The object to search for", true);
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLine("var iterator = 0;");
					arguments.buffer.writeLine("var composite = 0;");
					arguments.buffer.writeLine("var counter = 0;");
					arguments.buffer.writeLazyLoad(arguments.name);

					arguments.buffer.writeLine("iterator = get"& arguments.name & "Collection().iterator();");

					arguments.buffer.writeTransferClassCheck("arguments.object", arguments.linkObject.getClassName());
					arguments.buffer.writeLine("while(iterator.hasNext())");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("composite = iterator.next();");
						arguments.buffer.writeLine("counter = counter + 1;");
						arguments.buffer.writeLine("if(composite.equalsTransfer(arguments.object))");
						arguments.buffer.writeLine("{");
							arguments.buffer.writeLine("return counter;");
						arguments.buffer.writeLine("}");
					arguments.buffer.writeLine("}");
					arguments.buffer.writeLine("return -1;");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//empty
				arguments.buffer.writeCFFunctionOpen("empty" & arguments.name, "public", "void",
													"empty the collection, with no change to loading'");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLine("ArrayClear(get" & arguments.name & "Collection());");
					arguments.buffer.writeLine("StructClear(get" & arguments.name & "IDCollection());");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();


			break;

			//do struct functions
			case "struct":
				//get
				arguments.buffer.writeCFFunctionOpen("get" & arguments.name, "public", "transfer.com.TransferObject",
													"Returns the #linkObject.getClassName()# object at the given key in the struct");
				arguments.buffer.writeCFArgument("key", "string","The key to look for" , true);

				arguments.buffer.cfscript(true);
					arguments.buffer.writeLazyLoad(arguments.name);
					arguments.buffer.writeline("return StructFind(get" & arguments.name & "Collection(), arguments.key);");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//get Struct
				arguments.buffer.writeCFFunctionOpen("get" & arguments.name & "Struct", "public", "struct",
													"Returns the entire struct of #linkObject.getClassName()#");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLine("var struct = StructNew();");
					arguments.buffer.writeLazyLoad(arguments.name);
					arguments.buffer.writeLine("struct.putAll(get" & arguments.name & "Collection());");
					arguments.buffer.writeLine("return struct;");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//iterator
				arguments.buffer.writeCFFunctionOpen("get" & arguments.name & "Iterator", "public", "any",
													"Return a java.util.Iterator of #linkObject.getClassName()# objects");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLazyLoad(arguments.name);
					arguments.buffer.writeline("return get"& arguments.name&"Struct().values().iterator();");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//contains
				arguments.buffer.writeCFFunctionOpen("contains" & arguments.name, "public", "boolean",
													"If this struct contains a particular instance of #linkObject.getClassName()#");
				arguments.buffer.writeCFArgument("object", "transfer.com.TransferObject", "The object to look for", true);
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLine("var struct = 0;");
					arguments.buffer.writeTransferClassCheck("arguments.object", arguments.linkObject.getClassName());
					arguments.buffer.writeLazyLoad(arguments.name);
					arguments.buffer.writeLine("struct = get" & arguments.name & "Struct();");
					arguments.buffer.writeLine("if(StructKeyExists(struct, arguments.object.get"& arguments.collection.getKey().getProperty() &"()))");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("return struct[arguments.object.get"& arguments.collection.getKey().getProperty() &"()].equalsTransfer(arguments.object);");
					arguments.buffer.writeLine("}");
					arguments.buffer.writeLine("return false;");

				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//find
				arguments.buffer.writeCFFunctionOpen("find" & arguments.name, "public", "string",
													"Find the key that the given object is at in the Struct. Returns '' if it can't be found.'");
				arguments.buffer.writeCFArgument("object", "transfer.com.TransferObject", "The object to find", true);
				arguments.buffer.cfscript(true);
					arguments.buffer.writeTransferClassCheck("arguments.object", arguments.linkObject.getClassName());
					arguments.buffer.writeLine("if(contains" & arguments.name & "(arguments.object))");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("return arguments.object.get"& arguments.collection.getKey().getProperty() &"();");
					arguments.buffer.writeLine("}");
					arguments.buffer.writeLine("return " & q() & q() & ";");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();

				//empty
				arguments.buffer.writeCFFunctionOpen("empty" & arguments.name, "public", "void",
													"empty the collection, with no change to loading'");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeline("StructClear(get" & arguments.name & "Collection());");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeCFFunctionClose();
			break;
		}
	</cfscript>
</cffunction>

<cffunction name="writeRemoveAddAndClear" hint="Writes the remove function" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="name" hint="The name of the collection" type="string" required="Yes">
	<cfargument name="collection" hint="The Collection of the composite type" type="transfer.com.object.Collection" required="Yes">
	<cfargument name="linkObject" hint="The Object the link points to" type="transfer.com.object.Object" required="Yes">
	<cfargument name="scope" hint="Private, or public?" type="string" required="Yes">

	<cfscript>
		switch(arguments.collection.getType())
		{
			case "array":
				//add
				arguments.buffer.writeCFFunctionOpen("add" & arguments.name, arguments.scope, "void", "Add an object of type #arguments.linkObject.getClassName()# to the array");
				arguments.buffer.writeCFArgument("object", "transfer.com.TransferObject", "The object to add", true);
				arguments.buffer.writeNamedLockOpen("transfer." & arguments.object.getClassName() & "." & arguments.name & ".##get" & arguments.object.getPrimaryKey().getName() & "()##");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeTransferClassCheck("arguments.object", arguments.linkObject.getClassName());
					arguments.buffer.writeLazyLoad(arguments.name);

					arguments.buffer.writeLine("if(arguments.object.getIsPersisted())");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("StructInsert(get" & arguments.name & "IDCollection(), "&q()&"pk:"&q()&" & arguments.object.get" & arguments.linkObject.getPrimaryKey().getName() & "(), 1, true);");
					arguments.buffer.writeLine("}");

					arguments.buffer.writeLine("StructInsert(get" & arguments.name & "IDCollection(), "&q()&"obj:"&q()&" & getSystem().identityHashCode(arguments.object), 1, true);");

					arguments.buffer.writeLine("ArrayAppend(get" & arguments.name & "Collection(), arguments.object);");

					//only do if scope is public
					if(scope eq "public")
					{
						arguments.buffer.writeSetIsDirty(true);
					}

				arguments.buffer.cfscript(false);
				arguments.buffer.writeNamedLockClose();
				arguments.buffer.writeCFFunctionClose();

				//remove
				arguments.buffer.writeCFFunctionOpen("remove" & arguments.name, arguments.scope, "void", "remove an object of type #arguments.linkObject.getClassName()# from the array");
				arguments.buffer.writeCFArgument("object", "transfer.com.TransferObject", "the object to remove", true);
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLine("var iterator = 0;");
					arguments.buffer.writeLine("var composite = 0;");
					arguments.buffer.writeTransferClassCheck("arguments.object", arguments.linkObject.getClassName());
				arguments.buffer.cfscript(false);

				arguments.buffer.writeNamedLockOpen("transfer." & arguments.object.getClassName() & "." & arguments.name & ".##get" & arguments.object.getPrimaryKey().getName() & "()##");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeLazyLoad(arguments.name);
					arguments.buffer.writeLine("iterator = get"& arguments.name & "Collection().iterator();");
					arguments.buffer.writeLine("while(iterator.hasNext())");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("composite = iterator.next();");
						arguments.buffer.writeLine("if(composite.equalsTransfer(arguments.object))");
						arguments.buffer.writeLine("{");
							arguments.buffer.writeLine("iterator.remove();");

							arguments.buffer.writeLine("if(arguments.object.getIsPersisted())");
							arguments.buffer.writeLine("{");
								arguments.buffer.writeLine("StructDelete(get" & arguments.name & "IDCollection(), "&q()&"pk:"&q()&" & arguments.object.get" & arguments.linkObject.getPrimaryKey().getName() & "());");
							arguments.buffer.writeLine("}");

							arguments.buffer.writeLine("StructDelete(get" & arguments.name & "IDCollection(), "&q()&"obj:"&q()&" & getSystem().identityHashCode(arguments.object));");

							//only do if scope is public
							if(scope eq "public")
							{
								arguments.buffer.writeSetIsDirty(true);
							}

							arguments.buffer.writeLine("return;");
						arguments.buffer.writeLine("}");
					arguments.buffer.writeLine("}");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeNamedLockClose();

				arguments.buffer.writeCFFunctionClose();

				//clear
				arguments.buffer.writeCFFunctionOpen("clear" & arguments.name, arguments.scope, "void", "Clear all the elements from the array");

				arguments.buffer.writeNamedLockOpen("transfer." & arguments.object.getClassName() & "." & arguments.name & ".##get" & arguments.object.getPrimaryKey().getName() & "()##");
				arguments.buffer.cfscript(true);
					//arguments.buffer.writeLine("ArrayClear(get" & arguments.name & "Collection());");
					//arguments.buffer.writeLine("StructClear(get" & arguments.name & "IDCollection());");
					arguments.buffer.writeLine("empty" & arguments.name & "();");

					//only do if scope is public
					if(scope eq "public")
					{
						arguments.buffer.writeSetIsDirty(true);
						arguments.buffer.writeSetIsLoaded(arguments.name, true);
					}
				arguments.buffer.cfscript(false);
				arguments.buffer.writeNamedLockClose();
				arguments.buffer.writeCFFunctionClose();
			break;

			case "struct":
				//add
				arguments.buffer.writeCFFunctionOpen("add" & arguments.name, arguments.scope, "void", "add an object of type #arguments.linkObject.getClassName()# to the struct");
				arguments.buffer.writeCFArgument("object", "transfer.com.TransferObject", "The object to add", true);

				arguments.buffer.writeNamedLockOpen("transfer." & arguments.object.getClassName() & "." & arguments.name & ".##get" & arguments.object.getPrimaryKey().getName() & "()##");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeTransferClassCheck("arguments.object", arguments.linkObject.getClassName());
					arguments.buffer.writeLazyLoad(arguments.name);
					arguments.buffer.writeLine("StructInsert(get" & arguments.name & "Collection(), arguments.object.get" & arguments.collection.getKey().getProperty() &"(), arguments.object, true);");
					//only do if scope is public
					if(scope eq "public")
					{
						arguments.buffer.writeSetIsDirty(true);
					}
				arguments.buffer.cfscript(false);
				arguments.buffer.writeNamedLockClose();
				arguments.buffer.writeCFFunctionClose();

				//remove
				arguments.buffer.writeCFFunctionOpen("remove" & arguments.name, arguments.scope, "void", "remove an object of type #arguments.linkObject.getClassName()# from the struct");
				arguments.buffer.writeCFArgument("object", "transfer.com.TransferObject", "the object to remove", true);
				arguments.buffer.writeNamedLockOpen("transfer." & arguments.object.getClassName() & "." & arguments.name & ".##get" & arguments.object.getPrimaryKey().getName() & "()##");
				arguments.buffer.cfscript(true);
					arguments.buffer.writeTransferClassCheck("arguments.object", arguments.linkObject.getClassName());
					arguments.buffer.writeLine("if(contains" & arguments.name & "(arguments.object))");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("structDelete(get"& arguments.name & "Collection(), arguments.object.get"& arguments.collection.getKey().getProperty() &"());");
						//only do if scope is public
						if(scope eq "public")
						{
							arguments.buffer.writeSetIsDirty(true);
						}
					arguments.buffer.writeLine("}");
				arguments.buffer.cfscript(false);
				arguments.buffer.writeNamedLockClose();
				arguments.buffer.writeCFFunctionClose();

				//clear
				arguments.buffer.writeCFFunctionOpen("clear" & arguments.name, arguments.scope, "void", "Clear all the elements from the struct");
				arguments.buffer.writeNamedLockOpen("transfer." & arguments.object.getClassName() & "." & arguments.name & ".##get" & arguments.object.getPrimaryKey().getName() & "()##");
				arguments.buffer.cfscript(true);
					//arguments.buffer.writeline("StructClear(get" & arguments.name & "Collection());");
					arguments.buffer.writeLine("empty" & arguments.name & "();");
					//only do if scope is public
					if(scope eq "public")
					{
						arguments.buffer.writeSetIsDirty(true);
						arguments.buffer.writeSetIsLoaded(arguments.name, true);
					}
				arguments.buffer.cfscript(false);
				arguments.buffer.writeNamedLockClose();
				arguments.buffer.writeCFFunctionClose();
			break;
		}
	</cfscript>
</cffunction>

<cffunction name="writeSort" hint="writes the sorting functions for a composite object collection" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfargument name="name" hint="The name of the collection" type="string" required="Yes">
	<cfargument name="linkTo" hint="The type of object the collection is made of" type="transfer.com.object.Link" required="Yes">
	<cfargument name="collection" hint="The collection that is being written" type="transfer.com.object.Collection" required="Yes">
	<cfargument name="scope" hint="public, or private" type="string" required="No" default="public">
	<cfscript>
		var sortProperty = 0;
		var order = "asc";
		var linkObject = getObjectManager().getObject(arguments.linkTo.getTo());

		if(arguments.collection.hasOrder())
		{
			sortProperty = linkObject.getPropertyByName(arguments.collection.getOrder().getProperty());
			order = arguments.collection.getOrder().getOrder();
		}
		else
		{
			sortProperty = linkObject.getPrimaryKey();
		}

		//sort function
		arguments.buffer.writeCFFunctionOpen("sort" & arguments.name, arguments.scope, "void", "Sort all elements in the array #name#");

		arguments.buffer.writeNamedLockOpen("transfer." & arguments.object.getClassName() & "." & arguments.name & ".##get" & arguments.object.getPrimaryKey().getName() & "()##");
		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine("if(NOT " & collection.getType() &"isEmpty(get"&arguments.name&"Collection()))");
		arguments.buffer.writeLine("{");
			arguments.buffer.writeline("set"&arguments.name&"Collection(getUtility().quickSort(get"& arguments.name &"Collection(), "& arguments.name &"Comparator));");
		arguments.buffer.writeLine("}");
		arguments.buffer.cfscript(false);
		arguments.buffer.writeNamedLockClose();

		arguments.buffer.writeCFFunctionClose();

		arguments.buffer.writeCFFunctionOpen(arguments.name & "Comparator", "private", "numeric", "The Comparator HOF for sorting");
		arguments.buffer.writeCFArgument("object1", "transfer.com.TransferObject", "object one", true);
		arguments.buffer.writeCFArgument("object2", "transfer.com.TransferObject", "object two", true);

		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine("if(arguments.object1.get"& sortProperty.getName() &"() lt arguments.object2.get"& sortProperty.getName() &"())");
		arguments.buffer.writeLine("{");
		if(order eq "asc")
		{
			arguments.buffer.writeLine("return -1;");
		}
		else
		{
			arguments.buffer.writeLine("return 1;");
		}

		arguments.buffer.writeLine("}");
		arguments.buffer.writeLine("else if(arguments.object1.get"& sortProperty.getName() &"() gt arguments.object2.get"& sortProperty.getName() &"())");
		arguments.buffer.writeLine("{");
		if(order eq "asc")
		{
			arguments.buffer.writeLine("return 1;");
		}
		else
		{
			arguments.buffer.writeLine("return -1;");
		}
		arguments.buffer.writeLine("}");
		arguments.buffer.writeLine("return 0;");
		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

</cfcomponent>