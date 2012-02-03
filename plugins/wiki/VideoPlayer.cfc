<cfcomponent name="VideoPlayer" 
			 hint="A video player for Codex" 
			 extends="coldbox.system.plugin" 
			 output="false" 
			 cache="false">
				 
				 
		<-------------------------------------------- CONSTRUCTOR ------------------------------------------->	
   
    <cffunction name="init" access="public" returntype="VideoPlayer" output="false">
		<cfargument name="controller" type="any" required="true">
		<cfscript>
  		super.Init(arguments.controller);
  		setpluginName("VideoPlayer");
  		setpluginVersion("1.0");
  		setpluginDescription("A video player wiki plugin");
  		return this;
		</cfscript>
	</cffunction>

<-------------------------------------------- PUBLIC ------------------------------------------->	

	<cffunction name="renderit" output="false" access="public" returntype="string" hint="print today">
		<cfargument name="video" type="string" required="true" hint="The absolute source of the flv file"/>
		<cfargument name="width" type="numeric" required="false" default="640" hint="The width of the video"/>
		<cfargument name="height" type="numeric" required="false" default="385" hint="The height of the video"/>
		<cfargument name="preview" type="string" required="false" default="" hint="The absolute source of a preview image for the video"/>
		<cfset var returnVid  = "">
		<cfparam name="REQUEST.cfvideoid" default="1">
		
		<cfset REQUEST.cfvideoid = REQUEST.cfvideoid + 1>
		
		<cfsavecontent variable="returnVid">
			<cfoutput>
		<script type="text/javascript" src="/railo-context/swfobject.js.cfm"></script><div id="ph_#REQUEST.cfvideoid#"><a href="http://www.macromedia.com/go/getflashplayer">Get the Flash Player</a> to see this player.</a></div>
		<script type="text/javascript"> 
			var so = new SWFObject("/railo-context/mediaplayer.swf.cfm", "swf_#REQUEST.cfvideoid#", "#arguments.width#", "#arguments.height#", "8", "##333333");
			so.addParam('allowscriptaccess','always');
			so.addVariable('enablejs',true);
			so.addVariable('javascriptid','swf_#REQUEST.cfvideoid#');
			so.addVariable('shuffle',false);
			so.addVariable('linktarget','_self');
			so.addVariable('linkfromdisplay',false);
			so.addVariable('abouttxt','Railo Video Player');
			so.addVariable('aboutlnk','http://www.getrailo.org');
			so.addParam('allowfullscreen','true');
			so.addParam('usefullscreen','true');
			so.addVariable('autostart',false);
			so.addVariable('showdownload',false);
			so.addVariable('backcolor','0x333333');
			so.addVariable('frontcolor','0xc6c6c6');
			so.addVariable('lightcolor','0xffffff');
			so.addVariable('screencolor','0x000000');
			so.addVariable('width','#arguments.width#');
			so.addVariable('height','#arguments.height#');
			so.write("ph_#REQUEST.cfvideoid#");
			addItem('swf_#REQUEST.cfvideoid#',{file:'#arguments.video#'<cfif Len(arguments.preview)>,image:'#arguments.preview#'</cfif>});
			</script> 
			</cfoutput>
		</cfsavecontent>
		<cfreturn returnVid>
	</cffunction>		 
				 
				 
</cfcomponent>