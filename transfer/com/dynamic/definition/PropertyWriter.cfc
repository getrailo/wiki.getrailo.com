<!--- Document Information -----------------------------------------------------

Title:      PropertyWriter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Writes out the property definitions

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		05/04/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="PropertyWriter" hint="Writes out the property definitions" extends="AbstractBaseWriter">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="PropertyWriter" output="false">
	<cfargument name="objectManager" hint="The Object Manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(objectManager);

		return this;
	</cfscript>
</cffunction>

<cffunction name="writePrimaryKey" hint="Writes the ID property getter and setters" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">

	<cfscript>
		if(object.getPrimaryKey().getIsComposite())
		{
			writeCompositeKeyGetter(arguments.buffer, arguments.object.getPrimaryKey());
		}
		else
		{
			writeGetter(arguments.buffer, arguments.object.getPrimaryKey());
			writeSetter(arguments.buffer, arguments.object.getPrimaryKey());
		}
	</cfscript>
</cffunction>

<cffunction name="writeProperties" hint="Writes out the properties to the definition" access="public" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="object" hint="BO of the Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var iterator = arguments.Object.getPropertyIterator();
		var property = 0;

		while(iterator.hasNext())
		{
			property = iterator.next();

			//write getter
			writeGetter(arguments.buffer, property);

			//write setter
			writeSetter(arguments.buffer, property);

			if(property.getIsNullable())
			{
				writeSetNull(arguments.buffer, property);
				writeGetIsNull(arguments.buffer, property);
			}
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="writeCompositeKeyGetter" hint="writes the coposite key getter" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="compositekey" hint="the composite key meta" type="transfer.com.object.CompositeKey" required="Yes">
	<cfscript>
		var iterator = arguments.compositekey.getPropertyIterator();
		var property = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var composite = 0;

		arguments.buffer.writeCFFunctionOpen("get" & arguments.compositekey.getName(), "public", "string", "Returns the unique id, based off the composite keys");
		arguments.buffer.cfscript(true);
		arguments.buffer.writeLine("var key = createObject("& q() &"java"& q() &", "& q() &"java.lang.StringBuffer"& q() &").init();");

		while(iterator.hasNext())
		{
			property = iterator.next();

			if(property.getIsNullable())
			{
				arguments.buffer.writeLine("if(NOT get" & property.getName() & "IsNull())");
				arguments.buffer.writeLine("{");
			}

			arguments.buffer.writeLine("key.append(JavaCast("& q() &"string"& q() &", get" & property.getName() & "()));");

			if(property.getIsNullable())
			{
				arguments.buffer.writeLine("}");
			}


			arguments.buffer.writeLine("key.append(" & q() &  "|" & q() & ");");
		}

		iterator = arguments.compositeKey.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			composite = getObjectManager().getObject(manytoone.getLink().getTo());

			arguments.buffer.writeLine("if(has"& manytoone.getName() &"())");
			arguments.buffer.writeLine("{");
				arguments.buffer.writeLine("key.append(JavaCast("& q() &"string"& q() &", get"& manytoone.getName() &"().get"& composite.getPrimaryKey().getName() &"()));");
			arguments.buffer.writeLine("}");

			arguments.buffer.writeLine("key.append(" & q() &  "|" & q() & ");");
		}

		iterator = arguments.compositeKey.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();
			composite = getObjectManager().getObject(parentOneToMany.getLink().getTo());

			arguments.buffer.writeLine("if(hasParent"& composite.getObjectName() &"())");
			arguments.buffer.writeLine("{");
				arguments.buffer.writeLine("key.append(JavaCast("& q() &"string"& q() &", getParent"& composite.getObjectName() &"().get"& composite.getPrimaryKey().getName() &"()));");
			arguments.buffer.writeLine("}");

			arguments.buffer.writeLine("key.append(" & q() &  "|" & q() & ");");
		}

		arguments.buffer.writeLine("return key.toString();");
		arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeGetter" hint="Writes the getter for a property" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="property" hint="The property to write the getter for" type="transfer.com.object.Property" required="Yes">
	<cfscript>
		arguments.buffer.writeCFFunctionOpen("get" & arguments.property.getName(), "public", arguments.property.getType(), "Accessor for property #property.getName()#");
		arguments.buffer.writeCFScriptBlock("return instance." & arguments.property.getName() & ";");
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>


