<!--- Document Information -----------------------------------------------------

Title:      KeyRationalise.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Handles and standardises the key values of a TransferObject

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/08/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Handles and standardises the key values of a TransferObject" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="KeyRationalise" output="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="utility" hint="Util class" type="transfer.com.util.Utility" required="Yes" _autocreate="false">
	<cfscript>
		setObjectManager(arguments.objectManager);
		setUtility(arguments.utility);

		return this;
	</cfscript>
</cffunction>

<cffunction name="rationaliseKey" hint="builds the key to a string, formatting depending on the primary key type" access="public" returntype="string" output="false">
	<cfargument name="class" hint="The name of the class" type="string" required="Yes">
	<cfargument name="key" hint="The key for the id of the data" type="any" required="Yes">
	<cfscript>
		var object = getObjectManager().getObject(arguments.class);
		var primaryKey = object.getPrimaryKey();

		if(primaryKey.getIsComposite())
		{
			if(isStruct(arguments.key))
			{
				return buildCompositeKey(object, key);
			}
			else
			{
				throw("transfer.IllegalKeyTypeException", "The key for this class should be a struct", "The key for class '#arguments.class#' should be a struct");
			}
		}
		else
		{
			if(isSimpleValue(arguments.key))
			{
				return cleanKey(primaryKey, arguments.key);
			}
			else
			{
				throw("transfer.IllegalKeyTypeException", "The key for this class should be a simple value", "The key for class '#arguments.class#' should be of simple value");
			}
		}
	</cfscript>
</cffunction>

<cffunction name="buildCompositeKeyMapFromQuery" hint="builds a composite key from the query" access="public" returntype="struct" output="false">
	<cfargument name="compositeKey" hint="the composite key obejct" type="transfer.com.object.CompositeKey" required="Yes">
	<cfargument name="query" hint="the query to pull data from, assumed single row" type="query" required="Yes">
	<cfscript>
		var iterator = arguments.compositeKey.getPropertyIterator();
		var property = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var key = StructNew();
		var value = 0;

		while(iterator.hasNext())
		{
			property = iterator.next();
			value = arguments.query[property.getColumn()];

			if(Len(value))
			{
				key[property.getName()] = cleanKey(property, value);
			}
		}

		iterator = arguments.compositeKey.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();

			value = arguments.query[manytoone.getLink().getColumn()];

			if(Len(value))
			{
				key[manytoone.getName()] = cleanKey(manytoone.getLink().getToObject().getPrimaryKey(), value);
			}
		}

		iterator = arguments.compositeKey.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();

			value = arguments.query[parentOneToMany.getLink().getColumn()];

			if(Len(value))
			{
				key["parent" & parentOneToMany.getLink().getToObject().getObjectName()] = cleanKey(parentOneToMany.getLink().getToObject().getPrimaryKey(), value);
			}
		}

		return key;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="buildCompositeKey" hint="builds the composite key string from the struct" access="private" returntype="string" output="false">
	<cfargument name="object" hint="the object to build the composite key string for" type="transfer.com.object.Object" required="Yes">
	<cfargument name="key" hint="the identifier key for the object" type="struct" required="Yes">
	<cfscript>
		var buffer = createObject("java", "java.lang.StringBuffer").init();
		var compositeKey = arguments.object.getPrimaryKey();
		var iterator = compositeKey.getPropertyIterator();
		var property = 0;
		var manytoone = 0;
		var parentOneToMany = 0;
		var composite = 0;
		var pipe = "|";
		var singleKey = 0;
		var name = 0;

		while(iterator.hasNext())
		{
			property = iterator.next();
			name = property.getName();

			if(StructKeyExists(arguments.key, name))
			{
				buffer.append(cleanKey(property, arguments.key[property.getName()]));
			}

			buffer.append(pipe);
		}

		iterator = compositeKey.getManyToOneIterator();

		while(iterator.hasNext())
		{
			manytoone = iterator.next();

			singleKey = manytoone.getName();

			if(StructKeyExists(arguments.key, singleKey))
			{
				composite = getObjectManager().getObject(manytoone.getLink().getTo());
				buffer.append(cleanKey(composite.getPrimaryKey(), arguments.key[singleKey]));
			}

			buffer.append(pipe);
		}

		iterator = compositeKey.getParentOneToManyIterator();

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();
			composite = getObjectManager().getObject(parentOneToMany.getLink().getTo());

			singleKey = "parent" & composite.getObjectName();

			if(StructKeyExists(arguments.key, singleKey))
			{

				buffer.append(cleanKey(composite.getPrimaryKey(), arguments.key[singleKey]));
			}

			buffer.append(pipe);
		}

		return buffer.toString();
	</cfscript>
</cffunction>

<cffunction name="cleanKey" hint="Makes sure the key is formatted properly" access="public" returntype="string" output="false">
	<cfargument name="property" hint="the property to clean from" type="transfer.com.object.Property" required="Yes">
	<cfargument name="key" hint="The key for the id of the data" type="string" required="Yes">
	<cfscript>
		var type = arguments.property.getType();

		if(ListFindNoCase("guid,uuid", type))
		{
			arguments.key = UCase(arguments.key);
		}
		else if(type eq "numeric")
		{
			if(isNumeric(arguments.key))
			{
				//could be 'null' so, check
				arguments.key = getUtility().trimZero(arguments.key);
			}
		}

		return JavaCast("string", arguments.key);
	</cfscript>
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

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>