<!--- Document Information -----------------------------------------------------

Title:      DummySoftReferenceRegister.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Dummy register, for none caching

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/07/2008		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Dummy register, for none caching" output="false" extends="SoftReferenceRegister">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="DummySoftReferenceRegister" output="false">
	<cfscript>
		variables.instance = StructNew();

		return this;
	</cfscript>
</cffunction>

<cffunction name="register" hint="Returns a soft reference, that isn't stored anywhere" access="public" returntype="any" output="false">
	<cfargument name="transfer" hint="The transfer object" type="transfer.com.TransferObject" required="Yes">
	<cfscript>
		var softRef = createObject("java", "java.lang.ref.SoftReference").init(arguments.transfer);

		return softRef;
	</cfscript>
</cffunction>

<cffunction name="clearAllReferences" hint="Does nothing, as no soft ref's are stored" access="public" returntype="void" output="false">
</cffunction>

<cffunction name="reap" hint="does nothing, as there is nothing to reap" access="public" returntype="void" output="false">
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>