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
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	<!--- Meta Tags --->
	#renderView('tags/meta')#
	<!--- Base HREF --->
	<base href="#getSetting('htmlBaseURL')#/" />
	
	<cfloop list="#event.getValue("cssFullAppendList", "")#" index="css">
		<link rel="stylesheet" type="text/css" href="#css#.css" />
	</cfloop>
	<cfloop list="#event.getValue("jsFullAppendList", "")#" index="js">
		<script type="text/javascript" src="#js#.js"></script>
	</cfloop>
		#renderView('tags/header')#
			<!--- Render Custom HTML --->
			#rc.oCustomHTML.getBeforeSideBar()#
			#renderView('tags/sidebar')#
			<!--- Render Custom HTML --->
			#rc.oCustomHTML.getAfterSideBar()#
	<div class="footer">