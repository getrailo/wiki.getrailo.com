<!--- Document Information -----------------------------------------------------

Title:      TQLConverter.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Converts TQL statements back to regular SQL

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		11/07/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="TQLConverter" hint="Converts TQL statements back to regular SQL">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="TQLConverter" output="false">
	<cfscript>
		return this;
	</cfscript>
</cffunction>

<cffunction name="replaceProperties" hint="replaces {property} calls" access="public" returntype="string" output="false">
	<cfargument name="object" hint="The object the properties are read from" type="transfer.com.object.Object" required="Yes">
	<cfargument name="whereSQL" hint="The Where SQL statement" type="string" required="Yes">
	<cfargument name="table" hint="The table to map this property to, default to the object's table" type="string" required="No" default="#arguments.object.getTable()#">

	<cfscript>
		var results = 0;
		var property = 0;
		var check = true;
		var regex = "{([^}]*)}";

		while(check)
		{
			results = refind(regex, arguments.whereSQL, 1, true);

			if(results.len[1])
			{
				property = mid(arguments.whereSQL, results.pos[2], results.len[2]);
				arguments.whereSQL = replaceNoCase(arguments.whereSQL, "{"& property &"}", arguments.table  & "." & object.getPropertyByName(property).getColumn(), "all");
			}
			else
			{
				check = false;
			}
		}

		return arguments.whereSQL;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>