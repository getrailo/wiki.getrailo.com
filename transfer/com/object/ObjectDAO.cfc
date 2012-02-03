<!--- Document Information -----------------------------------------------------

Title:      ObjectDAO.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    DAO for object defintions

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		11/07/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="ObjectDAO" hint="DAO for object definitions">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="ObjectDAO" output="false">
	<cfargument name="configReader" hint="The XML Reader for the config file" type="transfer.com.io.XMLFileReader" required="Yes">
	<cfscript>
		setConfigReader(arguments.configReader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getObject" hint="Gets the object BO of a given defintion" access="public" returntype="Object" output="false">
	<cfargument name="Object" hint="The Object BO to populate" type="Object" required="Yes">
	<cfargument name="class" hint="The name of the package and class" type="string" required="Yes">
	<cfscript>
		var memento = structNew();
		var xpath = "/transfer/objectDefinitions/";
		var xPathBuilder = 0;
		var len = 0;
		var counter = 1;
		var xObject = 0;

		//search for properties
		xPathBuilder = ListToArray(arguments.class, ".");

		//let's build the xpath
		len = arrayLen(xPathBuilder);
		for(; counter lte len; counter = counter + 1)
		{
			if(counter eq len)
			{
				xpath = xpath & "object[@name='"& xPathBuilder[counter] &"']";
			}
			else
			{
				xpath = xpath & "package[@name='"& xPathBuilder[counter] &"']/";
			}
		}

		//properties
		xObject = getConfigReader().search(xpath);
		if(NOT ArrayLen(xObject))
		{
			throw("TransferObjectNotFoundException", "The requested object could not be found in the config file",
							"Could not find '"& arguments.class &"' in '" & getConfigReader().getPathList() & "'.");
		}

		xObject = xObject[1]; //convenience

		//create the memento
		memento.className = arguments.class;

		//objectname
		memento.objectName = xObject.xmlAttributes.name;

		//memento for the table name
		if(StructKeyExists(xObject.xmlAttributes, "table"))
		{
			memento.table = xObject.xmlAttributes.table;
		}
		setMementoDefault(memento, "table", memento.objectName);

		//memento for the sequence name
		if(StructKeyExists(xObject.xmlAttributes, "sequence"))
		{
			memento.sequence = xObject.xmlAttributes.sequence;
		}
		setMementoDefault(memento, "sequence", memento.table & "_seq");

		//memento for the decorator
		if(StructKeyExists(xObject.xmlAttributes, "decorator"))
		{
			memento.decorator = xObject.xmlAttributes.decorator;
		}
		setMementoDefault(memento, "decorator", "");

		//table alias
		if(StructKeyExists(xObject.xmlAttributes, "tablealias"))
		{
			memento.tablealias = xObject.xmlAttributes.tablealias;
		}

		//hash value for the object
		memento.hash = getObjectHash(arguments.class, toString(xObject));

		//properties
		memento.properties = ArrayNew(1);

		//memento for the ID
		memento.id = StructNew();

		if(StructKeyExists(xObject, "id"))
		{
			buildPrimaryKeyMemento(memento.objectName, memento.id, xObject.id);
		}
		else
		{
			buildCompositeKeyMemento(memento.objectName, memento.id, xObject.compositeid);
		}

		buildPropertyArrayMemento(memento.objectName, memento, xObject);

		buildManyToOneArrayMemento(memento, xObject);

		buildManyToManyArrayMemento(memento, xObject, arguments.class);

		buildOneToManyArrayMemento(memento, xObject);

		buildFunctionArrayMemento(memento, xObject);

		//special case
		buildParentOneToManyArrayMemento(memento, memento.className);

		//populate
		arguments.object.setMemento(memento);

		return object;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getObjectHash" hint="returns the unique hash for an object" access="public" returntype="string" output="false">
	<cfargument name="className" hint="the name of the class" type="string" required="Yes">
	<cfargument name="configXML" hint="the xml config string" type="string" required="Yes">
	<cfscript>
		var qExternal = getClassNameByOneToManyLinkTo(arguments.className);
		var buffer = createObject("java", "java.lang.StringBuffer").init(arguments.configXMl);
	</cfscript>
	<cfloop query="qExternal">
		<cfset buffer.append(className) />
	</cfloop>
	<cfreturn hash(buffer.toString()) />
</cffunction>

<cffunction name="buildManyToOneArrayMemento" hint="Build a memento for ManyToOne links" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="The memento to append the table to" type="struct" required="Yes">
	<cfargument name="xObject" hint="The object xmlElem" type="xml" required="Yes">
	<cfscript>
		var len = 0;
		var counter = 1;
		var manytoone = 0;
		var xManyToOne = 0;

		arguments.memento.manytoone = ArrayNew(1);

		if(NOT StructKeyExists(arguments.xObject, "manytoone"))
		{
			return;
		}

		len = ArrayLen(arguments.xObject.manytoone);

		for(;counter lte len; counter = counter + 1)
		{
			xManyToone = arguments.xObject.manytoone[counter];

			manytoone = StructNew();
			//StructAppend(manytoone, xManyToOne.xmlAttributes);
			buildCompositionMemento(manytoone, xManyToOne);

			//link
			manytoone.link = StructNew();
			StructAppend(manytoone.link, xManyToOne.link.xmlAttributes);

			ArrayAppend(arguments.memento.manytoone, manytoone);
		}
	</cfscript>
</cffunction>

<cffunction name="buildManyToManyArrayMemento" hint="Build a memento for ManyToMany links" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="The memento to append the table to" type="struct" required="Yes">
	<cfargument name="xObject" hint="The object xmlElem" type="xml" required="Yes">
	<cfargument name="class" hint="The name of the package and class" type="string" required="Yes">
	<cfscript>
		var len = 0;
		var counter = 1;
		var manytomany = 0;
		var xManyToMany = 0;

		arguments.memento.manytomany = ArrayNew(1);

		if(NOT StructKeyExists(arguments.xObject, "manytomany"))
		{
			return;
		}

		len = ArrayLen(arguments.xObject.manytomany);

		for(;counter lte len; counter = counter + 1)
		{
			xManyToMany = arguments.xObject.manytomany[counter];

			manytomany = StructNew();
			//StructAppend(manytomany, xManyToMany.xmlAttributes);
			buildCompositionMemento(manytomany, xManyToMany);

			//link from
			manytomany.linkfrom = StructNew();

			//link to
			manytomany.linkto = StructNew();

			if(xManyToMany.link[1].xmlAttributes.to eq arguments.class)
			{
				StructAppend(manytomany.linkfrom, xManyToMany.link[1].xmlAttributes);
				StructAppend(manytomany.linkto, xManyToMany.link[2].xmlAttributes);
			}
			else if(xManyToMany.link[2].xmlAttributes.to eq arguments.class)
			{
				StructAppend(manytomany.linkfrom, xManyToMany.link[2].xmlAttributes);
				StructAppend(manytomany.linkto, xManyToMany.link[1].xmlAttributes);
			}
			else
			{
				throw("transfer.InvalidManyToManyConfiguration",
					"Neither links in the manytomany declaration point to the source object",
					"link[1] refers to class '#xManyToMany.link[1].xmlAttributes.to#', and link[2] refers to #xManyToMany.link[2].xmlAttributes.to#,
						one of which should refer to '#arguments.class#'"
					);
			}

			buildCollectionMemento(manytomany, xManyToMany);

			ArrayAppend(arguments.memento.manytomany, manytomany);
		}
	</cfscript>
</cffunction>

<cffunction name="buildOneToManyArrayMemento" hint="Build a memento for OneToMany links" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="The memento to append the table to" type="struct" required="Yes">
	<cfargument name="xObject" hint="The object xmlElem" type="xml" required="Yes">
	<cfscript>
		var len = 0;
		var counter = 1;
		var onetomany = 0;
		var xOneToMany = 0;

		arguments.memento.onetomany = ArrayNew(1);

		if(NOT StructKeyExists(arguments.xObject, "onetomany"))
		{
			return;
		}

		len = ArrayLen(arguments.xObject.onetomany);

		for(;counter lte len; counter = counter + 1)
		{
			xOneToMany = arguments.xObject.onetomany[counter];

			onetomany = StructNew();
			//StructAppend(onetomany, xOneToMany.xmlAttributes);
			buildCompositionMemento(onetomany, xOneToMany);

			//link
			onetomany.link = StructNew();
			StructAppend(onetomany.link, xOneToMany.link.xmlAttributes);

			buildCollectionMemento(onetomany, xOneToMany);

			ArrayAppend(arguments.memento.onetomany, onetomany);
		}
	</cfscript>
</cffunction>


<cffunction name="buildCompositionMemento" hint="Builds a memento for a basic composition" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="The memento to append the table to" type="struct" required="Yes">
	<cfargument name="xComposition" hint="The composition xmlElem" type="xml" required="Yes">
	<cfscript>
		StructAppend(arguments.memento, arguments.xComposition.xmlAttributes);

		setMementoDefault(arguments.memento, "lazy", false);
		setMementoDefault(arguments.memento, "proxied", false);
		setMementoDefault(arguments.memento, "nullable", true);
	</cfscript>
</cffunction>

<cffunction name="buildCollectionMemento" hint="Builds a collection memento" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="The memento to append the table to" type="struct" required="Yes">
	<cfargument name="xMany" hint="The object xmlElem" type="xml" required="Yes">
	<cfscript>
		var collection = StructNew();

		StructAppend(collection, arguments.xMany.collection.xmlAttributes);

		//if struct, gimme a key
		if(collection.type eq "struct")
		{
			collection.key = StructNew();
			StructAppend(collection.key, arguments.xMany.collection.key.xmlAttributes);
		}

		//check for a order, and then set it
		if(StructKeyExists(arguments.xMany.collection, "order"))
		{
			collection.order = StructNew();
			StructAppend(collection.order, arguments.xMany.collection.order.xmlattributes);
			//set default to 'asc'
			setMementoDefault(collection.order, "order", "asc");
		}

		if(StructKeyExists(arguments.xMany.collection, "condition"))
		{
			collection.condition = StructNew();
			StructAppend(collection.condition, arguments.xMany.collection.condition.xmlAttributes);

			setMementoDefault(collection.condition, "property", "");
			setMementoDefault(collection.condition, "value", "");
			setMementoDefault(collection.condition, "where", "");
		}

		arguments.memento.collection = collection;
	</cfscript>
</cffunction>

<cffunction name="buildPropertyArrayMemento" hint="Builds the property part of the memento" access="private" returntype="void" output="false">
	<cfargument name="objectname" hint="The name of the object" type="string" required="Yes">
	<cfargument name="memento" hint="The memento to append the table to" type="struct" required="Yes">
	<cfargument name="xObject" hint="The object xmlElem" type="xml" required="Yes">
	<cfscript>
		var len = 0;
		var counter = 1;
		var property = 0;

		if(NOT StructKeyExists(arguments.xObject, "property"))
		{
			return;
		}

		len = ArrayLen(arguments.xObject.property);
		for(; counter lte len; counter = counter + 1)
		{
			property = StructNew();
			buildPropertyMemento(arguments.objectname, property, xObject.property[counter]);
			arguments.memento.properties[counter] = property;
		}
	</cfscript>
</cffunction>

<cffunction name="buildPrimaryKeyMemento" hint="Builds a primary key memento" access="private" returntype="void" output="false">
	<cfargument name="objectname" hint="The name of the object" type="string" required="Yes">
	<cfargument name="memento" hint="The memento to append the property to" type="struct" required="Yes">
	<cfargument name="xProperty" hint="The property xmlElem" type="xml" required="Yes">

	<cfscript>
		buildPropertyMemento(arguments.objectName, arguments.memento, arguments.xProperty);

		setMementoDefault(arguments.memento, "generate", false);
	</cfscript>
</cffunction>

<cffunction name="buildCompositeKeyMemento" hint="Builds a composite key memento" access="private" returntype="void" output="false">
	<cfargument name="objectname" hint="The name of the object" type="string" required="Yes">
	<cfargument name="memento" hint="The memento to append the property to" type="struct" required="Yes">
	<cfargument name="xProperty" hint="The composite xmlElem" type="xml" required="Yes">

	<cfscript>
		var len = ArrayLen(arguments.xProperty.xmlChildren);
		var item = 0;
		var counter = 1;

		arguments.memento.name = "compositeid";
		arguments.memento.column = "transfer_compositeid";
		arguments.memento.type = "string";

		buildPropertyMemento(arguments.objectName, arguments.memento, arguments.xProperty);

		arguments.memento.compositekey = structNew();

		arguments.memento.compositekey.property = ArrayNew(1);
		arguments.memento.compositekey.manytoone = ArrayNew(1);
		arguments.memento.compositekey.parentonetomany = ArrayNew(1);

		for(; counter lte len; counter = counter + 1)
		{
			item = arguments.xProperty.xmlChildren[counter];

			ArrayAppend(arguments.memento.compositekey[item.xmlName], item.xmlAttributes);
		}
	</cfscript>
</cffunction>

<cffunction name="buildPropertyMemento" hint="Builds a memento for a singular property" access="private" returntype="void" output="false">
	<cfargument name="objectname" hint="The name of the object" type="string" required="Yes">
	<cfargument name="memento" hint="The memento to append the property to" type="struct" required="Yes">
	<cfargument name="xProperty" hint="The property xmlElem" type="xml" required="Yes">
	<cfscript>
		StructAppend(arguments.memento, arguments.xProperty.xmlAttributes);

		//checking defaults

		//check set
		setMementoDefault(arguments.memento, "set", true);

		//check primary key
		setMementoDefault(arguments.memento, "primarykey", false);

		//check column value
		setMementoDefault(arguments.memento, "column", arguments.memento.name);

		//nullable
		setMementoDefault(arguments.memento, "nullable", false);

		//ignores
		setMementoDefault(arguments.memento, "ignore-update", false);
		setMementoDefault(arguments.memento, "ignore-insert", false);

		//refreshes
		setMementoDefault(arguments.memento, "refresh-insert", false);
		setMementoDefault(arguments.memento, "refresh-update", false);
	</cfscript>
</cffunction>

<cffunction name="buildFunctionArrayMemento" hint="Buils the memento for Custom Functions" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="The memento to append the table to" type="struct" required="Yes">
	<cfargument name="xObject" hint="The object xmlElem" type="xml" required="Yes">
	<cfscript>
		var len = 0;
		var counter = 1;
		var xFunction = 0;
		var xArgument = 0;
		var mementoPart = 0;
		var mementoArg = 0;
		var argCounter = 1;
		var argLen = 0;

		arguments.memento.function = ArrayNew(1);

		if(structKeyExists(arguments.xObject, "function"))
		{
			len = ArrayLen(arguments.xObject.function);
			for(; counter lte len; counter = counter + 1)
			{
				xFunction = arguments.xObject.function[counter];
				mementoPart = Structnew();

				StructAppend(mementoPart, xFunction.xmlAttributes);
				setMementoDefault(mementoPart, "access", "public");

				//do arguments
				mementoPart.argument = ArrayNew(1);
				if(StructKeyExists(xFunction, "argument"))
				{
					argLen = ArrayLen(xFunction.argument);
					for(argCounter = 1; argCounter lte argLen; argCounter = argCounter + 1)
					{
						xArgument = xFunction.argument[argCounter];
						mementoArg = StructNew();
						StructAppend(mementoArg, xArgument.xmlAttributes);
						setMementoDefault(mementoArg, "required", "false");
						setMementoDefault(mementoArg, "default", "");

						ArrayAppend(mementoPart.argument, mementoArg);
					}
				}

				//do body
				mementoPart.body = xFunction.body.xmlText;

				//attach
				ArrayAppend(arguments.memento.function, mementoPart);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="buildParentOneToManyArrayMemento" hint="Builds a memento for the parents of this object" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="The memento to append the property to" type="struct" required="Yes">
	<cfargument name="className" hint="The classname of the object" type="string" required="Yes">

	<cfscript>
		var qExternal = getClassNameByOneToManyLinkTo(arguments.className);
		var mementoPart = 0;

		arguments.memento.parentOneToMany = ArrayNew(1);
	</cfscript>

	<cfloop query="qExternal">
		<cfscript>
			mementoPart = StructNew();

			mementoPart.name = OneToManyName;
			mementoPart.link = StructNew();

			mementoPart.link.to = qExternal.className;
			mementoPart.link.column = linkColumn;

			//default
			setMementoDefault(mementoPart, "lazy", false);
			setMementoDefault(mementoPart, "proxied", false);
			setMementoDefault(mementoPart, "nullable", true);

			buildCollectionMemento(mementoPart, qExternal.xOneToMany);

			ArrayAppend(arguments.memento.parentOneTOMany, mementoPart);
		</cfscript>
	</cfloop>

</cffunction>

<cffunction name="getClassNameByOneToManyLinkTo" hint="Retrives the class names of all objects that have a One to Many relationship with this class. Query Columns are: OneToManyName,className,linkColumn" access="private" returntype="query" output="false">
	<cfargument name="className" hint="The classname to search on" type="string" required="Yes">
	<cfscript>
		var result = getConfigReader().search("/transfer/objectDefinitions//object[onetomany[link[@to='#arguments.className#']]]");
		var qObjects = QueryNew("OneToManyName,className,linkColumn,oneToManyIsLazy,xOneToMany");
		var object = 0;
		var element = 0;
		var column = 0;
		var onetomanyName = 0;
		var lazy = 0;
		var len = ArrayLen(result);
		var counter = 1;

		//going to need to get the parent recursively all the way up and rewrite the xpath every time
		for(; counter lte len; counter = counter + 1)
		{
			object = result[counter];

			//let's get the column and name
			element = xmlParse(ToString(object));
			column = XMLSearch(element, "/object/onetomany/link[@to='#arguments.className#']");
			onetomanyName = XMLSearch(element, "/object/onetomany[link[@to='#arguments.className#']]");

			onetomanyName = onetomanyName[1]; //convenience

			QueryAddRow(qObjects);
			QuerySetCell(qObjects, "oneToManyName", oneToManyName.xmlAttributes.name);
			QuerySetCell(qObjects, "xOneToMany", onetomanyName);

			if(StructKeyExists(object.xmlattributes, "table"))
			{
				QuerySetCell(qObjects, "className", getParentPath(object.xmlattributes.name, object.xmlattributes.table));
			}
			else
			{
				QuerySetCell(qObjects, "className", getParentPath(object.xmlattributes.name));
			}

			QuerySetCell(qObjects, "linkColumn", column[1].xmlAttributes.column);
		}

		return qObjects;
	</cfscript>
</cffunction>

<cffunction name="getParentPath" hint="Gets the parent of an item" access="private" returntype="string" output="false">
	<cfargument name="Name" hint="The name of the object" type="string" required="Yes">
	<cfargument name="table" hint="The name of the table for the object" type="string" required="no" default="">
	<cfargument name="path" hint="The path we're on" type="string" required="No" default="">
	<cfargument name="xpath" hint="The xpath that is currently set" type="string" required="No" default="" >
	<cfscript>
		var item = 0;

		//setup default
		if(NOT len(arguments.xpath))
		{
			if(len(arguments.table))
			{
				arguments.xpath = "/transfer/objectDefinitions//object[@name='"& arguments.name &"'][@table='"& arguments.table &"']";
			}
			else
			{
				arguments.xpath = "/transfer/objectDefinitions//object[@name='"& arguments.name &"'][not(@table)]";
			}
		}

		item = getConfigReader().search(arguments.xpath);

		//lets recurse
		if(item[1].xmlname neq "objectDefinitions")
		{
			arguments.xpath = arguments.xpath & "/..";
			arguments.path = ListPrepend(arguments.path, item[1].xmlAttributes.name, ".");
			arguments.path = getParentPath(arguments.name, arguments.table, arguments.path, arguments.xpath);
		}

		return arguments.path;
	</cfscript>
</cffunction>

<cffunction name="setMementoDefault" hint="Searches for a value, if it doesn't exist, sets a default" access="private" returntype="void" output="false">
	<cfargument name="memento" hint="The memento that is being built" type="struct" required="Yes">
	<cfargument name="key" hint="The key that is to be checked" type="string" required="Yes">
	<cfargument name="default" hint="The default value to be set" type="string" required="Yes">
	<cfscript>
			if(NOT StructKeyExists(arguments.memento, arguments.key))
			{
				arguments.memento[key] = arguments.default;
			}
	</cfscript>
</cffunction>

<cffunction name="getConfigReader" access="private" returntype="transfer.com.io.XMLFileReader" output="false">
	<cfreturn instance.ConfigReader />
</cffunction>

<cffunction name="setConfigReader" access="private" returntype="void" output="false">
	<cfargument name="ConfigReader" type="transfer.com.io.XMLFileReader" required="true">
	<cfset instance.ConfigReader = arguments.ConfigReader />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>