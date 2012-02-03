<!--- Document Information -----------------------------------------------------

Title:      EventActionWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes the defintion part that handles event actions

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		05/04/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="EventActionWriter" hint="Writes the defintion part that handles event actions" extends="AbstractBaseWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="EventActionWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeActionAfterDeleteTransferEvent" hint="Writes the method to be fired after a composite is deleted" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var onetomany = 0;
		var manytomany = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var class = 0;
		var parentObject = 0;

		var classArray = buildClassArrayManyToMany(arguments.object.getManyToManyIterator());
		var classIterator = classArray.iterator();
		var cIterator = 0;
		var ifString = "if";

		arguments.buffer.writeCFFunctionOpen("actionAfterDeleteTransferEvent", "public", "void", "Observer action method for when deletes occur");
		arguments.buffer.writeCFArgument("event", "transfer.com.events.TransferEvent", "The Transfer Event Object", true);

		//let's go round the one to many's and remove them
		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine("var className = arguments.event.getTransferObject().getClassName();");

		//**** many to many ****//

		//arguments.buffer.writeline("switch(arguments.event.getTransferObject().getClassName())");
		//arguments.buffer.writeline("{");

		while(classIterator.hasNext())
		{
			class = classIterator.next();
			//arguments.buffer.writeline("case " & q() & class & q() & ":");
			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			cIterator = arguments.object.getManyToManyIterator();

			while(cIterator.hasNext())
			{
				manytomany = cIterator.next();
				if(manyToMany.getLinkTo().getTo() eq class)
				{
					arguments.buffer.writeLine("if(get"& manyToMany.getName() &"IsLoaded())");
					arguments.buffer.writeLine("{");
						//write it so that it removes the item if it has one.
						arguments.buffer.writeLine("while(contains"& manyToMany.getName() & "(arguments.event.getTransferObject()))");
						arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("remove" & manyToMany.getName() & "(arguments.event.getTransferObject());");
						arguments.buffer.writeLine("}");
					arguments.buffer.writeLine("}");
				}
			}
			//arguments.buffer.writeline("break;");
			arguments.buffer.writeLine("}");
		}
		//arguments.buffer.writeline("}");

		//Remove the parent if it is being deleted
		//**** external one to many ****//

		classArray = buildClassArrayMany(arguments.object.getParentOneToManyIterator());
		classIterator = classArray.iterator();

		//arguments.buffer.writeline("switch(arguments.event.getTransferObject().getClassName())");
		//arguments.buffer.writeline("{");
		ifString = "if";

		while(classIterator.hasNext())
		{
			class = classIterator.next();
			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			cIterator = arguments.object.getParentOneToManyIterator();
			while(cIterator.hasNext())
			{
				parentOneToMany = cIterator.next();

				parentObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());

				if(parentOneToMany.getLink().getTo() eq class)
				{
					//write it so that it removes the item if it has one.
					arguments.buffer.writeline("if(hasParent" & parentObject.getObjectName() & "() AND arguments.event.getTransferObject().equalsTransfer(getParent" & parentObject.getObjectName() & "()))");
					arguments.buffer.writeline("{");
						arguments.buffer.writeline("removeParent" & parentObject.getObjectName() & "();");
					arguments.buffer.writeline("}");
				}
			}
			//arguments.buffer.writeline("break;");
			arguments.buffer.writeLine("}");

		}
		//arguments.buffer.writeline("}");


		//remove a child on manytoone if it is being deleted
		//**** many to one ****//
		classArray = buildClassArrayMany(arguments.object.getManyToOneIterator());
		classIterator = classArray.iterator();

		//arguments.buffer.writeline("switch(arguments.event.getTransferObject().getClassName())");
		//arguments.buffer.writeline("{");
		ifString = "if";

		while(classIterator.hasNext())
		{
			class = classIterator.next();
			//arguments.buffer.writeline("case " & q() & class & q() & ":");
			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			cIterator = arguments.object.getManyToOneIterator();
			while(cIterator.hasNext())
			{
				manytoone = cIterator.next();

				if(manytoOne.getLink().getTo() eq class)
				{
					//write it so that it removes the item if it has one.
					arguments.buffer.writeLine("if(get"& manytoone.getName() &"IsLoaded() AND has"& manytoone.getName() & "() AND get"& manytoone.getName() & "().equalsTransfer(arguments.event.getTransferObject()))");
					arguments.buffer.writeLine("{");
					arguments.buffer.writeLine("remove" & manytoone.getName() & "(arguments.event.getTransferObject());");
					arguments.buffer.writeLine("}");
				}
			}

			//arguments.buffer.writeline("break;");
			arguments.buffer.writeLine("}");

		}
		//arguments.buffer.writeline("}");


		//**** one to many ****//
		classArray = buildClassArrayMany(arguments.object.getOneToManyIterator());
		classIterator = classArray.iterator();

		//arguments.buffer.writeline("switch(arguments.event.getTransferObject().getClassName())");
		//arguments.buffer.writeline("{");
		ifString = "if";

		while(classIterator.hasNext())
		{
			class = classIterator.next();
			cIterator = arguments.object.getOneToManyIterator();

			//arguments.buffer.writeline("case " & q() & class & q() & ":");
			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			while(cIterator.hasNext())
			{
				onetomany = cIterator.next();

				if(onetomany.getLink().getTo() eq class)
				{
					//write it so that it removes the item if it has one.
					arguments.buffer.writeLine("if(get"& onetomany.getName() &"IsLoaded() AND contains"& oneToMany.getName() & "(arguments.event.getTransferObject()))");
					arguments.buffer.writeLine("{");
					arguments.buffer.writeLine("remove" & oneToMany.getName() & "(arguments.event.getTransferObject());");
					arguments.buffer.writeLine("}");
				}
			}

			//arguments.buffer.writeline("break;");
			arguments.buffer.writeLine("}");
		}
		//arguments.buffer.writeline("}");

		//no need to update, as the update has actually already happened.
		arguments.buffer.cfscript("false");
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeActionAfterCreateTransferEvent" hint="Writes the method to be fired after a composite is created" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		//var iterator = arguments.object.getOneToManyIterator();
		var onetomany = 0;
		var class = 0;
		var classArray = buildClassArrayMany(arguments.object.getOneToManyIterator());
		var classIterator = classArray.iterator();
		var cIterator = 0;
		var ifString = "if";

		arguments.buffer.writeCFFunctionOpen("actionAfterCreateTransferEvent", "public", "void", "Observer action method for when creates occur");
		arguments.buffer.writeCFArgument("event", "transfer.com.events.TransferEvent", "The Transfer Event Object", true);

		//**** one to many ****//

		//let's go round the one to many's and see if they are added
		arguments.buffer.cfscript(true);

		arguments.buffer.writeLine("var className = arguments.event.getTransferObject().getClassName();");

		//arguments.buffer.writeline("switch(arguments.event.getTransferObject().getClassName())");
		//arguments.buffer.writeline("{");

		while(classIterator.hasNext())
		{
			class = classIterator.next();

			cIterator = arguments.object.getOneToManyIterator();

			//arguments.buffer.writeline("case " & q() & class & q() & ":");
			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			while(cIterator.hasNext())
			{
				onetomany = cIterator.next();

				if(onetomany.getLink().getTo() eq class)
				{
					//if it has a parent at all -
					arguments.buffer.writeLine("if(arguments.event.getTransferObject().hasParent" & arguments.object.getObjectName() &"())");
					arguments.buffer.writeLine("{");

						//if it is the right class, and is NOT contained, and has 'this' as a parent, add it
						arguments.buffer.writeLine("if(arguments.event.getTransferObject().getParent" & arguments.object.getObjectName() &"().equalsTransfer(getThisObject()))");
						arguments.buffer.writeLine("{");
							arguments.buffer.writeLine("if(NOT contains"& oneToMany.getName() & "(arguments.event.getTransferObject()))");
							arguments.buffer.writeLine("{");
								arguments.buffer.writeLine("arguments.event.getTransferObject().setParent" & arguments.object.getObjectName() & "(getThisObject());" );
							arguments.buffer.writeLine("}");

							if(oneToMany.getCollection().getType() eq "array")
							{
								arguments.buffer.writeLine("sort" & oneToMany.getName() & "();");
							}

						arguments.buffer.writeLine("}");

					arguments.buffer.writeLine("}");
				}
			}

			//arguments.buffer.writeline("break;");
			arguments.buffer.writeLine("}");
		}
		//arguments.buffer.writeline("}");

		arguments.buffer.cfscript("false");
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeActionAfterUpdateTransferEvent" hint="Writes the method to be fired after a composite is updated" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var onetomany = 0;
		var class = 0;
		var classArray = buildClassArrayMany(arguments.object.getOneToManyIterator());
		var classIterator = classArray.iterator();
		var cIterator = 0;
		var ifString = "if";

		arguments.buffer.writeCFFunctionOpen("actionAfterUpdateTransferEvent", "public", "void", "Observer method action for when updates occur");
		arguments.buffer.writeCFArgument("event", "transfer.com.events.TransferEvent", "The Transfer Event Object", true);

		//**** one to many ****//

		//let's go round the one to many's and see if they are added
		arguments.buffer.cfscript(true);

		arguments.buffer.writeLine("var className = arguments.event.getTransferObject().getClassName();");

		//arguments.buffer.writeline("switch(arguments.event.getTransferObject().getClassName())");
		//arguments.buffer.writeline("{");

		while(classIterator.hasNext())
		{
			class = classIterator.next();

			cIterator = arguments.object.getOneToManyIterator();

			//arguments.buffer.writeline("case " & q() & class & q() & ":");
			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			while(cIterator.hasNext())
			{
				onetomany = cIterator.next();

				if(onetomany.getLink().getTo() eq class)
				{
					//if it has a parent at all -
					arguments.buffer.writeLine("if(arguments.event.getTransferObject().hasParent" & arguments.object.getObjectName() &"())");
					arguments.buffer.writeLine("{");

						//if it is the right class, and is NOT contained, and has 'this' as a parent, add it
						arguments.buffer.writeLine("if(arguments.event.getTransferObject().getParent" & arguments.object.getObjectName() &"().equalsTransfer(getThisObject()))");
						arguments.buffer.writeLine("{");
							arguments.buffer.writeLine("if(NOT contains"& oneToMany.getName() & "(arguments.event.getTransferObject()))");
							arguments.buffer.writeLine("{");
								//arguments.buffer.writeLine("add" & oneToMany.getName() & "(arguments.event.getTransferObject());");
								arguments.buffer.writeLine("arguments.event.getTransferObject().setParent" & arguments.object.getObjectName() & "(getThisObject());" );
							arguments.buffer.writeLine("}");

							if(oneToMany.getCollection().getType() eq "array")
							{
								arguments.buffer.writeLine("sort" & oneToMany.getName() & "();");
							}

						arguments.buffer.writeLine("}");

					arguments.buffer.writeLine("}");
				}
			}

			//arguments.buffer.writeline("break;");
			arguments.buffer.writeLine("}");
		}
		//arguments.buffer.writeline("}");

		//now we want to catch ordering changes in many to many's
		writeManyToManySoftSort(arguments.buffer, arguments.object);

		arguments.buffer.cfscript("false");
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeActionAfterDiscardTransferEvent" hint="Writes the method to be fired after a composite is discarded" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		//var iterator = arguments.object.getOneToManyIterator();
		var onetomany = 0;
		var manytomany = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var class = 0;
		var classArray = buildClassArrayMany(arguments.object.getOneToManyIterator());
		var classIterator = classArray.iterator();
		var cIterator = 0;
		var ifString = "if";
		var parentObject = 0;
		var primarykey = arguments.object.getPrimaryKey();

		arguments.buffer.writeCFFunctionOpen("actionAfterDiscardTransferEvent", "public", "void", "Observer action method for when discards occur");
		arguments.buffer.writeCFArgument("event", "transfer.com.events.TransferEvent", "The Transfer Event Object", true);

		arguments.buffer.cfscript(true);
		arguments.buffer.writeline("var discard = false;");
		arguments.buffer.writeLine("var className = arguments.event.getTransferObject().getClassName();");

		//**** one to many ****//

		while(classIterator.hasNext())
		{
			class = classIterator.next();

			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			cIterator = arguments.object.getOneToManyIterator();

			while(cIterator.hasNext())
			{
				onetomany = cIterator.next();

				if(onetomany.getLink().getTo() eq class)
				{
					//if it's the right class, and is contained, and has the same parent, discard it
					arguments.buffer.append("if(arguments.event.getTransferObject().getOriginalTransferObject().getParent" & arguments.object.getObjectName() & "isLoaded() ");
					arguments.buffer.append("AND arguments.event.getTransferObject().hasParent" & arguments.object.getObjectName() & "()");
					arguments.buffer.writeLine("AND arguments.event.getTransferObject().getParent" & arguments.object.getObjectName() &"().equalsTransfer(getThisObject()))");
					arguments.buffer.writeLine("{");

						arguments.buffer.append("if(get" & onetomany.getName() &"isLoaded() AND ");
						arguments.buffer.writeLine("contains"& oneToMany.getName() & "(arguments.event.getTransferObject()))");
						arguments.buffer.writeLine("{");

							arguments.buffer.writeLazyUnLoad(onetomany.getName());

						arguments.buffer.writeLine("}");

					arguments.buffer.writeLine("}");
				}
			}

			arguments.buffer.writeLine("}");
		}

		//**** many to many ****//

		ifString = "if";

		classArray = buildClassArrayManyToMany(arguments.object.getManyToManyIterator());
		classIterator = classArray.iterator();

		while(classIterator.hasNext())
		{
			class = classIterator.next();

			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			cIterator = arguments.object.getManyToManyIterator();

			while(cIterator.hasNext())
			{
				manytomany = cIterator.next();

				if(manytomany.getLinkTo().getTo() eq class)
				{
					//write it so that it removes the item if it has one.
					arguments.buffer.writeLine("if(get"& manyToMany.getName() &"IsLoaded() AND contains"& manyToMany.getName() & "(arguments.event.getTransferObject()))");
					arguments.buffer.writeLine("{");
						//arguments.buffer.writeLine("discard = true;");
						arguments.buffer.writeLazyUnload(manytomany.getName());
					arguments.buffer.writeLine("}");
				}
			}

			//arguments.buffer.writeline("break;");
			arguments.buffer.writeLine("}");
		}


		//**** many to one ****//

		ifString = "if";

		classArray = buildClassArrayMany(arguments.object.getManyToOneIterator());
		classIterator = classArray.iterator();

		while(classIterator.hasNext())
		{
			class = classIterator.next();

			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			cIterator = arguments.object.getManyToOneIterator();

			while(cIterator.hasNext())
			{
				manytoone = cIterator.next();

				if(manytoone.getLink().getTo() eq class)
				{
					//write it so that it removes the item if it has one.
					arguments.buffer.writeLine("if(get"& manytoone.getName() &"IsLoaded() AND has" & manytoone.getName() & "() AND get"& manytoone.getName() & "().equalsTransfer(arguments.event.getTransferObject()))");
					arguments.buffer.writeLine("{");

					if(primaryKey.getIsComposite() AND primaryKey.containsManyToOneByName(manytoone.getName()))
					{
						arguments.buffer.writeLine("discard = true;");
					}
					else
					{
						arguments.buffer.writeLazyUnload(manytoone.getName());
					}

					arguments.buffer.writeLine("}");
				}
			}

			arguments.buffer.writeLine("}");
		}

		//**** external one to many ****//

		classArray = buildClassArrayMany(arguments.object.getParentOneToManyIterator());
		classIterator = classArray.iterator();

		ifString = "if";

		while(classIterator.hasNext())
		{
			class = classIterator.next();

			arguments.buffer.writeLine(ifString & "(className eq " & q() & class & q() & ")");
			ifString = "else if";
			arguments.buffer.writeLine("{");

			cIterator = arguments.object.getParentOneToManyIterator();
			while(cIterator.hasNext())
			{
				parentOneToMany = cIterator.next();

				parentObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());

				if(parentOneToMany.getLink().getTo() eq class)
				{
					//write it so that it removes the item if it has one.
					arguments.buffer.writeline("if(getParent" & parentObject.getObjectName() & "isLoaded() AND hasParent" & parentObject.getObjectName() & "() AND arguments.event.getTransferObject().equalsTransfer(getParent" & parentObject.getObjectName() & "()))");
					arguments.buffer.writeline("{");

						if(primaryKey.getIsComposite() AND primaryKey.containsParentOneToManyByName(parentOneToMany.getName()))
						{
							arguments.buffer.writeLine("discard = true;");
						}
						else
						{
							arguments.buffer.writeLazyUnLoad("Parent" & parentObject.getObjectName());
						}

					arguments.buffer.writeline("}");
				}
			}

			arguments.buffer.writeLine("}");

		}


		/*
		if the child exists under us, and we hold a reference,
		you'll have to discard yourself too
		*/

		arguments.buffer.writeline("if(discard)");
		arguments.buffer.writeline("{");
		arguments.buffer.writeline("getTransfer().discard(getThisObject());");
		arguments.buffer.writeline("}");

		arguments.buffer.cfscript("false");
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="writeManyToManySoftSort" hint="Writes the part that handles whether or not to fire a software sorting" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="The object in which to get the manytomany collection from" type="transfer.com.object.Object" required="Yes">

	<cfscript>
		var many = 0;
		var class = 0;
		var classArray = buildClassArrayManyToMany(arguments.object.getManyToManyIterator());
		var classIterator = classArray.iterator();
		var cIterator = 0;


		//if it has nothing, write nothing
		if(NOT classIterator.hasNext())
		{
			return;
		}

		arguments.buffer.writeline("switch(arguments.event.getTransferObject().getClassName())");
		arguments.buffer.writeline("{");

		//**** many to many ****//

		//fire soft sorting
		while(classIterator.hasNext())
		{
			class = classIterator.next();
			arguments.buffer.writeline("case " & q() & class &q() & ":");

			cIterator = arguments.object.getManyToManyIterator();

			many = cIterator.next();

			if(many.getLinkTo().getTo() eq class AND many.getCollection().getType() eq "array")
			{
				arguments.buffer.writeLine("if(get"& many.getName() &"IsLoaded() AND contains"& many.getName() & "(arguments.event.getTransferObject()))");
				arguments.buffer.writeLine("{");
				arguments.buffer.writeLine("sort" & many.getName() & "();");
				arguments.buffer.writeLine("}");
			}

			arguments.buffer.writeline("break;");
		}
		arguments.buffer.writeline("}");
	</cfscript>
