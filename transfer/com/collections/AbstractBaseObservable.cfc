<!--- Document Information -----------------------------------------------------

Title:      AbstractBaseObservable.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    An abstract base for an observable pattern

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		22/02/2008		Created

------------------------------------------------------------------------------->

<cfcomponent hint="An abstract base for an observable pattern" output="false">

<cffunction name="addObserver" hint="Adds an observer" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer to be added" type="any" required="Yes">
	<cfargument name="key" hint="the key to add it under" type="string" required="No" default="#getSystem().identityHashCode(arguments.observer)#">
	<cfscript>
		StructInsert(getCollection(), arguments.key, arguments.observer, true);
	</cfscript>
</cffunction>

<cffunction name="removeObserver" hint="Removes an observer from the collection" access="public" returntype="void" output="false">
	<cfargument name="observer" hint="The observer to be removed (may be the soft reference)" type="any" required="Yes">
	<cfscript>
		var hash = getSystem().identityHashCode(arguments.observer);

		removeObserverByKey(hash);
	</cfscript>
</cffunction>

<cffunction name="removeObserverByKey" hint="If you have the identity key, you can remove it" access="public" returntype="void" output="false">
	<cfargument name="key" hint="The key to remove by" type="any" required="Yes">
	<cfscript>
		StructDelete(getCollection(), arguments.key);
	</cfscript>
</cffunction>

<cffunction name="fireEvent" hint="Fires off the event to all the Observers" access="public" returntype="void" output="false">
	<cfargument name="event" hint="The event object to fire" type="any" required="Yes">
	<cfscript>
		var counter = 1;
		var list = createObject("java", "java.util.ArrayList").init(getCollection().values());
		var len = ArrayLen(list);
		var eventObj = arguments.event;
		var item = 0;

		/*
		This has been tweaked to get as much speed out of it as possible.
		*/
		for(; counter lte len; counter = counter + 1)
		{
			try
			{
				item = list[counter];
			}
			catch(Expression exc)
			{
				/*
				do nothing, it is not likely that this will occur, but it *is* possible under high load
				as null values can creep in due to lack of synchronisation on the init() of the ArrayList.
				*/
			}

			fireActionMethod(item, eventObj);
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="init" hint="Constructor" access="private" returntype="void" output="false">
	<cfscript>
		var linkedHashMap = createObject("java", "java.util.LinkedHashMap").init();
		var Collections = createObject("java", "java.util.Collections");

		variables.instance = StructNew();

		setSystem(createObject("java", "java.lang.System"));

		setCollection(Collections.synchronizedMap(linkedHashMap));
	</cfscript>
</cffunction>

<cffunction name="fireActionMethod" hint="virtual: fires the action method" access="private" returntype="void" output="false">
	<cfargument name="object" hint="the object to fire against" type="any" required="Yes">
	<cfargument name="event" hint="The event object to fire" type="any" required="Yes">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="getCollection" access="private" returntype="any" output="false">
	<cfreturn instance.Collection />
</cffunction>

<cffunction name="setCollection" access="private" returntype="void" output="false">
	<cfargument name="Collection" type="any" required="true">
	<cfset instance.Collection = arguments.Collection />
</cffunction>

<cffunction name="getSystem" access="private" returntype="any" output="false">
	<cfreturn instance.System />
</cffunction>

<cffunction name="setSystem" access="private" returntype="void" output="false">
	<cfargument name="System" type="any" required="true">
	<cfset instance.System = arguments.System />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>


</cfcomponent>