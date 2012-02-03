<!--- Document Information -----------------------------------------------------

Title:      ManyToOne.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Many to One connection BO

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/08/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="ManyToOne" hint="Many to One connection BO" extends="AbstractBaseComposition">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="ManyToOne" output="false">
	<cfargument name="object" hint="the parent obect" type="transfer.com.object.Object" required="Yes">
	<cfargument name="objectManager" hint="The object manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(arguments.object, arguments.objectManager);

		setLink(createObject("component", "transfer.com.object.Link").init(arguments.objectManager));

		return this;
	</cfscript>
</cffunction>

<cffunction name="getLink" access="public" returntype="Link" output="false">
	<cfreturn instance.Link />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		super.setMemento(arguments.memento);

		getLink().setMemento(arguments.memento.link);
	</cfscript>
</cffunction>

<cffunction name="validate" hint="validates the many to one" access="public" returntype="void" output="false">
	<cfscript>

		//validate relationship state
		if(getLink().getToObject().getPrimaryKey().getIsComposite())
		{
			throw("transfer.InvalidRelationshipExeception",
				"A Many To One Relationship must link to an object with an 'id' element",
				"The Many to One Relationship '#getName()#' in class '#getObject().getClassName()#' cannot link to class #getLink().getToObject().getClassName()# as it utilises a composite key");
		}

	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setLink" access="private" returntype="void" output="false">
	<cfargument name="Link" type="Link" required="true">
	<cfset instance.Link = arguments.Link />
</cffunction>

</cfcomponent>