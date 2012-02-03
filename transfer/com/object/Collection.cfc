<!--- Document Information -----------------------------------------------------

Title:      Collection.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    BO For a collection definition

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		01/08/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="Collection" hint="BO for a collection defintion">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="Collection" output="false">
	<cfscript>
		setType("");

		return this;
	</cfscript>
</cffunction>

<cffunction name="getType" access="public" returntype="string" output="false">
	<cfreturn instance.Type />
</cffunction>

<cffunction name="getKey" access="public" returntype="Key" output="false">
	<cfreturn instance.Key />
</cffunction>

<cffunction name="hasKey" hint="if the collection has a key" access="public" returntype="boolean" output="false">
	<cfreturn StructKeyExists(instance, "key")>
</cffunction>

<cffunction name="hasOrder" hint="if the collection has a Order" access="public" returntype="boolean" output="false">
	<cfreturn StructKeyExists(instance, "Order")>
</cffunction>

<cffunction name="getOrder" access="public" returntype="Order" output="false">
	<cfreturn instance.Order />
</cffunction>

<cffunction name="getCondition" access="public" returntype="Condition" output="false">
	<cfreturn instance.Condition />
</cffunction>

<cffunction name="hasCondition" hint="If it has a condition" access="public" returntype="boolean" output="false">
	<cfreturn StructKeyExists(instance, "Condition")>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		var key = 0;
		var order = 0;
		var condition = 0;

		setType(arguments.memento.type);
		removeKey();
		removeOrder();
		removeCondition();

		if(StructkeyExists(arguments.memento, "key"))
		{
			key = createObject("component", "transfer.com.object.Key").init();
			key.setMemento(arguments.memento.key);
			setKey(key);
		}

		if(StructkeyExists(arguments.memento, "order"))
		{
			order = createObject("component", "transfer.com.object.Order").init();
			order.setMemento(arguments.memento.order);
			setOrder(order);
		}

		if(StructkeyExists(arguments.memento, "condition"))
		{
			condition= createObject("component", "transfer.com.object.Condition").init();
			condition.setMemento(arguments.memento.condition);
			setCondition(condition);
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="removeCondition" hint="removes a condition" access="private" returntype="void" output="false">
	<cfset StructDelete(instance, "Condition")>
</cffunction>

<cffunction name="setCondition" access="private" returntype="void" output="false">
	<cfargument name="Condition" type="Condition" required="true">
	<cfset instance.Condition = arguments.Condition />
</cffunction>

<cffunction name="setType" access="private" returntype="void" output="false">
	<cfargument name="Type" type="string" required="true">
	<cfset instance.Type = arguments.Type />
</cffunction>

<cffunction name="setKey" access="private" returntype="void" output="false">
	<cfargument name="Key" type="Key" required="true">
	<cfset instance.Key = arguments.Key />
</cffunction>

<cffunction name="removeKey" hint="removes the key" access="private" returntype="void" output="false">
	<cfscript>
		StructDelete(instance, "key");
	</cfscript>
</cffunction>

<cffunction name="removeOrder" hint="removes the Order" access="private" returntype="void" output="false">
	<cfscript>
		StructDelete(instance, "order");
	</cfscript>
</cffunction>

<cffunction name="setOrder" access="private" returntype="void" output="false">
	<cfargument name="Order" type="Order" required="true">
	<cfset instance.Order = arguments.Order />
</cffunction>

</cfcomponent>