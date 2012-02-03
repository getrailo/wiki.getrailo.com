<!--- Document Information -----------------------------------------------------

Title:      CopyValuesToWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes the 'copyValuesTo()' method

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		08/09/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="CopyValuesToWriter" hint="Writes the 'copyValuesTo()' method" extends="AbstractBaseWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="CopyValuesToWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeCopyValuesTo" hint="Writes the copyValuesTo() method" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var manytoone = 0;
		var onetomany = 0;
		var manytomany = 0;
		var parentOneToMany = 0;
		var parentObject = 0;
		var iterator = 0;

		arguments.buffer.writeCFFunctionOpen("copyValuesTo", "public", "void", "Copies the values of this object to one of the same class");
		arguments.buffer.writeCFArgument("transfer", "transfer.com.TransferObject", "The object to copy values to", true);

		arguments.buffer.cfscript(true);
		arguments.buffer.writeTransferClassCheck("arguments.transfer", arguments.object.getClassName());

		arguments.buffer.writeLine("arguments.transfer.setMemento(getMemento());");

		//do many to one
		iterator = arguments.object.getManyToOneIterator();
		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			if(manytoone.getIsLazy() AND NOT (arguments.object.getPrimaryKey().getIsComposite() AND arguments.object.getPrimaryKey().containsManyToOneByName(manytoone.getName())))
			{
				arguments.buffer.writeLine("if(get"& manytoone.getName() & "isLoaded())");
				arguments.buffer.writeLine("{");
					arguments.buffer.writeLine("arguments.transfer.set" & manytoone.getName() & "Memento(get"& manytoone.getName() &"Memento());");
				arguments.buffer.writeLine("}");
			}
		}

		//do many to many
		iterator = arguments.object.getManyToManyIterator();
		while(iterator.hasNext())
		{
			manytomany = iterator.next();

			if(manytomany.getIsLazy())
			{

				arguments.buffer.writeLine("if(get"& manytomany.getName()  &"isLoaded())");
				arguments.buffer.writeLine("{");
					arguments.buffer.writeLine("arguments.transfer.set" & manytomany.getName() & "Memento(get"& manytomany.getName() &"Memento());");
				arguments.buffer.writeLine("}");
			}
		}

		//do one to many
		iterator = arguments.object.getOneToManyIterator();
		while(iterator.hasNext())
		{
			onetomany = iterator.next();

			if(onetomany.getIsLazy())
			{

				arguments.buffer.writeLine("if(get"& onetomany.getName()  &"isLoaded())");
				arguments.buffer.writeLine("{");
					arguments.buffer.writeLine("arguments.transfer.set" & onetomany.getName() & "Memento(get"& onetomany.getName() &"Memento());");
				arguments.buffer.writeLine("}");
			}
		}

		/** external one to many links **/
		iterator = arguments.object.getParentOneToManyIterator();
		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();
			parentObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());

			/*
				Special case in that, if not loaded, we don't want it as per usual, however,
				if this object isn't dirty, leave loading the object up to the database as
				cloning objects going UP a tree can be very expensive, as they have to come
				back down.
			*/
			arguments.buffer.writeLine("if(getParent"& parentObject.getObjectName()  &"isLoaded() AND getIsDirty())");
			arguments.buffer.writeLine("{");
				arguments.buffer.writeLine("arguments.transfer.setParent" & parentObject.getObjectName() & "Memento(getParent"& parentObject.getObjectName() &"Memento(), true);");
			arguments.buffer.writeLine("}");
		}

		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>