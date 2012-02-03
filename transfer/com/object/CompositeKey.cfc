<!--- Document Information -----------------------------------------------------

Title:      CompositeKey.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    represents a composite key

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		09/07/2007		Created

------------------------------------------------------------------------------->

<cfcomponent name="CompositeKey" hint="Represents a Composite Key" extends="AbstractBaseKey">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="CompositeKey" output="false">
	<cfargument name="object" hint="The object that this is a key for" type="Object" required="Yes">
	<cfscript>
		variables.instance = StructNew();

		super.init();
		setObject(arguments.object);
		setPropertyCollection(ArrayNew(1));
		setParentOneToManyCollection(ArrayNew(1));
		setManyToOneCollection(ArrayNew(1));

		return this;
	</cfscript>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		var len = 0;
		var item = 0;
		var counter = 1;
		var compositeKey = arguments.memento.compositekey;

		arguments.memento.isComposite = true;

		super.setMemento(arguments.memento);

		//do properties
		len = ArrayLen(compositeKey.property);
		for(; counter lte len; counter = counter + 1)
		{
			item = compositeKey.property[counter];
			ArrayAppend(getPropertyCollection(), getObject().getPropertyByName(item.name));
		}

		//do parent one to many
		len = ArrayLen(compositeKey.parentOnetoMany);
		for(counter = 1; counter lte len; counter = counter + 1)
		{
			item = compositeKey.parentOneToMany[counter];
			ArrayAppend(getParentOneToManyCollection(), getObject().getParentOneToManyByClass(item.class));
		}

		//do manytoone
		len = ArrayLen(compositeKey.manyToOne);
		for(counter = 1; counter lte len; counter = counter + 1)
		{
			item = compositeKey.manytoone[counter];
			ArrayAppend(getManyToOneCollection(), getObject().getManytoOneByName(item.name));
		}
	</cfscript>
</cffunction>

<cffunction name="getPropertyIterator" hint="returns a java.util.Iterator for the properties" access="public" returntype="any" output="false">
	<cfreturn getPropertyCollection().iterator() />
</cffunction>

<cffunction name="getParentOneToManyIterator" hint="returns a java.util.Iterator for the parent onetomany" access="public" returntype="any" output="false">
	<cfreturn getParentOneToManyCollection().iterator() />
</cffunction>

<cffunction name="getManyToOneIterator" hint="returns a java.util.Iterator for the Manytoone" access="public" returntype="any" output="false">
	<cfreturn getManyToOneCollection().iterator() />
</cffunction>

<cffunction name="containsParentOneToManyByName" hint="Checks if it has a parent one to many as a member of the composite key" access="public" returntype="boolean" output="false">
	<cfargument name="name" hint="The name of the parent onetomany" type="string" required="Yes">
	<cfscript>
		var iterator = getParentOneToManyIterator();
		var parentonetomany = 0;

		while(iterator.hasNext())
		{
			parentonetomany = iterator.next();
			if(parentonetomany.getName() eq arguments.name)
			{
				return true;
			}
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="containsManyToOneByName" hint="Checks if it has a many to one as a member of the composite key" access="public" returntype="boolean" output="false">
	<cfargument name="name" hint="The name of the parent onetomany" type="string" required="Yes">
	<cfscript>
		var iterator = getManyToOneIterator();
		var manytoone = 0;

		while(iterator.hasNext())
		{
			manytoone = iterator.next();
			if(manytoone.getName() eq arguments.name)
			{
				return true;
			}
		}

		return false;
	</cfscript>
</cffunction>

<cffunction name="validate" hint="Throws an exception if validation fails" access="public" returntype="void" output="false">
	<cfscript>
		//need to vlaidate that no more than 1 parent one to many is lazy="false"
		var counter = 0;
		var iterator = getParentOneToManyIterator();
		var parentOneToMany = 0;
		var onetomany = 0;
		var list = "";

		while(iterator.hasNext())
		{
			parentOneToMany = iterator.next();
			onetomany = parentOneToMany.getLink().getToObject().getOneToManyByName(parentOneToMany.getName());

			if(NOT onetomany.getIsLazy())
			{
				throw("transfer.InvalidCompositeIDException",
						"All of the parent oneToMany declared in a 'compositeid' declaration' must be lazy='true'",
						"The operation you have tried to execute would have caused corrupt data, or an infinite loop. In object '#getObject().getClassName()#' the
						oneToMany '#parentOneToMany.getName()#' on object '#parentOneToMany.getLink().getToObject().getClassName()#' are lazy='false', when it must be lazy='true'");
			}
		}

	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getPropertyCollection" access="private" returntype="array" output="false">
	<cfreturn instance.PropertyCollection />
</cffunction>

<cffunction name="setPropertyCollection" access="private" returntype="void" output="false">
	<cfargument name="PropertyCollection" type="array" required="true">
	<cfset instance.PropertyCollection = arguments.PropertyCollection />
</cffunction>

<cffunction name="getManyToOneCollection" access="private" returntype="array" output="false">
	<cfreturn instance.ManyToOneCollection />
</cffunction>

<cffunction name="setManyToOneCollection" access="private" returntype="void" output="false">
	<cfargument name="ManyToOneCollection" type="array" required="true">
	<cfset instance.ManyToOneCollection = arguments.ManyToOneCollection />
</cffunction>

<cffunction name="getParentOneToManyCollection" access="private" returntype="array" output="false">
	<cfreturn instance.ParentOneToManyCollection />
</cffunction>

<cffunction name="setParentOneToManyCollection" access="private" returntype="void" output="false">
	<cfargument name="ParentOneToManyCollection" type="array" required="true">
	<cfset instance.ParentOneToManyCollection = arguments.ParentOneToManyCollection />
</cffunction>

<cffunction name="getObject" access="private" returntype="Object" output="false">
	<cfreturn instance.Object />
</cffunction>

<cffunction name="setObject" access="private" returntype="void" output="false">
	<cfargument name="Object" type="Object" required="true">
	<cfset instance.Object = arguments.Object />
</cffunction>

</cfcomponent>