</cffunction>

<cffunction name="buildClassArrayManyToMany" hint="Builds a class array from a ManyToMany collection (no duplicates)" access="public" returntype="array" output="false">
	<cfargument name="iterator" hint="The many to many iterator" type="any" required="Yes">
	<cfscript>
		var classArray = ArrayNew(1);
		var previousClass = "";
		var manytomany = 0;
		var class = 0;

		while(arguments.iterator.hasNext())
		{
			manytomany = arguments.iterator.next();
			class = manytomany.getLinkTo().getTo();
			if(class NEQ previousClass)
			{
				ArrayAppend(classArray, class);
			}
			previousClass = class;
		}

		return classArray;
	</cfscript>
</cffunction>

<cffunction name="buildClassArrayMany" hint="Builds a class array from a ManyToOne, OR OneToMany collection (no duplicates)" access="public" returntype="array" output="false">
	<cfargument name="iterator" hint="The many to many iterator" type="any" required="Yes">
	<cfscript>
		var classArray = ArrayNew(1);
		var previousClass = "";
		var many = 0;
		var class = 0;

		while(arguments.iterator.hasNext())
		{
			many = arguments.iterator.next();
			class = many.getLink().getTo();
			if(class NEQ previousClass)
			{
				ArrayAppend(classArray, class);
			}
			previousClass = class;
		}

		return classArray;
	</cfscript>
</cffunction>

</cfcomponent>