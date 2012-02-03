<cfsetting enablecfoutputonly="true">
<!--- Document Information -----------------------------------------------------

Title:      cacheReport.cfm

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    custom tag for displaying caching reports

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		25/07/2008		Created

------------------------------------------------------------------------------->

<!--- bounce out --->
<cfif thisTag.ExecutionMode eq "end">
	<cfexit method="exittag">
</cfif>

<cfparam name="attributes.monitor" type="any">
<!--- what mode the report is in, basic, detailed --->
<cfparam name="attributes.mode" type="string" default="basic">
<cfparam name="attributes.chartSize" type="numeric" default="400">

<cfsavecontent variable="css">
<cfoutput>
	<style type="text/css">
		##transfer-cachereport {
			width: 800px;
			margin: 0 auto 0 auto;
			font-family: Helvetica, Verdana, san-serif;
		}

		##transfer-title {
		}

		##transfer-title img {
			float: right;
		}

		.transfer-report {
			padding: 1em;
			margin: 0.6em;
			background: ##ddd;
		}

		.transfer-report img {
			margin-left: 1em;
		}

		.transfer-report-statistics {
			valign: top;
			float: right;
			width: 310px;
		}
	</style>
</cfoutput>
</cfsavecontent>

<cfhtmlhead text="#css#">

<cfoutput>
<div id="transfer-cachereport">
	<div id="transfer-title">
		<img src="http://www.transfer-orm.com/resources/images/transfer_poweredby.png" />
		<h1>Transfer Cache Report</h1>
	</div>
	<div id="transfer-report-content">

	<cfset classes = attributes.monitor.getCachedClasses() />
	<cfset len = ArrayLen(classes) />

	<cfswitch expression="#attributes.mode#">
		<cfcase value="basic">
		<p>
			Basic Report
		</p>
		<div class="transfer-report">
			<div class="transfer-report-statistics">
				<p>
					<strong>Total Estimated Size</strong><br /> #attributes.monitor.getTotalEstimatedSize()#
				</p>
			</div>

			<cfchart format="png" title="Estimated Cache Sizes" show3D="true" chartheight="#attributes.chartSize#" chartwidth="#attributes.chartSize#" showborder="true">
				<cfchartseries type="pie">
					<cfloop from="1" to="#len#" index="counter">
						<cfset class = classes[counter] />
						<cfchartdata item="#class#" value="#attributes.monitor.getEstimatedSize(class)#">
					</cfloop>
				</cfchartseries>
			</cfchart>
		</div>
		<div class="transfer-report">

			<div class="transfer-report-statistics">
				<p>
					<strong>Total Hit/Miss Ratio</strong><br /> #attributes.monitor.getTotalHitMissRatio()#<br/>
				</p>
				<p>
					<strong>Total Cache Evictions</strong><br /> #attributes.monitor.getTotalEvictions()#
				</p>
			</div>
			<cfchart format="png" title="Total Hits vs Misses" show3D="true" chartheight="#attributes.chartSize#" chartwidth="#attributes.chartSize#" showborder="true">
				<cfchartseries type="pie" colorlist="00B335,B30100">
					<cfchartdata item="Hits" value="#attributes.monitor.getTotalHits()#">
					<cfchartdata item="Misses" value="#attributes.monitor.getTotalMisses()#">
				</cfchartseries>
			</cfchart>
		</div>

		</cfcase>
		<cfcase value="detail">
			<p>
				Detailed Report
			</p>
			<cfloop from="1" to="#len#" index="counter">
				<cfset class = classes[counter]/>
				<cfset settings = attributes.monitor.getCacheSettings(class) />
				<div class="transfer-report">

					<div class="transfer-report-statistics">
						<p>
							<strong>Hit/Miss Ratio</strong><br /> #attributes.monitor.getHitMissRatio(class)# <br/>
						</p>
						<p>
							<strong>Cache Scope</strong><br /> #settings.scope#
						</p>
						<p>
							<strong>Cache Maximum Timeout</strong><br /> #settings.maxminutespersisted# minutes
						</p>
						<p>
							<strong>Cache Accessed Timeout</strong><br /> #settings.accessedminutestimeout# minutes
						</p>
						<p>
							<strong>Maximum Cached Objects</strong><br /> #settings.maxobjects#
						</p>
					</div>

					<cfchart format="png" title="#class#" show3D="true" chartheight="#attributes.chartSize#" chartwidth="#attributes.chartSize#" showborder="true">
						<cfchartseries type="bar" colorlist="fea620,427bfb,93943d,c5c716">
							<cfchartdata item="Extimated Size" value="#attributes.monitor.getEstimatedSize(class)#">
							<cfchartdata item="Hits" value="#attributes.monitor.getHits(class)#">
							<cfchartdata item="Misses" value="#attributes.monitor.getMisses(class)#">
							<cfchartdata item="Evictions" value="#attributes.monitor.getEvictions(class)#">
						</cfchartseries>
					</cfchart>

				</div>

			</cfloop>

		</cfcase>

		<cfdefaultcase>
			<cfthrow type="transfer.InvalidCacheReportMode"
					 message="Invalid mode for the CacheReport tag."
					 detail="The mode '#attributes.mode#' is invalid, it must be of type 'basic' or 'detail'">
		</cfdefaultcase>
	</cfswitch>

	</div>
</div>
</cfoutput>


<cfsetting enablecfoutputonly="false">