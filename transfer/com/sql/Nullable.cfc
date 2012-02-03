<!--- Document Information -----------------------------------------------------

Title:      DefaultNullable.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Handles DefaultNull values

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/07/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="DefaultNullable" hint="Handles DefaultNull values">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Nullable" output="false">
	<cfargument name="objectManager" hint="The object manager to query" type="transfer.com.object.ObjectManager" required="Yes">
	<cfargument name="utility" hint="The utility class" type="transfer.com.util.Utility" required="Yes">
	<cfscript>
		setObjectManager(arguments.objectManager);
		setUtility(arguments.utility);

		//setup system wide default
		setDefaultNullBoolean(false);
		setDefaultNullDate(createDate(100, 1, 1));
		setDefaultNullString("");
		setDefaultNullNumeric(0);
		setDefaultNullUUID("00000000-0000-0000-0000000000000000");
		setDefaultNullGUID("00000000-0000-0000-0000-000000000000");
		setDefaultNullBinary(getUtility().getEmptyByteArray());

		return this;
	</cfscript>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		if(StructKeyExists(arguments.memento, "string"))
		{
			setDefaultNullString(arguments.memento.string);
		}
		if(StructKeyExists(arguments.memento, "numeric"))
		{
			setDefaultNullNumeric(arguments.memento.numeric);
		}
		if(StructKeyExists(arguments.memento, "date"))
		{
			setDefaultNullDate(ParseDateTime(arguments.memento.date));
		}
		if(StructKeyExists(arguments.memento, "boolean"))
		{
			setDefaultNullBoolean(arguments.memento.boolean);
		}
		if(StructKeyExists(arguments.memento, "uuid"))
		{
			setDefaultNullUUID(arguments.memento.uuid);
		}
		if(StructKeyExists(arguments.memento, "guid"))
		{
			setDefaultNullGUID(arguments.memento.guid);
		}
		if(StructKeyExists(arguments.memento, "binary"))
		{
			setDefaultNullBinary(arguments.memento.binary);
		}
	</cfscript>
</cffunction>

<cffunction name="getNullValue" hint="returns the null value, depending on what type the property is" access="public" returntype="any" output="false">
	<cfargument name="className" hint="The className of the object to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to get the null value for" type="string" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.className);
		var property = object.getPropertyByName(arguments.propertyName);
		var type = property.getType();

		if(type eq "numeric")
		{
			return getNullNumeric(arguments.className, property.getName());
		}
		else if(type eq "uuid")
		{
			return getNullUUID(arguments.className, property.getName());
		}
		else if(type eq "guid")
		{
			return getNullGUID(arguments.className, property.getName());
		}
		else if(type eq "date")
		{
			return getNullDate(arguments.className, property.getName());
		}
		else if(type eq "boolean")
		{
			return getNullBoolean(arguments.className, property.getName());
		}
		else if(type eq "binary")
		{
			return getNullBinary(arguments.className, property.getName());
		}
		else
		{
			return getNullString(arguments.className, property.getName());
		}
	</cfscript>
</cffunction>

<cffunction name="getNullString" hint="Returns the null string value for this object and property" access="public" returntype="string" output="false">
	<cfargument name="className" hint="The className of the object to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfscript>
		if(hasNullValue(arguments.className, arguments.propertyName))
		{
			return getNullPropertyValue(arguments.className, arguments.propertyName);
		}

		return getDefaultNullString();
	</cfscript>
</cffunction>

<cffunction name="getNullNumeric" hint="Returns the null numeric value for this object and property" access="public" returntype="numeric" output="false">
	<cfargument name="className" hint="The className of the object to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfscript>
		if(hasNullValue(arguments.className, arguments.propertyName))
		{
			return getNullPropertyValue(arguments.className, arguments.propertyName);
		}

		return getDefaultNullNumeric();
	</cfscript>
</cffunction>

<cffunction name="getNullDate" hint="Returns the null date value for this object and property" access="public" returntype="date" output="false">
	<cfargument name="className" hint="The className of the object to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfscript>
		if(hasNullValue(arguments.className, arguments.propertyName))
		{
			return ParseDateTime(getNullPropertyValue(arguments.className, arguments.propertyName));
		}

		return getDefaultNullDate();
	</cfscript>
</cffunction>

<cffunction name="getNullBoolean" hint="Returns the null bool value for this object and property" access="public" returntype="boolean" output="false">
	<cfargument name="className" hint="The className of the object to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfscript>
		if(hasNullValue(arguments.className, arguments.propertyName))
		{
			return getNullPropertyValue(arguments.className, arguments.propertyName);
		}

		return getDefaultNullBoolean();
	</cfscript>
