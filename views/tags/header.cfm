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
<cfoutput>
<!--- Main Header And Tabs --->



<div id="header" class="topbar">
	<div class="topbar-inner">
        <div class="container-fluid">
		<a class="brand" href="#getSetting('htmlBaseURL')#">#rc.CodexOptions.wiki_name#</a>

		<cfif not event.valueExists("print")>
          <ul class="nav">
			<!--- Wiki Tab --->
			<li <cfif refindnocase("^page",event.getCurrentEvent())>class="active"</cfif>>
				<a href="#event.buildLink(pageShowRoot(rc.CodexOptions.wiki_defaultpage))#"><span>Wiki</span></a>
			</li>
	
			<cfif rc.oUser.getisAuthorized()>
			<!--- User Profile Tab --->
			<li <cfif refindnocase("^profile",event.getCurrentEvent())>class="active"</cfif>>
				<a href="#event.buildLink(rc.xehUserProfile)#"><span>My Profile</span></a>
			</li>
			</cfif>
	
			<!--- Admin Tab --->
			<cfif rc.oUser.checkPermission("WIKI_ADMIN")>
			<li <cfif refindnocase("^admin",event.getCurrentEvent())>class="active"</cfif> >
				<a href="#event.buildLink(rc.xehAdmin)#"><span class="adminTab">Admin</span></a>
			</li>
			</cfif>
		</ul>
		</cfif>
		
			<cfif rc.oUser.getisAuthorized()>
				<p class="pull-right">Logged in as <a href="#event.buildLink(rc.xehUserProfile)#">#RC.OUSER.GETFNAME()# #RC.OUSER.GETLNAME()#</a></p>
				
			</cfif>
			<cfif not event.valueExists("print")>
			<p class="pull-right">
			<form method="post" class="search" action="#event.buildLink(rc.xehWikiSearch)#">
				<input name="search_query" class="textbox" type="text" placeholder="Search"/>
				<input name="search" value="Search" type="submit" />
			</form>
			</p>
			</cfif>
        </div>
      </div>
</div>


</cfoutput>