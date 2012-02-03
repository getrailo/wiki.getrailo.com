<!--- Document Information -----------------------------------------------------

Title:      ParentOneToMany.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Represents the parents of a One to many collection

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		01/09/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="ParentOneToMany" hint="Represents the parent of a One to many collection" extends="AbstractBaseComposition">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="ParentOneToMany" output="false">
	<cfargument name="object" hint="the parent obect" type="transfer.com.object.Object" required="Yes">
	<cfargument name="objectManager" hint="The object manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(arguments.object, arguments.objectManager);
		setLink(createObject("component", "transfer.com.object.Link").init(arguments.objectManager));
		setCollection(createObject("component", "transfer.com.object.Collection").init());

		return this;
	</cfscript>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		super.setMemento(arguments.memento);
		getLink().setMemento(arguments.memento.link);
		getCollection().setMemento(arguments.memento.collection);
	</cfscript>
</cffunction>

<cffunction name="getLink" access="public" returntype="link" output="false">
	<cfreturn instance.Link />
</cffunction>

<cffunction name="getCollection" access="public" returntype="Collection" output="false">
	<cfreturn instance.Collection />
</cffunction>

<cffunction name="_dump">
	<cfargument name="s">
	<cfargument name="abort" default="true">
	<cfset var g = "">
		<cfdump var="#arguments.s#">
		<cfif arguments.abort>
		<cfabort>
		</cfif>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setLink" access="private" returntype="void" output="false">
	<cfargument name="Link" type="link" required="true">
	<cfset instance.Link = arguments.Link />
</cffunction>

<cffunction name="setCollection" access="private" returntype="void" output="false">
	<cfargument name="Collection" type="Collection" required="true">
	<cfset instance.Collection = arguments.Collection />
</cffunction>

</cfcomponent>