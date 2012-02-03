<!--- Document Information -----------------------------------------------------

Title:      SessionFacade.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Facade to the Session Scope

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		16/05/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="SessionFacade" hint="Facade to the Session Scope" extends="AbstractBaseFacade">

<cffunction name="configure" hint="Constructor" access="public" returntype="AbstractBaseFacade" output="false">
	<cfargument name="key" hint="The key to store values under" type="string" required="Yes">
	<cfscript>
		super.configure(arguments.key);

		setIsSessionEnabled(false);

		//the best way of checking if sessions are enabled
		try
		{
			session[arguments.key] = StructNew();
			setIsSessionEnabled(true);
		}
		catch(Any exc)
		{
			//don't do anything really, we're just using this as a 1 time check
		}

		return this;
	</cfscript>
</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getIsSessionEnabled" access="private" returntype="boolean" output="false">
	<cfreturn instance.IsSessionEnabled />
</cffunction>

<cffunction name="setIsSessionEnabled" access="private" returntype="void" output="false">
	<cfargument name="IsSessionEnabled" type="boolean" required="true">
	<cfset instance.IsSessionEnabled = arguments.IsSessionEnabled />
</cffunction>

<cffunction name="getScope" hint="returns the Session scope" access="private" returntype="struct" output="false">
	<cfif getIsSessionEnabled()>
		<cfif isDefined("session")>
			<cfreturn session>
		<cfelse>
			<!--- could be on session end --->
			<cfreturn StructNew() />
		</cfif>
	<cfelse>
		<!--- could be in onApplicationEnd --->
		<cfif isDefined("request")>
			<cfreturn request>
		<cfelse>
			<cfreturn StructNew() />
		</cfif>
	</cfif>
</cffunction>

</cfcomponent>