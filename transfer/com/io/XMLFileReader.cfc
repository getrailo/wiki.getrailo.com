<!--- Document Information -----------------------------------------------------

Title:      XMLFileReader.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Reads XML files and performs operations on them

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		04/11/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="XMLFileReader" hint="Reads XML files and performs operations on them">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="XMLFileReader" output="false">
	<cfargument name="path" hint="Absolute path to the file" type="string" required="Yes">
	<cfargument name="xsd" hint="the path to the xml shema file to validate against" type="string" required="Yes">
	<cfscript>
		setXSD(arguments.xsd);
		setPathList("");
		setXMLCollection(ArrayNew(1));

		addXML(arguments.path);

		return this;
	</cfscript>
</cffunction>

<cffunction name="search" hint="Searches the xml via an xpath" access="public" returntype="array" output="false">
	<cfargument name="xpath" hint="The xpath to search under" type="string" required="Yes">
	<cfscript>
		var results = ArrayNew(1);
		var len = arrayLen(getXMLCollection());
		var counter = 1;
		var collection = getXMLCollection();

		for(; counter lte len; counter = counter + 1)
		{
			results.addAll(xmlSearch(collection[counter], arguments.xpath));
		}

		return results;
	</cfscript>
</cffunction>

<cffunction name="getPathList" access="public" returntype="string" output="false">
	<cfreturn instance.PathList />
</cffunction>

<cffunction name="addXML" hint="adds some XML to the reader" access="public" returntype="void" output="false">
	<cfargument name="path" hint="the path to the XML to be read in and added" type="string" required="Yes">
	<cfargument name="overWrite" hint="whether or not overwrite the previous set of configurations" type="boolean" required="No" default="false">
	<cfscript>
		var filereader = createObject("component", "transfer.com.io.FileReader").init(arguments.path);
		var xml = xmlParse(fileReader.getContent());

		validate(xml, filereader.getPath());

		addPath(filereader.getPath());

		if(arguments.overWrite)
		{
			ArrayPrepend(getXMLCollection(), xml);
		}
		else
		{
			ArrayAppend(getXMLCollection(), xml);
		}

		executeIncludes(xml);
	</cfscript>
</cffunction>
<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="validate" hint="validates some XML, and handles the error" access="private" returntype="void" output="false">
	<cfargument name="xml" hint="the xml to validate" type="xml" required="Yes">
	<cfargument name="xmlPath" hint="the path to the xml" type="string" required="Yes">
	<cfscript>
		var validate = XMLValidate(arguments.xml, getXSD());
		var counter = 0;
		var detail = "";
		var len = 0;

		if(NOT validate.status)
		{
			len = ArrayLen(validate.errors);
			for(counter = 1; counter lte len; counter = counter + 1)
			{
				detail = detail & validate.errors[counter] & chr(10) & chr(13);
			}

			throw("transfer.InValidXMLException", "The XML Provided in '" & arguments.xmlPath & "' is not valid against its XML Schema", detail);
		}
	</cfscript>
</cffunction>

<cffunction name="executeIncludes" hint="find all the includes in this file, and include them" access="private" returntype="void" output="false">
	<cfargument name="xml" hint="the xml to validate" type="xml" required="Yes">
	<cfscript>
		var includes = xmlSearch(arguments.xml, "//include");
		var counter = 1;
		var len = ArrayLen(includes);
		var include = 0;

		for(; counter lte len; counter = counter + 1)
		{
			include = includes[counter];
			include.xmlAttributes.path = ExpandPath(include.xmlAttributes.path);
			addXML(argumentCollection=include.xmlAttributes);
		}
	</cfscript>
</cffunction>

<cffunction name="getXSD" access="private" returntype="string" output="false">
	<cfreturn instance.XSD />
</cffunction>

<cffunction name="setXSD" access="private" returntype="void" output="false">
	<cfargument name="XSD" type="string" required="true">
	<cfset instance.XSD = arguments.XSD />
</cffunction>

<cffunction name="getXMLCollection" access="private" returntype="array" output="false">
	<cfreturn instance.XMLCollection />
</cffunction>

<cffunction name="setXMLCollection" access="private" returntype="void" output="false">
	<cfargument name="XMLCollection" type="array" required="true">
	<cfset instance.XMLCollection = arguments.XMLCollection />
</cffunction>

<cffunction name="addPath" hint="add a path to the path list" access="private" returntype="void" output="false">
	<cfargument name="path" hint="the path to add" type="string" required="Yes">
	<cfscript>
		setPathList(ListAppend(getPathList(), arguments.path));
	</cfscript>
</cffunction>

<cffunction name="setPathList" access="private" returntype="void" output="false">
	<cfargument name="pathList" type="string" required="true">
	<cfset instance.pathList = arguments.pathList />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>