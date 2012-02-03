<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2008 by
Luis Majano (Ortus Solutions, Corp) and Mark Mandel (Compound Theory)
www.transfer-orm.org |  www.coldboxframework.com
********************************************************************************
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
********************************************************************************
$Build Date: @@build_date@@
$Build ID:	@@build_id@@
********************************************************************************
----------------------------------------------------------------------->
<cfcomponent extends="baseHandler"
				 
	<!--- Dependencies --->
	<cfproperty name="SecurityService" 	type="ioc" scope="instance" />
	<cfproperty name="ConfigService" 	type="ioc" scope="instance" />

	<cffunction name="init" access="public" returntype="main" output="false">
		<cfargument name="controller" type="any" required="yes">
		<cfscript>
			super.init(arguments.controller);
			
			// Show Keys
			instance.showKey = getSetting('showKey');
			instance.spaceKey = getSetting('spaceKey');
			
			return this;
		</cfscript>
	</cffunction>	

<!------------------------------------------- Implicit Events ------------------------------------------>

	<cffunction name="onAppInit" access="public" returntype="void" output="false">
			// Get Wiki Options
			var Options = getConfigService().getOptions();
			
			// Cache Them
			getColdboxOCM().set("CodexOptions",Options,0);
			
			// Check ShowKey
			if( getSetting("ShowKey") eq "" or getSetting("ShowKey") eq "page"){
				$throw(message="Invalid Show Key Detected",
					  detail="The ShowKey setting cannot be left blank or named 'page'. Please change it in the coldbox.xml",
					  type="Codex.InvalidShowKeyException");
			}
			
			// Check SpaceKEy
			if( getSetting("SpaceKey") eq "" or getSetting("SpaceKey") eq "page"){
				$throw(message="Invalid Space Key Detected",
					  detail="The SpaceKey setting cannot be left blank or named 'page'. Please change it in the coldbox.xml",
					  type="Codex.InvalidSpaceKeyException");
			}
		</cfscript>
		<cfsetting showdebugoutput="#getDebugMode()#">
		<cfscript>
			// Setup the global exit handlers For the admin
			rc.xehAdmin = "admin/main/home";
			if( reFindnocase("^admin",event.getCurrentEvent()) ){
				rc.xehAdminUsers = "admin/users/list";
				rc.xehAdminRoles = "admin/roles/list";
				
				/* Wiki Admin */
				rc.xehAdminNamespace = "admin/namespace/list";
				rc.xehAdminCategories = "admin/categories/list";
				rc.xehAdminComments = "admin/comments/list";
				
				/* Plugin Menu */
				rc.xehAdminPlugins = "admin/plugins/list";
				rc.xehAdminPluginDocs = "admin/plugins/docs";
				
				/* Tools Menu */
				rc.xehAdminAPI = "admin/tools/api";
				rc.xehAdminConverter = "admin/tools/converter";
				
				/* Settings Menu */
				rc.xehAdminOptions = "admin/config/options";
				rc.xehAdminCommentOptions = "admin/config/comments";
				rc.xehAdminCustomHTML = "admin/config/customhtml";
				rc.xehAdminLookups = "admin/lookups/display";
			}
			rc.xehSpecialCategory = "#instance.showKey#/Special:Categories";
			rc.xehWikiSearch = "page/search";
			rc.xehPageDirectory = "page/directory";
			rc.xehSpaceDirectory = "spaces";
			
			/* Global User Exit Handlers */
			rc.CodexOptions = getColdboxOCM().get('CodexOptions');
		</cfscript>
			var invalidList = "Framework.invalidEventException,Framework.EventHandlerNotRegisteredException";
			
			
			/* Test for 404 errors */
			if( listfindnocase(invalidList,exceptionBean.getType()) ){
				setNextRoute("notfound");
			}
	
	<cffunction name="notfound" access="public" returntype="void" output="false" hint="A not found 404 page">
		<cfargument name="Event" type="any">
		<cfheader statuscode="404" statustext="Page Not Found" />
		<cfset event.setView("main/notFound")>
	</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------->

	