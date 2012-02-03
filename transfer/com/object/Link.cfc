<!--- Document Information -----------------------------------------------------

Title:      Link.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    BO of a link from one property to the component

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		29/07/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="Link" hint="BO of a link from one property to the component">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Link" output="false">
	<cfargument name="objectManager" hint="The object manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		setObjectManager(arguments.objectManager);

		setColumn("");
		setTo("");

		return this;
	</cfscript>
</cffunction>

<cffunction name="getColumn" access="public" returntype="string" output="false">
	<cfreturn instance.Column />
</cffunction>

<cffunction name="getTo" access="public" hint="deprecated: use getToObject() instead to return the object that is being linked to" returntype="string" output="false">
	<cfreturn instance.To />
</cffunction>

<cffunction name="getToObject" hint="returns the Object that the link points to" access="public" returntype="transfer.com.object.Object" output="false">
	<cfscript>
		//not going to bother locking this, as it's only ever going to retrieve the same object anyway
		if(NOT structKeyExists(instance, "toObject"))
		{
			setToObject(getObjectManager().getObject(getTo()));
		}

		return instance.toObject;
	</cfscript>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		setTo(arguments.memento.to);
		setColumn(arguments.memento.column);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setToObject" access="private" returntype="void" output="false">
	<cfargument name="ToObject" type="transfer.com.object.Object" required="true">
	<cfset instance.ToObject = arguments.ToObject />
</cffunction>

<cffunction name="setTo" access="private" returntype="void" output="false">
	<cfargument name="To" type="string" required="true">
	<cfset instance.To = arguments.To />
</cffunction>

<cffunction name="setColumn" access="private" returntype="void" output="false">
	<cfargument name="Column" type="string" required="true">
	<cfset instance.Column = arguments.Column />
</cffunction>

<cffunction name="getObjectManager" access="private" returntype="transfer.com.object.ObjectManager" output="false">
	<cfreturn instance.ObjectManager />
</cffunction>

<cffunction name="setObjectManager" access="private" returntype="void" output="false">
	<cfargument name="ObjectManager" type="transfer.com.object.ObjectManager" required="true">
	<cfset instance.ObjectManager = arguments.ObjectManager />
</cffunction>

</cfcomponent>