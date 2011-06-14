<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <xsl:choose> 
        <xsl:when test="count(perldata/hashref/item) &gt; 0">
            <ul>
            <xsl:for-each select="perldata/hashref/item"><!--foreach node-->
                <xsl:sort select="hashref/item[@key='sort_key']" data-type="number" />

                <xsl:variable name="path" select="hashref/item[@key='path']" />
                <xsl:variable name="description" select="hashref/item[@key='description']" />
                <xsl:variable name="data" select="hashref/item[@key='data']" />
                <xsl:variable name="action" select="hashref/item[@key='action']" />
                <xsl:variable name="node" select="@key" />

                <!--for telling whether we're processing a leaf or not-->
                <xsl:variable name="type" select="hashref/item[@key='type']" />
                <xsl:choose>
                    <xsl:when test="$type='leaf'">
                        <li id="{$path}_{$node}" class="data">
                            <!--if there is an action to be performed when the leaf is clicked,
                                do it, otherwise just present the data-->
                            <xsl:choose>
                                <xsl:when test="$action != ''">

                                    <a onclick="{$action}" class="clickable highlight">
                                        <!-- add a description if it exists-->
                                        <xsl:if test="$description != ''">
                                            <xsl:value-of select="$description" /> -
                                        </xsl:if>

                                        <xsl:value-of select="$data" />
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>

                                    <!-- add a description if it exists-->
                                    <xsl:if test="$description != ''">
                                        <xsl:value-of select="$description" /> -
                                    </xsl:if>
                                    
                                    <xsl:value-of select="$data" />
                                </xsl:otherwise>
                            </xsl:choose>
                            
                        </li>
                    </xsl:when><!--end leaf node-->

                    <xsl:otherwise><!--node is a subtree-->
                        <li id="{$path}_{$node}-parent" class="expandable">
                            <!--togle the subtree of $node -->
                            <h4  class="clickable heading" onclick="toggle_subtree('{$path}','{$path}_{$node}')">
                                <xsl:value-of select="$node"/> 
                                <xsl:if test="$description != ''">
                                    <span class="description">[<xsl:value-of select="$description" />]</span>
                                </xsl:if>
                            </h4> 
                            <!--for containing the subtree of the node-->
                            <div id="{$path}_{$node}-child" class="inactive">
                            </div><!--end subtree-->
                        </li>
                    </xsl:otherwise><!--end subtree node-->
                </xsl:choose><!--end data choose-->
            </xsl:for-each><!--end foreach node-->
            </ul>
        </xsl:when>
        
        <xsl:otherwise>
        <h4>No Records found!</h4>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