<cffunction name="writeSetter" hint="Writes the setter for a property" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="property" hint="The property to write the getter for" type="transfer.com.object.Property" required="Yes">
	<cfscript>
		var access = 0;
		var type = arguments.property.getType();

		if(property.getSet())
		{
			access = "public";
		}
		else
		{
			access = "private";
		}

		arguments.buffer.writeCFFunctionOpen("set" & arguments.property.getName(),access ,"void", "Mutator for property #property.getName()#");
		arguments.buffer.writeCFArgument(property.getName(), type, "The value to set #property.getName()# to", true);
		arguments.buffer.cfScript(true);

		arguments.buffer.append("if(NOT StructKeyExists(instance, " & q() & arguments.property.getName() & q() & ") OR ");

		if(type eq "string")
		{
			arguments.buffer.append("Compare(get" & arguments.property.getName() & "(), arguments." & arguments.property.getName() & ") neq 0");
		}
		else if(type eq "binary")
		{
			arguments.buffer.append("NOT getUtility().nativeArrayEquals(get" & arguments.property.getName() & "(), arguments." & arguments.property.getName() & ")");
		}
		else
		{
			arguments.buffer.append("get" & arguments.property.getName() & "() neq arguments." & arguments.property.getName());
		}

		arguments.buffer.writeLine(")");

		arguments.buffer.writeline("{");
		arguments.buffer.append("instance." & arguments.property.getName() & " = ");

		//make sure numbers and UID's come out in the same format
		if(arguments.property.getType() eq "numeric")
		{
			arguments.buffer.append("getUtility().trimZero");
		}
		else if(ListFindNoCase("UUID,GUID", arguments.property.getType()))
		{
			arguments.buffer.append("UCase");
		}

		arguments.buffer.append("(arguments." & arguments.property.getName());
		arguments.buffer.writeLine(");");
		arguments.buffer.writeSetIsDirty(true);
		arguments.buffer.writeline("}");
		arguments.buffer.cfScript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeSetNull" hint="Writes the set()Null on the object" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="property" hint="The property to write the null for for" type="transfer.com.object.Property" required="Yes">
	<cfscript>
		arguments.buffer.writeCFFunctionOpen("set" & arguments.property.getName() & "Null", "public" ,"void",
											"Set #property.getName()# to its NULL value'");
			arguments.buffer.cfscript(true);
				arguments.buffer.writeLine("var nullValue = getNullable().getNull"& arguments.property.getType() & "(getClassName(), " & q() & arguments.property.getName() & q() & ");");
				arguments.buffer.writeLine("set" & arguments.property.getName() & "(nullValue);");
			arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

<cffunction name="writeGetIsNull" hint="Writes the get()IsNull on the object" access="private" returntype="void" output="false">
	<cfargument name="buffer" hint="The Buffer that the defintion file is being set in" type="transfer.com.dynamic.definition.DefinitionBuffer" required="Yes">
	<cfargument name="property" hint="The property to write the getIsnull for for" type="transfer.com.object.Property" required="Yes">
	<cfscript>
		arguments.buffer.writeCFFunctionOpen("get" & arguments.property.getName() & "IsNull", "public" ,"boolean",
											"Returns whether or not #property.getName()#'s value matches the set NULL value'");
			arguments.buffer.cfscript(true);
				arguments.buffer.writeLine("return getNullable().checkNull"& arguments.property.getType() & "(getThisObject(), " & q() & arguments.property.getName() & q() & ", get" & arguments.property.getName() & "());");
			arguments.buffer.cfscript(false);
		arguments.buffer.writeCFFunctionClose();
	</cfscript>
</cffunction>

</cfcomponent>