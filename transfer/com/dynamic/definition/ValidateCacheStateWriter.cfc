<!--- Document Information -----------------------------------------------------

Title:      ValidateCacheStateWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    writes the ValidateCacheStateWriter method

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		16/03/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="writes the validateCacheState() method" extends="AbstractBaseWriter" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="ValidateCacheStateWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeValidateCacheState" hint="Writes the validateCacheState() method" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var manytoone = 0;
		var onetomany = 0;
		var manytomany = 0;
		var parentOneToMany = 0;
		var parentObject = 0;
		var iterator = 0;

		arguments.buffer.writeCFFunctionOpen("validateCacheState", "package", "boolean", "if this object is cached, then validate that all it's composites are cached too");
		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine("var iterator = 0;");
		arguments.buffer.writeLine("var item = 0;");

		//if the object is not cached, then it is valid, as it's cache state doesn't matter
		arguments.buffer.writeLine("if(getIsPersisted() AND NOT getTransfer().validateIsCached(getThisObject()))");
		arguments.buffer.writeLine("{");

			/** external one to many links **/
			iterator = arguments.object.getParentOneToManyIterator();
			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();
				parentObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());

				/*
					if the transfer object is not persisted,
					and it has a parent, discard it to force the parent discard
				*/
				arguments.buffer.writeLine("if(getParent"& parentObject.getObjectName()  &"isLoaded() AND hasParent"& parentObject.getObjectName()  &"())");
				arguments.buffer.writeLine("{");
					//if I'm a clone, and my parent is a clone, then don't discard
					arguments.buffer.writeLine("if(getIsClone() AND getParent"& parentObject.getObjectName()  &"().getIsClone())");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("return true;");
					arguments.buffer.writeLine("}");
					arguments.buffer.writeLine("return false;");
				arguments.buffer.writeLine("}");
			}

			arguments.buffer.writeLine("return true;");

		arguments.buffer.writeLine("}");

			//do many to one
			iterator = arguments.object.getManyToOneIterator();
			while(iterator.hasNext())
			{
				manytoone = iterator.next();
				arguments.buffer.writeLine("if(get"& manytoone.getName() & "isLoaded() AND has"& manytoone.getName() & "())");
				arguments.buffer.writeLine("{");
					writeValidIsCachedCheck(arguments.buffer, "get"& manytoone.getName() &"()");
					/*
					arguments.buffer.writeLine("if(NOT getTransfer().validateIsCached(get"& manytoone.getName() &"()))");
					arguments.buffer.writeLine("{");
						arguments.buffer.writeLine("return false;");
					arguments.buffer.writeLine("}");
					*/
				arguments.buffer.writeLine("}");
			}

			//do many to many
			iterator = arguments.object.getManyToManyIterator();
			while(iterator.hasNext())
			{
				manytomany = iterator.next();

				arguments.buffer.writeLine("if(get"& manytomany.getName()  &"isLoaded())");
				arguments.buffer.writeLine("{");
					arguments.buffer.writeLine("iterator = get"& manytomany.getName()  &"iterator();");
					arguments.buffer.writeLine("while(iterator.hasNext())");
					arguments.buffer.writeLine("{");
						writeValidIsCachedCheck(arguments.buffer, "iterator.next()");
					arguments.buffer.writeLine("}");
				arguments.buffer.writeLine("}");
			}

			/** external one to many links **/
			iterator = arguments.object.getParentOneToManyIterator();
			while(iterator.hasNext())
			{
				parentOneToMany = iterator.next();
				parentObject = getObjectManager().getObject(parentOneToMany.getLink().getTo());

				arguments.buffer.writeLine("if(getParent"& parentObject.getObjectName()  &"isLoaded() AND hasParent"& parentObject.getObjectName()  &"())");
				arguments.buffer.writeLine("{");
					writeValidIsCachedCheck(arguments.buffer, "getParent" & parentObject.getObjectName() & "()");
				arguments.buffer.writeLine("}");
			}

		arguments.buffer.writeLine("return true;");

		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>
<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="writeValidIsCachedCheck" hint="writes the validIsCached check" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="text" hint="The cfml to check against" type="string" required="Yes">
	<cfscript>
		arguments.buffer.writeLine("item = " & arguments.text & ";");
		arguments.buffer.writeLine("if(item.getIsClone() OR NOT getTransfer().validateIsCached(item))");
		arguments.buffer.writeLine("{");
			arguments.buffer.writeLine("return false;");
		arguments.buffer.writeLine("}");
	</cfscript>
</cffunction>

</cfcomponent>