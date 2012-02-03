<!--- Document Information -----------------------------------------------------

Title:      DefinitionBuffer.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    A Buffer specifically for writing a Transfer Object definition

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		05/04/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="DefinitionBuffer" hint="A Buffer specifically for writing a Transfer Object definition">

<cfscript>
	instance = StructNew();

	//constants
	static = StructNew();

	//characters to use
	static.char.quote = """";
	static.char.nl = createObject("java", "java.lang.System").getProperty("line.separator");

	//doing this to fix syntax highlighting, and I write it alot
	static.char.cfscriptOpen = "<cfsc" & "ript>";
	static.char.cfscriptClose = "</cfsc" & "ript>";
	static.char.cffunction = "cffun" & "ction";
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="DefinitionBuffer" output="false">
	<cfscript>
		setStringBuffer(createObject("Java", "java.lang.StringBuffer").init());

		return this;
	</cfscript>
</cffunction>

<cffunction name="writeCFFunctionOpen" hint="Writes the opening part of a CFFunction" access="public" returntype="void" output="false">
	<cfargument name="name" hint="The name of the function" type="string" required="Yes">
	<cfargument name="access" hint="The access of the funtion" type="string" required="Yes">
	<cfargument name="returnType" hint="The return Type of the function" type="string" required="Yes">
	<cfargument name="hint" hint="The hint for the function" type="string" required="no" default="">
	<cfscript>
		append("<");
		append(static.char.cffunction);
		append(" name=" & q() & arguments.name & q());
		append(" access=" & q() & arguments.access & q());
		append(" returntype=" & q() & arguments.returnType & q());
		append(" default=" & q() & arguments.returnType & q());
		append(" hint=" & q() & arguments.hint & q());
		writeLine(" output="& q() &"false"& q() &">");
	</cfscript>
</cffunction>

<cffunction name="writeCFFunctionClose" hint="Writes the closing part of a cffunction" access="public" returntype="void" output="false">
	<cfscript>
		append("</");
		append(static.char.cffunction);
		writeLine(">" & nl()); //done so as not to totally confuse syntax parsers
	</cfscript>
</cffunction>

<cffunction name="writeCFArgument" hint="Writes an argument to the buffer" access="public" returntype="void" output="false">
	<cfargument name="name" hint="The name of the argument" type="string" required="Yes">
	<cfargument name="type" hint="The type of the argument" type="string" required="No" default="any">
	<cfargument name="hint" hint="the hint to add to the argument" type="string" required="No" default="">
	<cfargument name="required" hint="Whether the argument is required" type="boolean" required="No" default="no">
	<cfargument name="default" hint="Default value for the argument" type="string" required="No">

	<cfscript>
		append("<" & "cfargument name=" & q() & arguments.name & q());
		append(" type=" & q() & arguments.type & q());
		append(" required=" & q() & arguments.required & q());
		append(" hint=" & q() & arguments.hint & q());
		/*append(" default=" & q() & arguments.default & q());*/

		//if there is a default, write it
		if(structKeyExists(arguments, "default"))
		{
			append(" default=" & q() & arguments.default & q());
		}
		writeLine(">");
	</cfscript>
</cffunction>

<cffunction name="writeCopyOpenFunction" hint="copies the open function call for a given function" access="public" returntype="void" output="false">
	<cfargument name="function" hint="The function coming through" type="any" required="Yes">
	<cfargument name="defaultHint" hint="the default hint value" type="string" required="No" default="">
	<cfscript>
		var metadata = getMetaData(arguments.function);
		var len = 0;
		var counter = 0;
		var metaArg = 0;
		var hasParams = StructKeyExists(metadata, "parameters");
		var argsList = "";

		if(NOT StructKeyExists(metadata, "returntype"))
		{
			metadata.returntype = "any";
		}

		if(NOT StructKeyExists(metadata, "hint"))
		{
			metadata.hint = arguments.defaultHint;
		}

		writeCFFunctionOpen(metadata.name, metadata.access, metadata.returntype, metadata.hint);

		if(hasParams)
		{
			len = ArrayLen(metadata.parameters);

			for(counter = 1; counter lte len; counter = counter + 1)
			{
				metaArg = metadata.parameters[counter];

				writeCFArgument(argumentCollection=metaArg);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="writeDoubleCheckLockOpen" hint="Writes a double check lock start" access="public" returntype="void" output="false">
	<cfargument name="condition" hint="The condition to check" type="string" required="Yes">
	<cfargument name="lockName" hint="The name of the lock" type="string" required="Yes">

	<cfscript>
		writeline("<cfif "& arguments.condition &">");
		writeline("<cflock name=" & q() & arguments.lockname & q() &" timeout=""60"">");
		writeline("<cfif "& arguments.condition &">");
	</cfscript>
</cffunction>

<cffunction name="writeDoubleCheckLockClose" hint="Writes a double check lock end" access="public" returntype="void" output="false">
	<cfscript>
		writeline("</cfif>");
		writeline("</cflock>");
		writeline("</cfif>");
	</cfscript>
</cffunction>

<cffunction name="writeNamedLockOpen" hint="writes a named lock" access="public" returntype="void" output="false">
	<cfargument name="lockName" hint="The name of the lock" type="string" required="Yes">
	<cfscript>
		writeline("<cflock name=" & q() & arguments.lockname & q() &" timeout=""60"">");
	</cfscript>
</cffunction>

<cffunction name="writeNamedLockClose" hint="writes a named lock" access="public" returntype="void" output="false">
	<cfscript>
		writeline("</cflock>");
	</cfscript>
</cffunction>

<cffunction name="writeCFScriptBlock" hint="Writes a block of cfscript" access="public" returntype="void" output="false">
	<cfargument name="body" hint="The body of the script block" type="string" required="Yes">
	<cfscript>
		cfscript(true);
		writeLine(arguments.body);
		cfscript(false);
	</cfscript>
</cffunction>

<cffunction name="writeSetIsLoaded" hint="Writes a set is loaded function" access="public" returntype="void" output="false">
	<cfargument name="name" hint="The name of the isLoaded" type="string" required="Yes">
	<cfargument name="loaded" hint="If it's loaded or not" type="boolean" required="Yes">

	<cfscript>
		writeLine("set" & arguments.name & "isLoaded(" & arguments.loaded & ");");
	</cfscript>
</cffunction>

<cffunction name="writeLazyLoad" hint="writes the check if it's loaded, and calls its load method" access="public" returntype="void" output="false">
	<cfargument name="name" hint="The name of the Loaded" type="string" required="Yes">
	<cfscript>
		writeLine("if(NOT get"& arguments.name &"isLoaded())");
		writeLine("{");
		writeLine("load" & arguments.name & "();");
		writeLine("}");
	</cfscript>
</cffunction>

<cffunction name="writeLazyUnLoad" hint="writes the check if it's loaded, and calls its unload method" access="public" returntype="void" output="false">
	<cfargument name="name" hint="The name of the Loaded" type="string" required="Yes">
	<cfscript>
		writeLine("if(get"& arguments.name &"isLoaded())");
		writeLine("{");
		writeLine("unload" & arguments.name & "();");
		writeLine("}");
	</cfscript>
</cffunction>

<cffunction name="writeSetIsDirty" hint="Writes the functoin call to setIsDirty()" access="public" returntype="void" output="false">
	<cfargument name="isDirty" hint="boolean if it is dirty or not" type="boolean" required="Yes">
	<cfscript>
		writeLine("setIsDirty("& arguments.isDirty &");");
	</cfscript>
</cffunction>

<cffunction name="append" hint="Appends the string" access="public" returntype="void" output="false">
	<cfargument name="string" hint="The string to append" type="string" required="Yes">
	<cfscript>
		getStringBuffer().append(arguments.string);
	</cfscript>
</cffunction>

<cffunction name="writeLine" hint="Writes a line with a carriage return at the end" access="public" returntype="void" output="false">
	<cfargument name="text" hint="The text" type="string" required="Yes">
	<cfscript>
		append(arguments.text);
		append(nl());
	</cfscript>
</cffunction>

<cffunction name="cfScript" hint="Writes a cfscript" access="public" returntype="void" output="false">
	<cfargument name="open" hint="Is it open, or close?" type="boolean" required="Yes">
	<cfscript>
		if(arguments.open)
		{
			writeLine(static.char.cfscriptOpen);
		}
		else
		{
			writeLine(static.char.cfscriptClose);
		}
	</cfscript>
</cffunction>

<cffunction name="toDefintionString" hint="Method to push out contents to the string" access="public" returntype="string" output="false">
	<cfreturn getStringBuffer().toString()>
</cffunction>

<cffunction name="writeTransferClassCheck" hint="Writes the code to check a class type" access="public" returntype="void" output="false">
	<cfargument name="transferScript" hint="The reference to the transfer object to check" type="string" required="Yes">
	<cfargument name="className" hint="The className to check against" type="string" required="Yes">
	<cfscript>
		writeLine("if("& arguments.transferScript & ".getClassName() neq " &q() & arguments.className & q()& ")");
		writeLine("{");
		writeLine("throw("& q()& "InvalidTransferClassException"& q()& ","& q()& "The supplied Transfer class was not the one specified in the configuration file "& q()& ","& q()& "The Transfer class of '##"& arguments.transferScript &".getClassName()##' does not match the expected class of '" & arguments.className &"'" & q()& ");");
		writeLine("}");
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="q" hint="returns a quote" access="private" returntype="string" output="false">
	<cfreturn static.char.quote>
</cffunction>

<cffunction name="nl" hint="return new line char" access="private" returntype="string" output="false">
	<cfreturn static.char.nl>
</cffunction>

<cffunction name="getStringBuffer" hint="return: java.lang.StringBuffer" access="private" returntype="any" output="false">
	<cfreturn instance.StringBuffer />
</cffunction>

<cffunction name="setStringBuffer" access="private" returntype="void" output="false">
	<cfargument name="StringBuffer" hint="java.lang.StringBuffer" type="any" required="true">
	<cfset instance.StringBuffer = arguments.StringBuffer />
</cffunction>

</cfcomponent>