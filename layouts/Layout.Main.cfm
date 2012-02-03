<!DOCTYPE html>
<html lang="en">
  <head>
	<meta charset="utf-8">
	<cfoutput>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
	<meta name="Robots" content="index,follow" />
	<!--- Meta Tags --->
	#renderView('tags/meta')#
	<!--- Base HREF --->
	<base href="#getSetting('htmlBaseURL')#/" />

   	<!--- Render Title --->
	#renderView('tags/title')#
  

    <!-- Le HTML5 shim, for IE6-8 support of HTML elements -->
    <!--[if lt IE 9]>
      <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->

    <!-- Le styles -->
    <link href="/assets/css/bootstrap.min.css" rel="stylesheet">
    <style type="text/css">
      body {
        padding-top: 60px;
      }
    </style>

    <!-- Le fav and touch icons -->
    <link rel="shortcut icon" href="/favicon.ico">
			<!--- loop around the cssAppendList, to add page specific css --->	<cfloop list="#event.getValue("cssAppendList", "")#" index="css">		<link rel="stylesheet" type="text/css" href="includes/css/#css#.css" />	</cfloop>
	<cfloop list="#event.getValue("cssFullAppendList", "")#" index="css">
		<link rel="stylesheet" type="text/css" href="#css#.css" />
	</cfloop>	<!--- Global JS --->	<script type="text/javascript" src="includes/scripts/jquery-latest.pack.js"></script>	<script type="text/javascript" src="includes/scripts/codex.js"></script>	<cfloop list="#event.getValue("jsAppendList", "")#" index="js">		<script type="text/javascript" src="includes/scripts/#js#.js"></script>	</cfloop>
	<cfloop list="#event.getValue("jsFullAppendList", "")#" index="js">
		<script type="text/javascript" src="#js#.js"></script>
	</cfloop>	<!--- Render Custom HTML --->	#rc.oCustomHTML.getbeforeHeadEnd()#	</cfoutput></head><cfoutput><body>
	#renderView('tags/header')#
	<!--- Render Custom HTML --->	#rc.oCustomHTML.getafterBodyStart()#
	
	<div class="container-fluid">
      <div class="sidebar">
        <div class="well">
        <!--- Render Custom HTML --->
			#rc.oCustomHTML.getBeforeSideBar()#
			<!--- Render SideBar --->
			#renderView('tags/sidebar')#
			<!--- Render Custom HTML --->
			#rc.oCustomHTML.getAfterSideBar()# 
		<!--- 
		 <h5>Sidebar</h5>
          <ul>
            <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
          </ul>
          <h5>Sidebar</h5>
          <ul>
            <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
          </ul>
          <h5>Sidebar</h5>
          <ul>
            <li><a href="#">Link</a></li>
            <li><a href="#">Link</a></li>
          </ul> --->
        </div>
      </div>
	
	
	 <div class="content">
		#renderView()#
		
		<footer>
		#renderView('tags/footer')#
		</footer>
	</div>
		
		<!--- Render Custom HTML --->	#rc.oCustomHTML.getbeforeBodyEnd()#
	
	</div></body></cfoutput></html>