</cffunction>

<cffunction name="getNullUUID" hint="Returns the null UUID value for this object and property" access="public" returntype="uuid" output="false">
	<cfargument name="className" hint="The className of the object to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfscript>
		if(hasNullValue(arguments.className, arguments.propertyName))
		{
			return getNullPropertyValue(arguments.className, arguments.propertyName);
		}

		return getDefaultNullUUID();
	</cfscript>
</cffunction>

<cffunction name="getNullGUID" hint="Returns the null GUID value for this object and property" access="public" returntype="guid" output="false">
	<cfargument name="className" hint="The className of the object to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfscript>
		if(hasNullValue(arguments.className, arguments.propertyName))
		{
			return getNullPropertyValue(arguments.className, arguments.propertyName);
		}

		return getDefaultNullGUID();
	</cfscript>
</cffunction>

<cffunction name="getNullBinary" hint="Returns the null binary value for this object and property" access="public" returntype="binary" output="false">
	<cfargument name="className" hint="The className of the object to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfscript>
		if(hasNullValue(arguments.className, arguments.propertyName))
		{
			return getNullPropertyValue(arguments.className, arguments.propertyName).getBytes();
		}

		return getDefaultNullBinary();
	</cfscript>
</cffunction>

<cffunction name="checkNullValue" hint="Generically checks a null value for a given property" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to get the null value for" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="property" hint="The the property to check against" type="transfer.com.object.Property" required="Yes">
	<cfargument name="value" hint="The value to test" type="any" required="Yes">
	<cfscript>
		var type = arguments.property.getType();

		if(type eq "numeric")
		{
			return checkNullNumeric(arguments.transfer, arguments.property.getName(), arguments.value);
		}
		else if(type eq "uuid")
		{
			return checkNullUUID(arguments.transfer, arguments.property.getName(), arguments.value);
		}
		else if(type eq "guid")
		{
			return checkNullGUID(arguments.transfer, arguments.property.getName(), arguments.value);
		}
		else if(type eq "date")
		{
			return checkNullDate(arguments.transfer, arguments.property.getName(), arguments.value);
		}
		else if(type eq "boolean")
		{
			return checkNullBoolean(arguments.transfer, arguments.property.getName(), arguments.value);
		}
		else if(type eq "binary")
		{
			return checkNullBinary(arguments.transfer, arguments.property.getName(), arguments.value);
		}
		else
		{
			return checkNullString(arguments.transfer, arguments.property.getName(), arguments.value);
		}
	</cfscript>
</cffunction>

<cffunction name="checkNullUUID" hint="whether the UUID is a null value or not" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to get the null value for" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfargument name="uuid" hint="the uuid to test" type="uuid" required="Yes">
	<cfreturn arguments.uuid eq getNullUUID(arguments.transfer.getClassName(), arguments.propertyName)>
</cffunction>

<cffunction name="checkNullGUID" hint="whether the GUID is a null value or not" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to get the null value for" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfargument name="guid" hint="the guid to test" type="guid" required="Yes">
	<cfreturn arguments.guid eq getNullGUID(arguments.transfer.getClassName(), arguments.propertyName)>
</cffunction>

<cffunction name="checkNullDate" hint="whether the Date is a null value or not" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to get the null value for" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfargument name="date" hint="the date to test" type="date" required="Yes">
	<cfreturn arguments.date eq getNullDate(arguments.transfer.getClassName(), arguments.propertyName)>
</cffunction>

<cffunction name="checkNullNumeric" hint="whether the numeric is a null value or not" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to get the null value for" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfargument name="number" hint="the number to test" type="numeric" required="Yes">
	<cfreturn arguments.number eq getNullNumeric(arguments.transfer.getClassName(), arguments.propertyName)>
</cffunction>

<cffunction name="checkNullBoolean" hint="whether the boolean is a null value or not" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to get the null value for" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfargument name="boolean" hint="the boolean to test" type="boolean" required="Yes">
	<cfreturn arguments.boolean eq getNullBoolean(arguments.transfer.getClassName(), arguments.propertyName)>
</cffunction>

<cffunction name="checkNullString" hint="whether the string is a null value or not" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to get the null value for" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfargument name="string" hint="the string to test" type="string" required="Yes">
	<cfreturn arguments.string eq getNullString(arguments.transfer.getClassName(), arguments.propertyName)>
