<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <xsl:choose> 
        <xsl:when test="count(perldata/hashref/item) &gt; 0">
	    <xsl:variable name="group" select="perldata/hashref/item[@key='group']" />
	    <xsl:variable name="hostname" select="perldata/hashref/item[@key='hostname']" />
	    <xsl:variable name="rrd" select="perldata/hashref/item[@key='rrd']" />
        <xsl:variable name="description" select="perldata/hashref/item[@key='description']" />
        <xsl:variable name="title" select="perldata/hashref/item[@key='title']" />
        <xsl:variable name="last_updated" select="perldata/hashref/item[@key='last_updated']" />

        <h2>
            <xsl:value-of select="$title" />
            [<span class="description"><xsl:value-of select="$description" /></span>]
        </h2>

        <h3 class="subtitle"><xsl:value-of select="$rrd" /> - last updated <xsl:value-of select="$last_updated" /></h3>
        <input type="button" onclick="load_port_info('{$group}','{$hostname}','{$rrd}','{$title}','{$description}')" value="Refresh Statistics"/>

	    <xsl:for-each select="perldata/hashref/item[@key='graph']/hashref/item">
	        <xsl:variable name="dsin" select="hashref/item[@key='dslist']/hashref/item[@key='In']"/>
	        <xsl:variable name="dsout" select="hashref/item[@key='dslist']/hashref/item[@key='Out']"/>
            <xsl:variable name="colorin" select="hashref/item[@key='colors']/hashref/item[@key='In']"/>
	        <xsl:variable name="colorout" select="hashref/item[@key='colors']/hashref/item[@key='Out']"/>
	        <xsl:variable name="labelin" select="hashref/item[@key='labels']/hashref/item[@key='In']"/>
	        <xsl:variable name="labelout" select="hashref/item[@key='labels']/hashref/item[@key='Out']"/>
	        <xsl:variable name="yaxis" select="hashref/item[@key='yaxis']"/>
	        <xsl:variable name="scale" select="hashref/item[@key='scale']"/>

            <xsl:variable name="range" select="86400" /><!--set the default range-->
            <xsl:variable name="graph_name" select="@key" />
	        <div class = "datasection">
	            <h3><xsl:value-of select="@key" /></h3>
               
                <!--port statistics-->
                <div class="port_stats_container">
                
                <xsl:for-each select="hashref/item[@key='stats']/hashref/item">
                <div class="port_stats">
                    <h4><xsl:value-of select="@key" /></h4>
                    <table class="port_stats">
                    <xsl:for-each select="hashref/item">
                        <tr>
                            <td><xsl:value-of select="@key" /></td>
                            <td><xsl:value-of select="." /></td>
                        </tr>
                    </xsl:for-each>
                    </table>
                </div><!--end port stats div-->
                </xsl:for-each>                
                </div><!--end port stats container-->


                <!--data containers for use by javascript-->
                <form id="{$graph_name}_data">
                   <input type="hidden" name="rrd_path" value="{$group}/{$hostname}/{$rrd}" />
                   <input type="hidden" name="ds-list" value="{$dsin},{$dsout}" /> 
                   <input type="hidden" name="color-list" value="{$colorin},{$colorout}" /> 
                   <input type="hidden" name="label-list" value="{$labelin},{$labelout}" /> 
                   <input type="hidden" name="yaxis" value="{$yaxis}" /> 
                   <input type="hidden" name="scale" value="{$scale}" />
                   <input type="hidden" name="range" value="{$range}" id="{$graph_name}_range" />
                </form>
                
                <div id="{$graph_name}_graph" class="graph_container">
                    <img src="graph.cgi?rrd_path={$group}/{$hostname}/{$rrd}&amp;ds-list={$dsin},{$dsout}&amp;color-list={$colorin},{$colorout}&amp;yaxis={$yaxis}&amp;scale={$scale}&amp;label-list={$labelin},{$labelout}&amp;range={$range}"/>
	            </div>
                <!--slider for changing the range of the graph-->
                <!--todo: figure out a nice log scale for the slider (linear between 2 days and a year is too much)-->
                <div class="range_slider_container">
                    <div id="{$graph_name}_rangehr"></div> <!--human-readable range indication-->
                    <div id="{$graph_name}_range_slider"></div>
                    <span class="hint">Use the slider to adjust the time scale of the graph</span>
                    <span style="float: right"><input type="button" onclick="update_graph('{$graph_name}');" value="Refresh Graph"/></span>
                </div><!--end slider container-->

                <script type="text/javascript">
                    //alert("#<xsl:value-of select="$graph_name"/>_range_slider");
                    $("#<xsl:value-of select="$graph_name"/>_range_slider").slider({
                        range: "min",
                        value: 3,
                        min: 0,
                        max: 10,
                        step: 1,
                        change: function(event, ui) {
                                    
                                    //calculate the range based on the value of the slider
                                    var range;
                                    var rangehr;

                                    switch(ui.value)
                                    {
                                        case 0:
                                            range = 3600;
                                            rangehr = "Last Hour";
                                            break;
                                        
                                        case 1:
                                            range = 7200;
                                            rangehr = "Last two Hours";
                                            break;
                                        
                                        case 2:
                                            range = 43200;
                                            rangehr = "Last Twelve Hours";
                                            break;
                                        
                                        case 3: //make sure to change the initial values below!
                                            range = 86400;
                                            rangehr = "Last Day"; //default time range
                                            break;

                                        case 4:
                                            range = 151200;
                                            rangehr = "Last Two Days"
                                            break;
                                       
                                        case 5:
                                            range = 604800;
                                            rangehr = "Last Week";
                                            break;
                                        
                                        case 6:
                                            range = 1209600;
                                            rangehr = "Last Two Weeks";
                                            break;

                                        case 7:
                                            range = 2629743;
                                            rangehr = "Last Month";
                                            break;

                                        case 8:
                                            range = 15778463;
                                            rangehr = "Last Six Months";
                                            break;
                                        
                                        case 9:
                                            range = 31556926;
                                            rangehr = "Last Year";
                                            break;
                                        
                                        case 10:
                                            range = 63113851;
                                            rangehr = "Last Two Years";
                                            break;
                                    }//end time span definitions

                                
                                    //change the image based on the new range (if the range had changed)
                                    $("#<xsl:value-of select="$graph_name"/>_range").val(range);
                                    $("#<xsl:value-of select="$graph_name"/>_rangehr").html(rangehr);
                                    update_graph('<xsl:value-of select="$graph_name"/>');
                                
                                }//end change callback definition
                        });//end slider init

                    //set initial values for the range and range hr
                    $("#<xsl:value-of select="$graph_name"/>_rangehr").html("Last Day"); //default time range
                    $("#<xsl:value-of select="$graph_name"/>_range").val(86400);
                </script>

            </div>
	   </xsl:for-each><!--end foreach graph-->
       </xsl:when><!--end when records found-->
        
        <xsl:otherwise>
        <h1>No Records found!</h1>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
