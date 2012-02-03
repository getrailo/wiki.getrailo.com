<!--- Document Information -----------------------------------------------------

Title:      PrimaryKey.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Represents a Primary Key

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		10/01/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="PrimaryKey" hint="Represents a Primary Key" extends="AbstractBaseKey">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="PrimaryKey" output="false">
	<cfscript>
		super.init();
		setGenerate(false);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getGenerate" access="public" returntype="boolean" output="false">
	<cfreturn instance.Generate />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		arguments.memento.isComposite = false;

		super.setMemento(arguments.memento);

		setGenerate(arguments.memento.generate);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setGenerate" access="private" returntype="void" output="false">
	<cfargument name="Generate" type="boolean" required="true">
	<cfset instance.Generate = arguments.Generate />
</cffunction>

</cfcomponent>