</cffunction>

<cffunction name="checkNullBinary" hint="whether the binary is a null value or not" access="public" returntype="boolean" output="false">
	<cfargument name="transfer" hint="The transfer object to get the null value for" type="transfer.com.TransferObject" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfargument name="binary" hint="the binary to test" type="binary" required="Yes">
	<cfreturn getUtility().nativeArrayEquals(arguments.binary, getNullBinary(arguments.transfer.getClassName(), arguments.propertyName)) />
</cffunction>


<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="hasNullValue" hint="Checks to see if a property of an object has a null value" access="private" returntype="boolean" output="false">
	<cfargument name="className" hint="The className of the object to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.className);
		var property = object.getPropertyByName(arguments.propertyName);

		return property.hasNullValue();
	</cfscript>
</cffunction>

<cffunction name="getNullPropertyValue" hint="gets the null value of a property" access="private" returntype="any" output="false">
	<cfargument name="className" hint="The class to get the null value for" type="string" required="Yes">
	<cfargument name="propertyName" hint="The name of the property to check against" type="string" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.className);
		var property = object.getPropertyByName(arguments.propertyName);

		return property.getNullValue();
	</cfscript>
</cffunction>

<cffunction name="getDefaultNullNumeric" access="private" returntype="numeric" output="false">
	<cfreturn instance.DefaultNullNumeric />
</cffunction>

<cffunction name="getDefaultNullString" access="private" returntype="string" output="false">
	<cfreturn instance.DefaultNullString />
</cffunction>

<cffunction name="getDefaultNullDate" access="private" returntype="date" output="false">
	<cfreturn instance.DefaultNullDate />
</cffunction>

<cffunction name="getDefaultNullBoolean" access="private" returntype="string" output="false">
	<cfreturn instance.DefaultNullBoolean />
</cffunction>

<cffunction name="getDefaultNullUUID" access="private" returntype="uuid" output="false">
	<cfreturn instance.DefaultNullUUID />
</cffunction>

<cffunction name="getDefaultNullGUID" access="private" returntype="guid" output="false">
	<cfreturn instance.DefaultNullGUID />
</cffunction>

<cffunction name="setDefaultNullGUID" access="private" returntype="void" output="false">
	<cfargument name="DefaultNullGUID" type="guid" required="true">
	<cfset instance.DefaultNullGUID = arguments.DefaultNullGUID />
</cffunction>

<cffunction name="setDefaultNullUUID" access="private" returntype="void" output="false">
	<cfargument name="DefaultNullUUID" type="uuid" required="true">
	<cfset instance.DefaultNullUUID = arguments.DefaultNullUUID />
</cffunction>

<cffunction name="setDefaultNullBoolean" access="private" returntype="void" output="false">
	<cfargument name="DefaultNullBoolean" type="string" required="true">
	<cfset instance.DefaultNullBoolean = arguments.DefaultNullBoolean />
</cffunction>

<cffunction name="setDefaultNullDate" access="private" returntype="void" output="false">
	<cfargument name="DefaultNullDate" type="date" required="true">
	<cfset instance.DefaultNullDate = arguments.DefaultNullDate />
</cffunction>

<cffunction name="setDefaultNullString" access="private" returntype="void" output="false">
	<cfargument name="DefaultNullString" type="string" required="true">
	<cfset instance.DefaultNullString = arguments.DefaultNullString />
</cffunction>

<cffunction name="setDefaultNullNumeric" access="private" returntype="void" output="false">
	<cfargument name="DefaultNullNumeric" type="numeric" required="true">
	<cfset instance.DefaultNullNumeric = arguments.DefaultNullNumeric />
</cffunction>

<cffunction name="setDefaultNullBinary" access="private" returntype="void" output="false">
	<cfargument name="defaultNullBinary" type="binary" required="true">
	<cfset instance.DefaultNullBinary = arguments.DefaultNullBinary />
</cffunction>

<cffunction name="getDefaultNullBinary" access="private" returntype="binary" output="false">
	<cfreturn instance.DefaultNullBinary />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

<cffunction name="getUtility" access="private" returntype="transfer.com.util.Utility" output="false">
	<cfreturn instance.Utility />
</cffunction>

<cffunction name="setUtility" access="private" returntype="void" output="false">
	<cfargument name="Utility" type="transfer.com.util.Utility" required="true">
	<cfset instance.Utility = arguments.Utility />
</cffunction>

</cfcomponent>