<!--- Document Information -----------------------------------------------------

Title:      ManyToMany.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    BO for Many To Many connection

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		29/07/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="ManyToMany" hint="BO for a Many to Many connection" extends="AbstractBaseComposition">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="ManyToMany" output="false">
	<cfargument name="object" hint="the parent obect" type="transfer.com.object.Object" required="Yes">
	<cfargument name="objectManager" hint="The object manager" type="transfer.com.object.ObjectManager" required="Yes">
	<cfscript>
		super.init(arguments.object, arguments.objectManager);

		setTable("");

		setLinkTo(createObject("component", "transfer.com.object.Link").init(arguments.objectManager));
		setLinkFrom(createObject("component", "transfer.com.object.Link").init(arguments.objectManager));
		setCollection(createObject("component", "transfer.com.object.Collection").init());
		setIsParent(false);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getTable" access="public" returntype="string" output="false">
	<cfreturn instance.Table />
</cffunction>

<cffunction name="getLinkTo" access="public" returntype="Link" output="false">
	<cfreturn instance.LinkTo />
</cffunction>

<cffunction name="getLinkFrom" access="public" returntype="Link" output="false">
	<cfreturn instance.LinkFrom />
</cffunction>

<cffunction name="getCollection" access="public" returntype="Collection" output="false">
	<cfreturn instance.Collection />
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		super.setMemento(arguments.memento);

		setTable(arguments.memento.table);

		getLinkTo().setMemento(arguments.memento.linkTo);
		getLinkFrom().setMemento(arguments.memento.linkFrom);

		getCollection().setMemento(arguments.memento.collection);

		//set the table alias, if ti exists
		if(StructKeyExists(arguments.memento, "tablealias"))
		{
			setTableAlias(arguments.memento.tableAlias);
		}

		/*
		we'll be cheeky, and store the memento temporarily, as we know we'll grab it later
		and then delete it
		*/
		instance.memento = arguments.memento;
	</cfscript>
</cffunction>

<cffunction name="getTableAlias" access="public" returntype="string" output="false">
	<cfreturn instance.tableAlias />
</cffunction>

<cffunction name="hasTableAlias" hint="if the object has a table alias" access="public" returntype="boolean" output="false">
	<cfreturn StructKeyExists(instance, "tableAlias") />
</cffunction>

<cffunction name="validate" hint="validates the many to many" access="public" returntype="void" output="false">
	<cfscript>
		//validate the composite key relationships
		if(getLinkTo().getToObject().getPrimaryKey().getIsComposite())
		{
			throw("transfer.InvalidRelationshipExeception",
				"A Many To Many Relationship must link to an object with an 'id' element",
				"The Many to Many Relationship '#getName()#' in class '#getObject().getClassName()#' cannot link to class #getLinkTo().getToObject().getClassName()# as it utilises a composite key");
		}
		else if(getLinkFrom().getToObject().getPrimaryKey().getIsComposite())
		{
			throw("transfer.InvalidRelationshipExeception",
				"A Many To Many Relationship must link to an object with an 'id' element",
				"The Many to Many Relationship '#getName()#' in class '#getObject().getClassName()#' cannot link to class #getLinkFrom().getToObject().getClassName()# as it utilises a composite key");
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!--- make this package, so we can set it to true --->
<cffunction name="setIsParent" access="package" returntype="void" output="false">
	<cfargument name="isParent" type="boolean" required="true">
	<cfset instance.isParent = arguments.isParent />
</cffunction>

<cffunction name="notifyComplete" hint="notifies the object that it has finished loading, and can do post processing" access="package" returntype="void" output="false">
	<cfscript>
		var parentManyToMany = 0;
		var object = 0;

		//add yourself to the child, as a parent
		if(NOT getIsParent())
		{
			object = getLinkTo().getToObject();

			parentManyToMany = createObject("component", "transfer.com.object.ManyToMany").init(object, getObjectManager());

			parentManyToMany.setIsParent(true);

			parentManyToMany.setMemento(instance.memento);

			object.addParentManyToMany(parentManyToMany);

			parentManyToMany.notifyComplete();
		}

		//cleanup
		StructDelete(instance,"memento");
	</cfscript>
</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setTable" access="private" returntype="void" output="false">
	<cfargument name="Table" type="string" required="true">
	<cfset instance.Table = arguments.Table />
</cffunction>

<cffunction name="setTableAlias" access="private" returntype="void" output="false">
	<cfargument name="tableAlias" type="string" required="true">
	<cfset instance.tableAlias = arguments.tableAlias />
</cffunction>

<cffunction name="setLinkFrom" access="private" returntype="void" output="false">
	<cfargument name="LinkFrom" type="Link" required="true">
	<cfset instance.LinkFrom = arguments.LinkFrom />
</cffunction>

<cffunction name="setLinkTo" access="private" returntype="void" output="false">
	<cfargument name="LinkTo" type="Link" required="true">
	<cfset instance.LinkTo = arguments.LinkTo />
</cffunction>

<cffunction name="setCollection" access="private" returntype="void" output="false">
	<cfargument name="Collection" type="Collection" required="true">
	<cfset instance.Collection = arguments.Collection />
</cffunction>

<cffunction name="getIsParent" access="private" returntype="boolean" output="false">
	<cfreturn instance.isParent />
</cffunction>

</cfcomponent>