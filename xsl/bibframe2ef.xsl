<?xml version='1.0'?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:bf="http://id.loc.gov/ontologies/bibframe/"
                xmlns:dct="http://purl.org/dc/terms/"
                xmlns:htrc="http://wcsa.htrc.illinois.edu/">

    <xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes" />

    <!-- Metadata schema that this stylesheet adheres to -->
    <xsl:variable name="schema_version">https://schemas.hathitrust.org/EF_Schema_MetadataSubSchema_v_3.0</xsl:variable>

    <xsl:key name="lang_combined" match="." use="." />
    <xsl:param name="pPat">"</xsl:param>
    <xsl:param name="pRep">\\"</xsl:param>
    <xsl:param name="oneSlash">\\</xsl:param>
    <xsl:param name="twoSlash">\\\\</xsl:param>

    <xsl:template match='/'>
        <xsl:variable name="Item" select="/rdf:RDF/bf:Item[starts-with(@rdf:about,'http://hdl.handle.net/2027/')]" />
        <xsl:text>{</xsl:text>
        <xsl:for-each select="$Item">
            <xsl:variable name="volume_id" select="substring(./@rdf:about,28)" />
            <xsl:variable name="instance_id" select="./bf:itemOf/@rdf:resource" />
            <xsl:variable name="Instance" select="/rdf:RDF/bf:Instance[@rdf:about = $instance_id][1]" />
            <xsl:variable name="work_id" select="$Instance/bf:instanceOf/@rdf:resource" />
            <xsl:variable name="Work" select="/rdf:RDF/bf:Work[@rdf:about = $work_id][1]" />

            <xsl:if test="position() != 1">
                <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text>"</xsl:text><xsl:value-of select="$volume_id" /><xsl:text>": {</xsl:text>
            <xsl:text>"@context": "https://worksets.hathitrust.org/context/ef_context.jsonld"</xsl:text>
            <xsl:text>,"metadata":{</xsl:text>
            <xsl:text>"schemaVersion":"</xsl:text><xsl:value-of select="$schema_version" /><xsl:text>"</xsl:text>
            <xsl:text>,"id":"</xsl:text><xsl:value-of select="./@rdf:about" /><xsl:text>"</xsl:text>
            <xsl:text>,"type": [ "DataFeedItem", </xsl:text>
            <xsl:choose>
                <xsl:when test="substring($Instance/bf:issuance/bf:Issuance/@rdf:about,39) = 'mono'">
                    <xsl:text>"Book"</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="substring($Instance/bf:issuance/bf:Issuance/@rdf:about,39) = 'serl'">
                            <xsl:text>"PublicationVolume"</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>"CreativeWork"</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text> ]</xsl:text>
            <xsl:text>,"dateCreated":</xsl:text><xsl:value-of select="format-date(current-date(),'[Y0001][M01][D01]')" />
            <xsl:call-template name="title">
                <xsl:with-param name="Instance" select="$Instance" />
            </xsl:call-template>
            <xsl:call-template name="contribution_agents">
                <xsl:with-param name="node" select="$Work/bf:contribution/bf:Contribution[bf:agent/bf:Agent/rdfs:label/text()]" />
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test="./dct:created">
                    <xsl:call-template name="date">
                        <xsl:with-param name="node" select="./dct:created" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$Instance/bf:provisionActivity/bf:ProvisionActivity/bf:date and $Instance/bf:provisionActivity/bf:ProvisionActivity/rdf:type[@rdf:resource = 'http://id.loc.gov/ontologies/bibframe/Publication']">
                    <xsl:choose>
                        <xsl:when test="$Instance/bf:provisionActivity/bf:ProvisionActivity/bf:date[@rdf:datatype = 'http://id.loc.gov/datatypes/edtf']">
                            <xsl:call-template name="date">
                                <xsl:with-param name="node" select="$Instance/bf:provisionActivity/bf:ProvisionActivity/bf:date[@rdf:datatype = 'http://id.loc.gov/datatypes/edtf']" />
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="date">
                                <xsl:with-param name="node" select="$Instance/bf:provisionActivity/bf:ProvisionActivity/bf:date" />
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>,"pubDate": null</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="publisher">
                <xsl:with-param name="Instance" select="$Instance" />
            </xsl:call-template>
            <xsl:call-template name="pub_place">
                <xsl:with-param name="Instance" select="$Instance" />
            </xsl:call-template>
            <xsl:call-template name="languages">
                <xsl:with-param name="langs" select='$Work/bf:language/bf:Language/@rdf:about[matches(substring(.,40),"[a-z]{3}")] | $Work/bf:language/bf:Language/bf:identifiedBy/bf:Identifier/rdf:value/@rdf:resource[matches(substring(.,40),"[a-z]{3}")]' />
            </xsl:call-template>
            <xsl:if test="./dct:accessRights">
                <xsl:text>,"accessRights":"</xsl:text><xsl:value-of select="./dct:accessRights/text()" /><xsl:text>"</xsl:text>
            </xsl:if>
            <xsl:if test="./dct:accessRights">
                <xsl:choose>
                    <xsl:when test="./dct:accessRights/text() = 'pd'">
                        <xsl:text>,"isAccessibleForFree": true</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>,"isAccessibleForFree": false</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="./htrc:contentProviderAgent/@rdf:resource">
                <xsl:text>,"sourceInstitution":{</xsl:text>
                <xsl:text>"type":"http://id.loc.gov/ontologies/bibframe/Organization"</xsl:text>
                <xsl:text>,"name":"</xsl:text><xsl:value-of select="substring(./htrc:contentProviderAgent/@rdf:resource,52)" /><xsl:text>"</xsl:text>
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:if test="$Work/bf:adminMetadata/bf:AdminMetadata/bf:identifiedBy/bf:Local/rdf:value or starts-with($Instance/@rdf:about, 'http://www.worldcat.org')">
                <xsl:text>,"mainEntityOfPage":[</xsl:text>
                <xsl:if test="$Work/bf:adminMetadata/bf:AdminMetadata/bf:identifiedBy/bf:Local/rdf:value">
                    <xsl:text>"https://catalog.hathitrust.org/Record/</xsl:text><xsl:value-of select="$Work/bf:adminMetadata/bf:AdminMetadata/bf:identifiedBy/bf:Local/rdf:value/text()" /><xsl:text>"</xsl:text>
                </xsl:if>
                <xsl:if test="starts-with($Instance/@rdf:about, 'http://www.worldcat.org')">
                    <xsl:text>,"http://catalog.hathitrust.org/api/volumes/brief/oclc/</xsl:text><xsl:value-of select="substring($Instance/@rdf:about,30)" /><xsl:text>.json"</xsl:text>
                    <xsl:text>,"http://catalog.hathitrust.org/api/volumes/full/oclc/</xsl:text><xsl:value-of select="substring($Instance/@rdf:about,30)" /><xsl:text>.json"</xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:text>]</xsl:text>
            <xsl:call-template name="create_identifiers">
                <xsl:with-param name="Instance" select="$Instance" />
                <xsl:with-param name="Work" select="$Work" />
            </xsl:call-template>
            <xsl:call-template name="is_n">
                <xsl:with-param name="base_path" select="$Instance/bf:identifiedBy/bf:Issn" />
                <xsl:with-param name="is_n" select="'issn'" />
            </xsl:call-template>
            <xsl:call-template name="is_n">
                <xsl:with-param name="base_path" select="$Instance/bf:identifiedBy/bf:Isbn" />
                <xsl:with-param name="is_n" select="'isbn'" />
            </xsl:call-template>
            <!--				<xsl:call-template name="subject">
                                <xsl:with-param name="Work" select="$Work" />
                            </xsl:call-template>-->
            <xsl:call-template name="genre">
                <xsl:with-param name="Work" select="$Work" />
            </xsl:call-template>
            <xsl:if test="./bf:enumerationAndChronology">
                <xsl:text>,"enumerationChronology":"</xsl:text><xsl:value-of select="replace(replace(./bf:enumerationAndChronology/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
            </xsl:if>
            <xsl:if test="$Work/rdf:type/@rdf:resource">
                <xsl:text>,"typeOfResource":"</xsl:text><xsl:value-of select="$Work/rdf:type/@rdf:resource" /><xsl:text>"</xsl:text>
            </xsl:if>
            <xsl:if test="./htrc:lastRightsUpdateDate">
                <xsl:text>,"lastRightsUpdateDate":</xsl:text><xsl:value-of select="./htrc:lastRightsUpdateDate/text()" />
            </xsl:if>
            <xsl:call-template name="part_of">
                <xsl:with-param name="Instance" select="$Instance" />
                <xsl:with-param name="Work" select="$Work" />
            </xsl:call-template>
            <xsl:text>}</xsl:text>
            <xsl:text>}</xsl:text>
        </xsl:for-each>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template name="title">
        <xsl:param name="Instance" />
        <xsl:variable name="iss_title" select="$Instance/bf:title/bf:Title[not(rdf:type)]" />
        <xsl:variable name="var_titles" select="$Instance/bf:title/bf:Title[rdf:type/@rdf:resource = 'http://id.loc.gov/ontologies/bibframe/VariantTitle']" />
        <xsl:choose>
            <xsl:when test="count($iss_title) = 1">
                <xsl:text>,"title":"</xsl:text><xsl:value-of select="replace(replace($iss_title/rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>,"title":"</xsl:text><xsl:value-of select="replace(replace($iss_title[1]/rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="count($var_titles) > 0">
                <xsl:text>,"alternateTitle":[</xsl:text>
                <xsl:for-each select="$var_titles">
                    <xsl:if test="position() != 1">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                    <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(./rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                </xsl:for-each>
                <xsl:if test="count($iss_title) > 1">
                    <xsl:for-each select="$iss_title">
                        <xsl:if test="position() != 1">
                            <xsl:text>,"</xsl:text><xsl:value-of select="replace(replace(./rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
                <xsl:text>]</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="count($iss_title) > 1">
                    <xsl:text>,"alternateTitle":[</xsl:text>
                    <xsl:for-each select="$iss_title">
                        <xsl:if test="position() != 1">
                            <xsl:if test="position() > 2">
                                <xsl:text>,</xsl:text>
                            </xsl:if>
                            <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(./rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text>]</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="date">
        <xsl:param name="node" />
        <xsl:variable name="date_count" select="count($node)" />
        <xsl:choose>
            <xsl:when test="$date_count = 1">
                <xsl:text>,"pubDate":</xsl:text>
                <xsl:choose>
                    <xsl:when test='matches(substring($node/text(),1,4),"[12]\d{3}")'>
                        <xsl:value-of select="substring($node/text(),1,4)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(substring($node/text(),1,4),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>,"pubDate":</xsl:text>
                <xsl:choose>
                    <xsl:when test='matches(substring($node[1]/text(),1,4),"[12]\d{3}")'>
                        <xsl:value-of select="substring($node[1]/text(),1,4)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(substring($node[1]/text(),1,4),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="contribution_agents">
        <xsl:param name="node" />
        <xsl:variable name="contributor_count" select="count($node)" />
        <xsl:choose>
            <xsl:when test="$contributor_count = 1">
                <xsl:text>,"contributor":{</xsl:text>
                <xsl:if test="$node/bf:agent/bf:Agent/@rdf:about">
                    <xsl:text>"id":"</xsl:text><xsl:value-of select="$node/bf:agent/bf:Agent/@rdf:about" /><xsl:text>"</xsl:text>
                </xsl:if>
                <xsl:text>,"type":"</xsl:text>
                <xsl:choose>
                    <xsl:when test="$node/bf:agent/bf:Agent/rdf:type/@rdf:resource">
                        <xsl:value-of select="$node/bf:agent/bf:Agent/rdf:type/@rdf:resource" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>http://catalogdata.library.illinois.edu/lod/types/Contributor</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>"</xsl:text>
                <xsl:text>,"name":"</xsl:text><xsl:value-of select="replace(replace($node/bf:agent/bf:Agent/rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                <xsl:text>}</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$contributor_count > 1">
                    <xsl:text>,"contributor":[</xsl:text>
                    <xsl:for-each select="$node">
                        <xsl:if test="position() != 1">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                        <xsl:text>{</xsl:text>
                        <xsl:if test="./bf:agent/bf:Agent/@rdf:about">
                            <xsl:text>"id":"</xsl:text><xsl:value-of select="./bf:agent/bf:Agent/@rdf:about" /><xsl:text>"</xsl:text>
                        </xsl:if>
                        <xsl:text>,"type":"</xsl:text>
                        <xsl:choose>
                            <xsl:when test="./bf:agent/bf:Agent/rdf:type/@rdf:resource">
                                <xsl:value-of select="./bf:agent/bf:Agent/rdf:type/@rdf:resource" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>http://catalogdata.library.illinois.edu/lod/types/Contributor</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>"</xsl:text>
                        <xsl:text>,"name":"</xsl:text><xsl:value-of select="replace(replace(./bf:agent/bf:Agent/rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                        <xsl:text>}</xsl:text>
                    </xsl:for-each>
                    <xsl:text>]</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="publisher">
        <xsl:param name="Instance" />
        <xsl:variable name="publication_agents" select="$Instance/bf:provisionActivity/bf:ProvisionActivity/bf:agent/bf:Agent[rdfs:label/text()]" />
        <xsl:choose>
            <xsl:when test="count($publication_agents) > 1" >
                <xsl:text>,"publisher":[</xsl:text>
                <xsl:for-each select="$publication_agents">
                    <xsl:if test="position() != 1">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                    <xsl:text>{</xsl:text>
                    <xsl:if test="./@rdf:about">
                        <xsl:text>"id":"</xsl:text><xsl:value-of select="./@rdf:about" /><xsl:text>",</xsl:text>
                    </xsl:if>
                    <xsl:text>"type":"http://id.loc.gov/ontologies/bibframe/Organization"</xsl:text>
                    <xsl:text>,"name":"</xsl:text><xsl:value-of select='replace(replace(./rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)' /><xsl:text>"</xsl:text>
                    <xsl:text>}</xsl:text>
                </xsl:for-each>
                <xsl:text>]</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="count($publication_agents) = 1" >
                    <xsl:text>,"publisher":{</xsl:text>
                    <xsl:if test="$publication_agents/@rdf:about">
                        <xsl:text>"id":"</xsl:text><xsl:value-of select="$publication_agents/@rdf:about" /><xsl:text>",</xsl:text>
                    </xsl:if>
                    <xsl:text>"type":"http://id.loc.gov/ontologies/bibframe/Organization"</xsl:text>
                    <xsl:text>,"name":"</xsl:text><xsl:value-of select='replace(replace($publication_agents/rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)' /><xsl:text>"</xsl:text>
                    <xsl:text>}</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="pub_place">
        <xsl:param name="Instance" />
        <xsl:variable name="pub_places" select='$Instance/bf:provisionActivity/bf:ProvisionActivity/bf:place/bf:Place/@rdf:about[matches(substring(.,40),"[a-z]{2,3}")]' />
        <xsl:choose>
            <xsl:when test="count($pub_places) > 1" >
                <xsl:text>,"pubPlace":[</xsl:text>
                <xsl:for-each select="$pub_places">
                    <xsl:if test="position() != 1">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                    <xsl:text>{</xsl:text>
                    <xsl:text>"id":"</xsl:text><xsl:value-of select="." /><xsl:text>"</xsl:text>
                    <xsl:text>,"type":"http://id.loc.gov/ontologies/bibframe/Place"</xsl:text>
                    <xsl:call-template name="pub_place_name">
                        <xsl:with-param name="val" select="translate(substring(.,40),'#','')" />
                    </xsl:call-template>
                    <xsl:text>}</xsl:text>
                </xsl:for-each>
                <xsl:text>]</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="count($pub_places) = 1">
                    <xsl:text>,"pubPlace":{</xsl:text>
                    <xsl:text>"id":"</xsl:text><xsl:value-of select="$pub_places" /><xsl:text>"</xsl:text>
                    <xsl:text>,"type":"http://id.loc.gov/ontologies/bibframe/Place"</xsl:text>
                    <xsl:call-template name="pub_place_name">
                        <xsl:with-param name="val" select="translate(substring($pub_places,40),'#','')" />
                    </xsl:call-template>
                    <xsl:text>}</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="languages">
        <xsl:param name="langs" />
        <xsl:variable name="lang_count" select="count($langs)" />
        <xsl:choose>
            <xsl:when test="$lang_count > 1">
                <xsl:variable name="lang_set" select="$langs[generate-id() = generate-id(key('lang_combined',.)[1])]" />
                <xsl:variable name="lang_set_count" select="count($lang_set)" />
                <xsl:choose>
                    <xsl:when test="$lang_set_count > 1">
                        <xsl:text>,"language":[</xsl:text>
                        <xsl:for-each select="$lang_set">
                            <xsl:if test="position() != 1">
                                <xsl:text>,</xsl:text>
                            </xsl:if>
                            <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(substring(.,40),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                        </xsl:for-each>
                        <xsl:text>]</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="$lang_set_count = 1">
                                <xsl:text>,"language":"</xsl:text><xsl:value-of select="replace(replace(substring($lang_set,40),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>,"language":[</xsl:text>
                                <!--Create a set of unique language values present in the language structures, both with and without the identifiedBy structure-->
                                <xsl:for-each select="$langs">
                                    <xsl:if test="position() != 1">
                                        <xsl:text>,</xsl:text>
                                    </xsl:if>
                                    <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(substring(.,40),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                                </xsl:for-each>
                                <xsl:text>]</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$lang_count = 1">
                    <xsl:text>,"language":"</xsl:text><xsl:value-of select="replace(replace(substring($langs,40),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="create_identifiers">
        <xsl:param name="Instance" />
        <xsl:param name="Work" />
        <xsl:variable name="lcc" select="$Work/bf:classification/bf:ClassificationLcc" />
        <xsl:variable name="lccn" select="$Instance/bf:identifiedBy/bf:Lccn/rdf:value" />
        <xsl:variable name="oclc" select="$Instance/bf:identifiedBy/bf:Local[bf:source/bf:Source/rdfs:label = 'OCoLC']" />
        <xsl:variable name="lcc_count" select="count($lcc)" />
        <xsl:variable name="lccn_count" select="count($lccn)" />
        <xsl:variable name="oclc_count" select="count($oclc)" />
        <xsl:variable name="identifier_count" select="$lcc_count + $lccn_count + $oclc_count" />

        <xsl:if test="$lcc_count > 0">
            <xsl:choose>
                <xsl:when test="$lcc_count = 1">
                    <xsl:text>,"lcc":</xsl:text>
                    <xsl:choose>
                        <xsl:when test="count($lcc/bf:classificationPortion) > 1">
                            <xsl:text>"</xsl:text><xsl:value-of select="replace(replace($lcc/bf:classificationPortion[1]/text(),$oneSlash,$twoSlash),$pPat,$pRep)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>"</xsl:text><xsl:value-of select="replace(replace($lcc/bf:classificationPortion/text(),$oneSlash,$twoSlash),$pPat,$pRep)" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:for-each select="$lcc/bf:itemPortion/text()">
                        <xsl:text></xsl:text>
                        <xsl:value-of select="replace(replace(.,$oneSlash,$twoSlash),$pPat,$pRep)" />
                    </xsl:for-each><xsl:text>"</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>,"lcc":[</xsl:text>
                    <xsl:for-each select="$lcc">
                        <xsl:if test="position() != 1">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                        <xsl:choose>
                            <xsl:when test="count(./bf:classificationPortion) > 1">
                                <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(./bf:classificationPortion[1]/text(),$oneSlash,$twoSlash),$pPat,$pRep)" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(./bf:classificationPortion/text(),$oneSlash,$twoSlash),$pPat,$pRep)" />
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:for-each select="./bf:itemPortion/text()">
                            <xsl:text></xsl:text>
                            <xsl:value-of select="replace(replace(.,$oneSlash,$twoSlash),$pPat,$pRep)" />
                        </xsl:for-each>
                        <xsl:text>"</xsl:text>
                    </xsl:for-each>
                    <xsl:text>]</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>

        <xsl:if test="$lccn_count > 0">
            <xsl:choose>
                <xsl:when test="$lccn_count = 1">
                    <xsl:text>,"lccn":</xsl:text>
                    <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(replace($lccn/text(),$oneSlash,$twoSlash),$pPat,$pRep),'^\s+|\s+$','')" /><xsl:text>"</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>,"lccn":[</xsl:text>
                    <xsl:for-each select="$lccn">
                        <xsl:if test="position() != 1">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                        <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(replace(./text(),$oneSlash,$twoSlash),$pPat,$pRep),'^\s+|\s+$','')" /><xsl:text>"</xsl:text>
                    </xsl:for-each>
                    <xsl:text>]</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>

        <xsl:if test="$oclc_count > 0">
            <xsl:choose>
                <xsl:when test="$oclc_count = 1">
                    <xsl:text>,"oclc":</xsl:text>
                    <xsl:text>"</xsl:text><xsl:value-of select="replace(replace($oclc/rdf:value/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>,"oclc":[</xsl:text>
                    <xsl:for-each select="$oclc">
                        <xsl:if test="position() != 1">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                        <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(./rdf:value/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                    </xsl:for-each>
                    <xsl:text>]</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>

        <xsl:if test="$lcc_count > 0">
            <xsl:choose>
                <xsl:when test="count($lcc/bf:classificationPortion) = 1">
                    <xsl:text>,"category":"</xsl:text>
                    <xsl:call-template name="lcc_map">
                        <xsl:with-param name="lcc_value" select="replace(replace($lcc/bf:classificationPortion/text(),$oneSlash,$twoSlash),$pPat,$pRep)" />
                    </xsl:call-template>
                    <xsl:text>"</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>,"category":[</xsl:text>
                    <xsl:for-each select="$lcc/bf:classificationPortion">
                        <xsl:if test="position() != 1">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                        <xsl:text>"</xsl:text>
                        <xsl:call-template name="lcc_map">
                            <xsl:with-param name="lcc_value" select="replace(replace(./text(),$oneSlash,$twoSlash),$pPat,$pRep)" />
                        </xsl:call-template>
                        <xsl:text>"</xsl:text>
                    </xsl:for-each>
                    <xsl:text>]</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <xsl:template name="is_n">
        <xsl:param name="base_path" />
        <xsl:param name="is_n" />
        <xsl:if test="$base_path/rdf:value">
            <xsl:choose>
                <xsl:when test="count($base_path[count(./bf:status) = 0 or ./bf:status/bf:Status/rdf:label/text() != 'invalid' or ./bf:status/bf:Status/rdf:label/text() != 'incorrect']) > 1">
                    <xsl:text>,"</xsl:text><xsl:value-of select="$is_n" /><xsl:text>":[</xsl:text>
                    <xsl:for-each select="$base_path[count(./bf:status) = 0 or ./bf:status/bf:Status/rdf:label/text() != 'invalid' or ./bf:status/bf:Status/rdf:label/text() != 'incorrect']">
                        <xsl:if test="position() != 1">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                        <xsl:text>"</xsl:text><xsl:value-of select="replace(replace(tokenize(./rdf:value/text(),' ')[position() = 1],$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                    </xsl:for-each>
                    <xsl:text>]</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="count($base_path/bf:status) = 0 or $base_path/bf:status/bf:Status/rdf:label/text() != 'invalid' or $base_path/bf:status/bf:Status/rdf:label/text() != 'incorrect'">
                        <xsl:text>,"</xsl:text><xsl:value-of select="$is_n" /><xsl:text>":"</xsl:text><xsl:value-of select="replace(replace(tokenize($base_path/rdf:value/text(),' ')[position() = 1],$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <xsl:template name="subject">
        <xsl:param name="Work" />
        <xsl:variable name="subjects" select="$Work/bf:subject/*[not(bf:Temporal)]"/>
        <xsl:if test="count($subjects) > 0">
            <xsl:text>,"subjects":[</xsl:text>
            <xsl:for-each select="$subjects">
                <xsl:if test="position() != 1">
                    <xsl:text>,</xsl:text>
                </xsl:if>
                <xsl:text>{</xsl:text>
                <xsl:if test="./@rdf:about">
                    <xsl:text>"id":"</xsl:text><xsl:value-of select="./@rdf:about" /><xsl:text>",</xsl:text>
                </xsl:if>
                <xsl:text>"type":"</xsl:text><xsl:value-of select="./rdf:type[1]/@rdf:resource" /><xsl:text>"</xsl:text>
                <xsl:text>,"value":"</xsl:text><xsl:value-of select="replace(replace(./rdfs:label,$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
                <xsl:text>}</xsl:text>
            </xsl:for-each>
            <xsl:text>]</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template name="genre">
        <xsl:param name="Work" />
        <xsl:variable name="genres" select="$Work/bf:genreForm/bf:GenreForm/@rdf:about[substring(.,1,1) != '_' and substring(.,1,4) != 'urn:' and substring(.,1,18) != 'http://catalogdata' and substring(.,1,19) != 'http://experimental' ]" />
        <xsl:choose>
            <xsl:when test="count($genres) > 1">
                <xsl:text>,"genre":[</xsl:text>
                <xsl:for-each select="$genres">
                    <xsl:if test="position() != 1">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                    <xsl:text>"</xsl:text><xsl:value-of select="." /><xsl:text>"</xsl:text>
                </xsl:for-each>
                <xsl:text>]</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="count($genres) = 1">
                    <xsl:text>,"genre":"</xsl:text><xsl:value-of select="$genres" /><xsl:text>"</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="part_of">
        <xsl:param name="Instance" />
        <xsl:param name="Work" />
        <xsl:if test="substring($Instance/bf:issuance/bf:Issuance/@rdf:about,39) = 'serl'">
            <xsl:text>,"isPartOf":{</xsl:text>
            <xsl:text>"id":"</xsl:text><xsl:value-of select="$Instance/@rdf:about" /><xsl:text>"</xsl:text>
            <xsl:text>,"type":"CreativeWorkSeries"</xsl:text>
            <xsl:text>,"journalTitle":"</xsl:text><xsl:value-of select="replace(replace($Work/bf:title[1]/bf:Title/rdfs:label/text(),$oneSlash,$twoSlash),$pPat,$pRep)" /><xsl:text>"</xsl:text>
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template name="lcc_map">
        <xsl:param name="lcc_value" />
        <xsl:choose>
            <xsl:when test="substring($lcc_value,1,1) = 'A'">
                <xsl:call-template name="lcc_map_a">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'B'">
                <xsl:call-template name="lcc_map_b">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'C'">
                <xsl:call-template name="lcc_map_c">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'D'">
                <xsl:call-template name="lcc_map_d">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'E'">
                <xsl:call-template name="lcc_map_e">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'F'">
                <xsl:call-template name="lcc_map_f">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'G'">
                <xsl:call-template name="lcc_map_g">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'H'">
                <xsl:call-template name="lcc_map_h">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'J'">
                <xsl:call-template name="lcc_map_j">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'K'">
                <xsl:call-template name="lcc_map_k">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'L'">
                <xsl:call-template name="lcc_map_l">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'M'">
                <xsl:call-template name="lcc_map_m">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'N'">
                <xsl:call-template name="lcc_map_n">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'P'">
                <xsl:call-template name="lcc_map_p">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'Q'">
                <xsl:call-template name="lcc_map_q">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'R'">
                <xsl:call-template name="lcc_map_r">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'S'">
                <xsl:call-template name="lcc_map_s">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'T'">
                <xsl:call-template name="lcc_map_t">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'U'">
                <xsl:call-template name="lcc_map_u">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'V'">
                <xsl:call-template name="lcc_map_v">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="substring($lcc_value,1,1) = 'Z'">
                <xsl:call-template name="lcc_map_z">
                    <xsl:with-param name="val" select="$lcc_value" />
                </xsl:call-template>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_a">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'AC'"><xsl:text>Collections. Series. Collected works</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'AE'"><xsl:text>Encyclopedias</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'AG'"><xsl:text>Dictionaries and other general reference works</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'AI'"><xsl:text>Indexes</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'AM'"><xsl:text>Museums. Collectors and collecting</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'AN'"><xsl:text>Newspapers</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'AP'"><xsl:text>Periodicals</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'AS'"><xsl:text>Academies and learned societies</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'AY'"><xsl:text>Yearbooks. Almanacs. Directories</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'AZ'"><xsl:text>History of scholarship and learning. The humanities</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>GENERAL WORKS</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_b">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'BC'"><xsl:text>Logic</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BD'"><xsl:text>Speculative philosophy</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BF'"><xsl:text>Psychology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BH'"><xsl:text>Aesthetics</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BJ'"><xsl:text>Ethics</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BL'"><xsl:text>Religions. Mythology. Rationalism</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BM'"><xsl:text>Judaism</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BP'"><xsl:text>Islam. Bahaism. Theosophy, etc.</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BQ'"><xsl:text>Buddhism</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BR'"><xsl:text>Christianity</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BS'"><xsl:text>The Bible</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BT'"><xsl:text>Doctrinal Theology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BV'"><xsl:text>Practical Theology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'BX'"><xsl:text>Christian Denominations</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Philosophy (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_c">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'CB'"><xsl:text>History of Civilization</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'CC'"><xsl:text>Archaeology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'CD'"><xsl:text>Diplomatics. Archives. Seals</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'CE'"><xsl:text>Technical Chronology. Calendar</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'CJ'"><xsl:text>Numismatics</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'CN'"><xsl:text>Inscriptions. Epigraphy</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'CR'"><xsl:text>Heraldry</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'CS'"><xsl:text>Genealogy</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'CT'"><xsl:text>Biography</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Auxiliary Sciences of History (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_d">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,3) = 'DAW'"><xsl:text>Central Europe</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DA'"><xsl:text>Great Britain</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DB'"><xsl:text>Austria - Liechtenstein - Hungary - Czechoslovakia</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DC'"><xsl:text>France - Andorra - Monaco</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DD'"><xsl:text>Germany</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DE'"><xsl:text>Greco-Roman World</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DF'"><xsl:text>Greece</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DG'"><xsl:text>Italy - Malta</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DH'"><xsl:text>Low Countries - Benelux Countries</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,3) = 'DJK'"><xsl:text>Eastern Europe (General)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DJ'"><xsl:text>Netherlands (Holland)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DK'"><xsl:text>Russia. Soviet Union. Former Soviet Republics - Poland</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DL'"><xsl:text>Northern Europe. Scandinavia</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DP'"><xsl:text>Spain - Portugal</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DQ'"><xsl:text>Switzerland</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DR'"><xsl:text>Balkan Peninsula</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DS'"><xsl:text>Asia</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DT'"><xsl:text>Africa</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DU'"><xsl:text>Oceania (South Seas)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'DX'"><xsl:text>Romanies</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>History (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_e">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="number(substring-after($val,'E')) &lt;= 143">America</xsl:when>
            <xsl:when test="number(substring-after($val,'E')) &lt;= 909">United States</xsl:when>
            <xsl:otherwise><xsl:text>HISTORY OF THE AMERICAS</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_f">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="number(substring-after($val,'F')) &lt;= 975">United States local history</xsl:when>
            <xsl:when test="number(substring-after($val,'F')) &lt;= 1145.2">British America (including Canada)</xsl:when>
            <xsl:when test="number(substring-after($val,'F')) = 1170">French America</xsl:when>
            <xsl:when test="number(substring-after($val,'F')) &lt;= 3799">Latin America. Spanish America</xsl:when>
            <xsl:otherwise><xsl:text>HISTORY OF THE AMERICAS</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_g">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'GA'"><xsl:text>Mathematical geography. Cartography</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'GB'"><xsl:text>Physical geography</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'GC'"><xsl:text>Oceanography</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'GE'"><xsl:text>Environmental Sciences</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'GF'"><xsl:text>Human ecology. Anthropogeography</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'GN'"><xsl:text>Anthropology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'GR'"><xsl:text>Folklore</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'GT'"><xsl:text>Manners and customs (General)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'GV'"><xsl:text>Recreation. Leisure</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Geography (General). Atlases. Maps</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_h">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'HA'"><xsl:text>Statistics</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HB'"><xsl:text>Economic theory. Demography</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HC'"><xsl:text>Economic history and conditions</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HD'"><xsl:text>Industries. Land use. Labor</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HE'"><xsl:text>Transportation and communications</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HF'"><xsl:text>Commerce</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HG'"><xsl:text>Finance</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HJ'"><xsl:text>Public finance</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HM'"><xsl:text>Sociology (General)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HN'"><xsl:text>Social history and conditions. Social problems. Social reform</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HQ'"><xsl:text>The family. Marriage. Women</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HS'"><xsl:text>Societies:secret, benevolent, etc.</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HT'"><xsl:text>Communities. Classes. Races</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HV'"><xsl:text>Social pathology. Social and public welfare. Criminology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'HX'"><xsl:text>Socialism. Communism. Anarchism</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Social sciences (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_j">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'JA'"><xsl:text>Political science (General)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JC'"><xsl:text>Political theory</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JF'"><xsl:text>Political institutions and public administration</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JJ'"><xsl:text>Political institutions and public administration (North America)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JK'"><xsl:text>Political institutions and public administration (United States)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JL'"><xsl:text>Political institutions and public administration (Canada, Latin America, etc.)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JN'"><xsl:text>Political institutions and public administration (Europe)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JQ'"><xsl:text>Political institutions and public administration (Asia, Africa, Australia, Pacific Area, etc.)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JS'"><xsl:text>Local government. Municipal government</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JV'"><xsl:text>Colonies and colonization. Emigration and immigration. International migration</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JX'"><xsl:text>International law, see JZ and KZ</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'JZ'"><xsl:text>International relations</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>General legislative and executive papers</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_k">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,3) = 'KBM'"><xsl:text>Jewish law</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,3) = 'KBP'"><xsl:text>Islamic law</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,3) = 'KBR'"><xsl:text>History of canon law</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,3) = 'KBU'"><xsl:text>Law of the Roman Catholic Church. The Holy See</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KB'"><xsl:text>Religious law in general. Comparative religious law. Jurisprudence</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,3) = 'KDZ'"><xsl:text>America. North America</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KD'"><xsl:text>United Kingdom and Ireland</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KE'"><xsl:text>Canada</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KF'"><xsl:text>United States</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KG'"><xsl:text>Latin America - Mexico and Central America - West Indies. Caribbean area</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KH'"><xsl:text>South America</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KJ'"><xsl:text>Europe</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KK'"><xsl:text>Europe</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KL'"><xsl:text>Asia and Eurasia, Africa, Pacific Area, and Antarctica</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KM'"><xsl:text>Asia</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KN'"><xsl:text>South Asia. Southeast Asia. East Asia</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KP'"><xsl:text>South Asia. Southeast Asia. East Asia</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KQ'"><xsl:text>Africa</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KR'"><xsl:text>Africa</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KS'"><xsl:text>Africa</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KT'"><xsl:text>Africa</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KU'"><xsl:text>Pacific Area</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KV'"><xsl:text>Pacific area jurisdictions</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KW'"><xsl:text>Pacific area jurisdictions</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'KZ'"><xsl:text>Law of nations</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Law in general. Comparative and uniform law. Jurisprudence</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_l">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'LA'"><xsl:text>History of education</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'LB'"><xsl:text>Theory and practice of education</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'LC'"><xsl:text>Special aspects of education</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'LD'"><xsl:text>Individual institutions - United States</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'LE'"><xsl:text>Individual institutions - America (except United States)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'LF'"><xsl:text>Individual institutions - Europe</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'LG'"><xsl:text>Individual institutions - Asia, Africa, Indian Ocean islands, Australia, New Zealand, Pacific islands</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'LH'"><xsl:text>College and school magazines and papers</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'LJ'"><xsl:text>Student fraternities and societies, United States</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'LT'"><xsl:text>Textbooks</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Education (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_m">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'ML'"><xsl:text>Literature on music</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'MT'"><xsl:text>Instruction and study</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Music</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_n">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'NA'"><xsl:text>Architecture</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'NB'"><xsl:text>Sculpture</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'NC'"><xsl:text>Drawing. Design. Illustration</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'ND'"><xsl:text>Painting</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'NE'"><xsl:text>Print media</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'NK'"><xsl:text>Decorative arts</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'NX'"><xsl:text>Arts in general</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Visual arts</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_p">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'PA'"><xsl:text>Greek language and literature. Latin language and literature</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PB'"><xsl:text>Modern languages. Celtic languages</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PC'"><xsl:text>Romance languages</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PD'"><xsl:text>Germanic languages. Scandinavian languages</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PE'"><xsl:text>English language</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PF'"><xsl:text>West Germanic languages</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PG'"><xsl:text>Slavic languages. Baltic languages. Albanian language</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PH'"><xsl:text>Uralic languages. Basque language</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PJ'"><xsl:text>Oriental languages and literatures</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PK'"><xsl:text>Indo-Iranian languages and literatures</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PL'"><xsl:text>Languages and literatures of Eastern Asia, Africa, Oceania</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PM'"><xsl:text>Hyperborean, Indian, and artificial languages</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PN'"><xsl:text>Literature (General)</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PQ'"><xsl:text>French literature - Italian literature - Spanish literature - Portuguese literature</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PR'"><xsl:text>English literature</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PS'"><xsl:text>American literature</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PT'"><xsl:text>German literature - Dutch literature - Flemish literature since 1830 - Afrikaans literature - Scandinavian literature - Old Norse literature:Old Icelandic and Old Norwegian - Modern Icelandic literature - Faroese literature - Danish literature - Norwegian literature - Swedish literature</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'PZ'"><xsl:text>Fiction and juvenile belles lettres</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Philology. Linguistics</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_q">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'QA'"><xsl:text>Mathematics</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QB'"><xsl:text>Astronomy</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QC'"><xsl:text>Physics</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QD'"><xsl:text>Chemistry</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QE'"><xsl:text>Geology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QH'"><xsl:text>Natural history - Biology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QK'"><xsl:text>Botany</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QL'"><xsl:text>Zoology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QM'"><xsl:text>Human anatomy</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QP'"><xsl:text>Physiology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'QR'"><xsl:text>Microbiology</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Science (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_r">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'RA'"><xsl:text>Public aspects of medicine</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RB'"><xsl:text>Pathology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RC'"><xsl:text>Internal medicine</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RD'"><xsl:text>Surgery</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RE'"><xsl:text>Ophthalmology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RF'"><xsl:text>Otorhinolaryngology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RG'"><xsl:text>Gynecology and obstetrics</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RJ'"><xsl:text>Pediatrics</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RK'"><xsl:text>Dentistry</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RL'"><xsl:text>Dermatology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RM'"><xsl:text>Therapeutics. Pharmacology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RS'"><xsl:text>Pharmacy and materia medica</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RT'"><xsl:text>Nursing</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RV'"><xsl:text>Botanic, Thomsonian, and eclectic medicine</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RX'"><xsl:text>Homeopathy</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'RZ'"><xsl:text>Other systems of medicine</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Medicine (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_s">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'SB'"><xsl:text>Plant culture</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'SD'"><xsl:text>Forestry</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'SF'"><xsl:text>Animal culture</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'SH'"><xsl:text>Aquaculture. Fisheries. Angling</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'SK'"><xsl:text>Hunting sports</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Agriculture (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_t">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'TA'"><xsl:text>Engineering (General). Civil engineering</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TC'"><xsl:text>Hydraulic engineering. Ocean engineering</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TD'"><xsl:text>Environmental technology. Sanitary engineering</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TE'"><xsl:text>Highway engineering. Roads and pavements</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TF'"><xsl:text>Railroad engineering and operation</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TG'"><xsl:text>Bridge engineering</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TH'"><xsl:text>Building construction</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TJ'"><xsl:text>Mechanical engineering and machinery</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TK'"><xsl:text>Electrical engineering. Electronics. Nuclear engineering</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TL'"><xsl:text>Motor vehicles. Aeronautics. Astronautics</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TN'"><xsl:text>Mining engineering. Metallurgy</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TP'"><xsl:text>Chemical technology</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TR'"><xsl:text>Photography</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TS'"><xsl:text>Manufactures</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TT'"><xsl:text>Handicrafts. Arts and crafts</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'TX'"><xsl:text>Home economics</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Technology (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_u">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'UA'"><xsl:text>Armies:Organization, distribution, military situation</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'UB'"><xsl:text>Military administration</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'UC'"><xsl:text>Maintenance and transportation</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'UD'"><xsl:text>Infantry</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'UE'"><xsl:text>Cavalry. Armor</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'UF'"><xsl:text>Artillery</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'UG'"><xsl:text>Military engineering. Air forces</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'UH'"><xsl:text>Other services</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Military science (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_v">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'VA'"><xsl:text>Navies:Organization, distribution, naval situation</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'VB'"><xsl:text>Naval administration</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'VC'"><xsl:text>Naval maintenance</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'VD'"><xsl:text>Naval seamen</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'VE'"><xsl:text>Marines</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'VF'"><xsl:text>Naval ordnance</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'VG'"><xsl:text>Minor services of navies</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'VK'"><xsl:text>Navigation. Merchant marine</xsl:text></xsl:when>
            <xsl:when test="substring($val,1,2) = 'VM'"><xsl:text>Naval architecture. Shipbuilding. Marine engineering</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Naval science (General)</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lcc_map_z">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="substring($val,1,2) = 'ZA'"><xsl:text>Information resources (General)</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Books (General). Writing. Paleography. Book industries and trade. Libraries. Bibliography</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="pub_place_name">
        <xsl:param name="val" />
        <xsl:choose>
            <xsl:when test="$val = 'aa'"><xsl:text>,"name": "Albania"</xsl:text></xsl:when>
            <xsl:when test="$val = 'abc'"><xsl:text>,"name": "Alberta"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ac'"><xsl:text>,"name": "Ashmore and Cartier Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'aca'"><xsl:text>,"name": "Australian Capital Territory"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ae'"><xsl:text>,"name": "Algeria"</xsl:text></xsl:when>
            <xsl:when test="$val = 'af'"><xsl:text>,"name": "Afghanistan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ag'"><xsl:text>,"name": "Argentina"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ai'"><xsl:text>,"name": "Armenia (Republic)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'air'"><xsl:text>,"name": "Armenian S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'aj'"><xsl:text>,"name": "Azerbaijan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ajr'"><xsl:text>,"name": "Azerbaijan S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'aku'"><xsl:text>,"name": "Alaska"</xsl:text></xsl:when>
            <xsl:when test="$val = 'alu'"><xsl:text>,"name": "Alabama"</xsl:text></xsl:when>
            <xsl:when test="$val = 'am'"><xsl:text>,"name": "Anguilla"</xsl:text></xsl:when>
            <xsl:when test="$val = 'an'"><xsl:text>,"name": "Andorra"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ao'"><xsl:text>,"name": "Angola"</xsl:text></xsl:when>
            <xsl:when test="$val = 'aq'"><xsl:text>,"name": "Antigua and Barbuda"</xsl:text></xsl:when>
            <xsl:when test="$val = 'aru'"><xsl:text>,"name": "Arkansas"</xsl:text></xsl:when>
            <xsl:when test="$val = 'as'"><xsl:text>,"name": "American Samoa"</xsl:text></xsl:when>
            <xsl:when test="$val = 'at'"><xsl:text>,"name": "Australia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'au'"><xsl:text>,"name": "Austria"</xsl:text></xsl:when>
            <xsl:when test="$val = 'aw'"><xsl:text>,"name": "Aruba"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ay'"><xsl:text>,"name": "Antarctica"</xsl:text></xsl:when>
            <xsl:when test="$val = 'azu'"><xsl:text>,"name": "Arizona"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ba'"><xsl:text>,"name": "Bahrain"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bb'"><xsl:text>,"name": "Barbados"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bcc'"><xsl:text>,"name": "British Columbia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bd'"><xsl:text>,"name": "Burundi"</xsl:text></xsl:when>
            <xsl:when test="$val = 'be'"><xsl:text>,"name": "Belgium"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bf'"><xsl:text>,"name": "Bahamas"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bg'"><xsl:text>,"name": "Bangladesh"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bh'"><xsl:text>,"name": "Belize"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bi'"><xsl:text>,"name": "British Indian Ocean Territory"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bl'"><xsl:text>,"name": "Brazil"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bm'"><xsl:text>,"name": "Bermuda Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bn'"><xsl:text>,"name": "Bosnia and Herzegovina"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bo'"><xsl:text>,"name": "Bolivia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bp'"><xsl:text>,"name": "Solomon Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'br'"><xsl:text>,"name": "Burma"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bs'"><xsl:text>,"name": "Botswana"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bt'"><xsl:text>,"name": "Bhutan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bu'"><xsl:text>,"name": "Bulgaria"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bv'"><xsl:text>,"name": "Bouvet Island"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bw'"><xsl:text>,"name": "Belarus"</xsl:text></xsl:when>
            <xsl:when test="$val = 'bwr'"><xsl:text>,"name": "Byelorussian S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'bx'"><xsl:text>,"name": "Brunei"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ca'"><xsl:text>,"name": "Caribbean Netherlands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cau'"><xsl:text>,"name": "California"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cb'"><xsl:text>,"name": "Cambodia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cc'"><xsl:text>,"name": "China"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cd'"><xsl:text>,"name": "Chad"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ce'"><xsl:text>,"name": "Sri Lanka"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cf'"><xsl:text>,"name": "Congo (Brazzaville)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cg'"><xsl:text>,"name": "Congo (Democratic Republic)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ch'"><xsl:text>,"name": "China (Republic : 1949 )"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ci'"><xsl:text>,"name": "Croatia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cj'"><xsl:text>,"name": "Cayman Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ck'"><xsl:text>,"name": "Colombia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cl'"><xsl:text>,"name": "Chile"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cm'"><xsl:text>,"name": "Cameroon"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cn'"><xsl:text>,"name": "Canada"</xsl:text></xsl:when>
            <xsl:when test="$val = 'co'"><xsl:text>,"name": "Curaçao"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cou'"><xsl:text>,"name": "Colorado"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cp'"><xsl:text>,"name": "Canton and Enderbury Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cq'"><xsl:text>,"name": "Comoros"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cr'"><xsl:text>,"name": "Costa Rica"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cs'"><xsl:text>,"name": "Czechoslovakia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ctu'"><xsl:text>,"name": "Connecticut"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cu'"><xsl:text>,"name": "Cuba"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cv'"><xsl:text>,"name": "Cabo Verde"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cw'"><xsl:text>,"name": "Cook Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cx'"><xsl:text>,"name": "Central African Republic"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cy'"><xsl:text>,"name": "Cyprus"</xsl:text></xsl:when>
            <xsl:when test="$val = 'cz'"><xsl:text>,"name": "Canal Zone"</xsl:text></xsl:when>
            <xsl:when test="$val = 'dcu'"><xsl:text>,"name": "District of Columbia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'deu'"><xsl:text>,"name": "Delaware"</xsl:text></xsl:when>
            <xsl:when test="$val = 'dk'"><xsl:text>,"name": "Denmark"</xsl:text></xsl:when>
            <xsl:when test="$val = 'dm'"><xsl:text>,"name": "Benin"</xsl:text></xsl:when>
            <xsl:when test="$val = 'dq'"><xsl:text>,"name": "Dominica"</xsl:text></xsl:when>
            <xsl:when test="$val = 'dr'"><xsl:text>,"name": "Dominican Republic"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ea'"><xsl:text>,"name": "Eritrea"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ec'"><xsl:text>,"name": "Ecuador"</xsl:text></xsl:when>
            <xsl:when test="$val = 'eg'"><xsl:text>,"name": "Equatorial Guinea"</xsl:text></xsl:when>
            <xsl:when test="$val = 'em'"><xsl:text>,"name": "TimorLeste"</xsl:text></xsl:when>
            <xsl:when test="$val = 'enk'"><xsl:text>,"name": "England"</xsl:text></xsl:when>
            <xsl:when test="$val = 'er'"><xsl:text>,"name": "Estonia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'err'"><xsl:text>,"name": "Estonia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'es'"><xsl:text>,"name": "El Salvador"</xsl:text></xsl:when>
            <xsl:when test="$val = 'et'"><xsl:text>,"name": "Ethiopia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'fa'"><xsl:text>,"name": "Faroe Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'fg'"><xsl:text>,"name": "French Guiana"</xsl:text></xsl:when>
            <xsl:when test="$val = 'fi'"><xsl:text>,"name": "Finland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'fj'"><xsl:text>,"name": "Fiji"</xsl:text></xsl:when>
            <xsl:when test="$val = 'fk'"><xsl:text>,"name": "Falkland Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'flu'"><xsl:text>,"name": "Florida"</xsl:text></xsl:when>
            <xsl:when test="$val = 'fm'"><xsl:text>,"name": "Micronesia (Federated States)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'fp'"><xsl:text>,"name": "French Polynesia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'fr'"><xsl:text>,"name": "France"</xsl:text></xsl:when>
            <xsl:when test="$val = 'fs'"><xsl:text>,"name": "Terres australes et antarctiques françaises"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ft'"><xsl:text>,"name": "Djibouti"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gau'"><xsl:text>,"name": "Georgia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gb'"><xsl:text>,"name": "Kiribati"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gd'"><xsl:text>,"name": "Grenada"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ge'"><xsl:text>,"name": "Germany (East)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gg'"><xsl:text>,"name": "Guernsey"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gh'"><xsl:text>,"name": "Ghana"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gi'"><xsl:text>,"name": "Gibraltar"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gl'"><xsl:text>,"name": "Greenland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gm'"><xsl:text>,"name": "Gambia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gn'"><xsl:text>,"name": "Gilbert and Ellice Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'go'"><xsl:text>,"name": "Gabon"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gp'"><xsl:text>,"name": "Guadeloupe"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gr'"><xsl:text>,"name": "Greece"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gs'"><xsl:text>,"name": "Georgia (Republic)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gsr'"><xsl:text>,"name": "Georgian S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'gt'"><xsl:text>,"name": "Guatemala"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gu'"><xsl:text>,"name": "Guam"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gv'"><xsl:text>,"name": "Guinea"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gw'"><xsl:text>,"name": "Germany"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gy'"><xsl:text>,"name": "Guyana"</xsl:text></xsl:when>
            <xsl:when test="$val = 'gz'"><xsl:text>,"name": "Gaza Strip"</xsl:text></xsl:when>
            <xsl:when test="$val = 'hiu'"><xsl:text>,"name": "Hawaii"</xsl:text></xsl:when>
            <xsl:when test="$val = 'hk'"><xsl:text>,"name": "Hong Kong"</xsl:text></xsl:when>
            <xsl:when test="$val = 'hm'"><xsl:text>,"name": "Heard and McDonald Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ho'"><xsl:text>,"name": "Honduras"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ht'"><xsl:text>,"name": "Haiti"</xsl:text></xsl:when>
            <xsl:when test="$val = 'hu'"><xsl:text>,"name": "Hungary"</xsl:text></xsl:when>
            <xsl:when test="$val = 'iau'"><xsl:text>,"name": "Iowa"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ic'"><xsl:text>,"name": "Iceland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'idu'"><xsl:text>,"name": "Idaho"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ie'"><xsl:text>,"name": "Ireland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ii'"><xsl:text>,"name": "India"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ilu'"><xsl:text>,"name": "Illinois"</xsl:text></xsl:when>
            <xsl:when test="$val = 'im'"><xsl:text>,"name": "Isle of Man"</xsl:text></xsl:when>
            <xsl:when test="$val = 'inu'"><xsl:text>,"name": "Indiana"</xsl:text></xsl:when>
            <xsl:when test="$val = 'io'"><xsl:text>,"name": "Indonesia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'iq'"><xsl:text>,"name": "Iraq"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ir'"><xsl:text>,"name": "Iran"</xsl:text></xsl:when>
            <xsl:when test="$val = 'is'"><xsl:text>,"name": "Israel"</xsl:text></xsl:when>
            <xsl:when test="$val = 'it'"><xsl:text>,"name": "Italy"</xsl:text></xsl:when>
            <xsl:when test="$val = 'iu'"><xsl:text>,"name": "IsraelSyria Demilitarized Zones"</xsl:text></xsl:when>
            <xsl:when test="$val = 'iv'"><xsl:text>,"name": "Côte d'Ivoire"</xsl:text></xsl:when>
            <xsl:when test="$val = 'iw'"><xsl:text>,"name": "IsraelJordan Demilitarized Zones"</xsl:text></xsl:when>
            <xsl:when test="$val = 'iy'"><xsl:text>,"name": "IraqSaudi Arabia Neutral Zone"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ja'"><xsl:text>,"name": "Japan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'je'"><xsl:text>,"name": "Jersey"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ji'"><xsl:text>,"name": "Johnston Atoll"</xsl:text></xsl:when>
            <xsl:when test="$val = 'jm'"><xsl:text>,"name": "Jamaica"</xsl:text></xsl:when>
            <xsl:when test="$val = 'jn'"><xsl:text>,"name": "Jan Mayen"</xsl:text></xsl:when>
            <xsl:when test="$val = 'jo'"><xsl:text>,"name": "Jordan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ke'"><xsl:text>,"name": "Kenya"</xsl:text></xsl:when>
            <xsl:when test="$val = 'kg'"><xsl:text>,"name": "Kyrgyzstan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'kgr'"><xsl:text>,"name": "Kirghiz S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'kn'"><xsl:text>,"name": "Korea (North)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ko'"><xsl:text>,"name": "Korea (South)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ksu'"><xsl:text>,"name": "Kansas"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ku'"><xsl:text>,"name": "Kuwait"</xsl:text></xsl:when>
            <xsl:when test="$val = 'kv'"><xsl:text>,"name": "Kosovo"</xsl:text></xsl:when>
            <xsl:when test="$val = 'kyu'"><xsl:text>,"name": "Kentucky"</xsl:text></xsl:when>
            <xsl:when test="$val = 'kz'"><xsl:text>,"name": "Kazakhstan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'kzr'"><xsl:text>,"name": "Kazakh S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'lau'"><xsl:text>,"name": "Louisiana"</xsl:text></xsl:when>
            <xsl:when test="$val = 'lb'"><xsl:text>,"name": "Liberia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'le'"><xsl:text>,"name": "Lebanon"</xsl:text></xsl:when>
            <xsl:when test="$val = 'lh'"><xsl:text>,"name": "Liechtenstein"</xsl:text></xsl:when>
            <xsl:when test="$val = 'li'"><xsl:text>,"name": "Lithuania"</xsl:text></xsl:when>
            <xsl:when test="$val = 'lir'"><xsl:text>,"name": "Lithuania"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ln'"><xsl:text>,"name": "Central and Southern Line Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'lo'"><xsl:text>,"name": "Lesotho"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ls'"><xsl:text>,"name": "Laos"</xsl:text></xsl:when>
            <xsl:when test="$val = 'lu'"><xsl:text>,"name": "Luxembourg"</xsl:text></xsl:when>
            <xsl:when test="$val = 'lv'"><xsl:text>,"name": "Latvia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'lvr'"><xsl:text>,"name": "Latvia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ly'"><xsl:text>,"name": "Libya"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mau'"><xsl:text>,"name": "Massachusetts"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mbc'"><xsl:text>,"name": "Manitoba"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mc'"><xsl:text>,"name": "Monaco"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mdu'"><xsl:text>,"name": "Maryland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'meu'"><xsl:text>,"name": "Maine"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mf'"><xsl:text>,"name": "Mauritius"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mg'"><xsl:text>,"name": "Madagascar"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mh'"><xsl:text>,"name": "Macao"</xsl:text></xsl:when>
            <xsl:when test="$val = 'miu'"><xsl:text>,"name": "Michigan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mj'"><xsl:text>,"name": "Montserrat"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mk'"><xsl:text>,"name": "Oman"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ml'"><xsl:text>,"name": "Mali"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mm'"><xsl:text>,"name": "Malta"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mnu'"><xsl:text>,"name": "Minnesota"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mo'"><xsl:text>,"name": "Montenegro"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mou'"><xsl:text>,"name": "Missouri"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mp'"><xsl:text>,"name": "Mongolia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mq'"><xsl:text>,"name": "Martinique"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mr'"><xsl:text>,"name": "Morocco"</xsl:text></xsl:when>
            <xsl:when test="$val = 'msu'"><xsl:text>,"name": "Mississippi"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mtu'"><xsl:text>,"name": "Montana"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mu'"><xsl:text>,"name": "Mauritania"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mv'"><xsl:text>,"name": "Moldova"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mvr'"><xsl:text>,"name": "Moldavian S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'mw'"><xsl:text>,"name": "Malawi"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mx'"><xsl:text>,"name": "Mexico"</xsl:text></xsl:when>
            <xsl:when test="$val = 'my'"><xsl:text>,"name": "Malaysia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'mz'"><xsl:text>,"name": "Mozambique"</xsl:text></xsl:when>
            <xsl:when test="$val = 'na'"><xsl:text>,"name": "Netherlands Antilles"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nbu'"><xsl:text>,"name": "Nebraska"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ncu'"><xsl:text>,"name": "North Carolina"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ndu'"><xsl:text>,"name": "North Dakota"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ne'"><xsl:text>,"name": "Netherlands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nfc'"><xsl:text>,"name": "Newfoundland and Labrador"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ng'"><xsl:text>,"name": "Niger"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nhu'"><xsl:text>,"name": "New Hampshire"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nik'"><xsl:text>,"name": "Northern Ireland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nju'"><xsl:text>,"name": "New Jersey"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nkc'"><xsl:text>,"name": "New Brunswick"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nl'"><xsl:text>,"name": "New Caledonia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nm'"><xsl:text>,"name": "Northern Mariana Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nmu'"><xsl:text>,"name": "New Mexico"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nn'"><xsl:text>,"name": "Vanuatu"</xsl:text></xsl:when>
            <xsl:when test="$val = 'no'"><xsl:text>,"name": "Norway"</xsl:text></xsl:when>
            <xsl:when test="$val = 'np'"><xsl:text>,"name": "Nepal"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nq'"><xsl:text>,"name": "Nicaragua"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nr'"><xsl:text>,"name": "Nigeria"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nsc'"><xsl:text>,"name": "Nova Scotia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ntc'"><xsl:text>,"name": "Northwest Territories"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nu'"><xsl:text>,"name": "Nauru"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nuc'"><xsl:text>,"name": "Nunavut"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nvu'"><xsl:text>,"name": "Nevada"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nw'"><xsl:text>,"name": "Northern Mariana Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nx'"><xsl:text>,"name": "Norfolk Island"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nyu'"><xsl:text>,"name": "New York (State)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'nz'"><xsl:text>,"name": "New Zealand"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ohu'"><xsl:text>,"name": "Ohio"</xsl:text></xsl:when>
            <xsl:when test="$val = 'oku'"><xsl:text>,"name": "Oklahoma"</xsl:text></xsl:when>
            <xsl:when test="$val = 'onc'"><xsl:text>,"name": "Ontario"</xsl:text></xsl:when>
            <xsl:when test="$val = 'oru'"><xsl:text>,"name": "Oregon"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ot'"><xsl:text>,"name": "Mayotte"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pau'"><xsl:text>,"name": "Pennsylvania"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pc'"><xsl:text>,"name": "Pitcairn Island"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pe'"><xsl:text>,"name": "Peru"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pf'"><xsl:text>,"name": "Paracel Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pg'"><xsl:text>,"name": "GuineaBissau"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ph'"><xsl:text>,"name": "Philippines"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pic'"><xsl:text>,"name": "Prince Edward Island"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pk'"><xsl:text>,"name": "Pakistan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pl'"><xsl:text>,"name": "Poland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pn'"><xsl:text>,"name": "Panama"</xsl:text></xsl:when>
            <xsl:when test="$val = 'po'"><xsl:text>,"name": "Portugal"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pp'"><xsl:text>,"name": "Papua New Guinea"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pr'"><xsl:text>,"name": "Puerto Rico"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pt'"><xsl:text>,"name": "Portuguese Timor"</xsl:text></xsl:when>
            <xsl:when test="$val = 'pw'"><xsl:text>,"name": "Palau"</xsl:text></xsl:when>
            <xsl:when test="$val = 'py'"><xsl:text>,"name": "Paraguay"</xsl:text></xsl:when>
            <xsl:when test="$val = 'qa'"><xsl:text>,"name": "Qatar"</xsl:text></xsl:when>
            <xsl:when test="$val = 'qea'"><xsl:text>,"name": "Queensland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'quc'"><xsl:text>,"name": "Québec (Province)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'rb'"><xsl:text>,"name": "Serbia"</xsl:text></xsl:when>
            <xsl:when test="$val = 're'"><xsl:text>,"name": "Réunion"</xsl:text></xsl:when>
            <xsl:when test="$val = 'rh'"><xsl:text>,"name": "Zimbabwe"</xsl:text></xsl:when>
            <xsl:when test="$val = 'riu'"><xsl:text>,"name": "Rhode Island"</xsl:text></xsl:when>
            <xsl:when test="$val = 'rm'"><xsl:text>,"name": "Romania"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ru'"><xsl:text>,"name": "Russia (Federation)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'rur'"><xsl:text>,"name": "Russian S.F.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'rw'"><xsl:text>,"name": "Rwanda"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ry'"><xsl:text>,"name": "Ryukyu Islands, Southern"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sa'"><xsl:text>,"name": "South Africa"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sb'"><xsl:text>,"name": "Svalbard"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sc'"><xsl:text>,"name": "SaintBarthélemy"</xsl:text></xsl:when>
            <xsl:when test="$val = 'scu'"><xsl:text>,"name": "South Carolina"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sd'"><xsl:text>,"name": "South Sudan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sdu'"><xsl:text>,"name": "South Dakota"</xsl:text></xsl:when>
            <xsl:when test="$val = 'se'"><xsl:text>,"name": "Seychelles"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sf'"><xsl:text>,"name": "Sao Tome and Principe"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sg'"><xsl:text>,"name": "Senegal"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sh'"><xsl:text>,"name": "Spanish North Africa"</xsl:text></xsl:when>
            <xsl:when test="$val = 'si'"><xsl:text>,"name": "Singapore"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sj'"><xsl:text>,"name": "Sudan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sk'"><xsl:text>,"name": "Sikkim"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sl'"><xsl:text>,"name": "Sierra Leone"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sm'"><xsl:text>,"name": "San Marino"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sn'"><xsl:text>,"name": "Sint Maarten"</xsl:text></xsl:when>
            <xsl:when test="$val = 'snc'"><xsl:text>,"name": "Saskatchewan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'so'"><xsl:text>,"name": "Somalia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sp'"><xsl:text>,"name": "Spain"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sq'"><xsl:text>,"name": "Eswatini"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sr'"><xsl:text>,"name": "Surinam"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ss'"><xsl:text>,"name": "Western Sahara"</xsl:text></xsl:when>
            <xsl:when test="$val = 'st'"><xsl:text>,"name": "SaintMartin"</xsl:text></xsl:when>
            <xsl:when test="$val = 'stk'"><xsl:text>,"name": "Scotland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'su'"><xsl:text>,"name": "Saudi Arabia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sv'"><xsl:text>,"name": "Swan Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sw'"><xsl:text>,"name": "Sweden"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sx'"><xsl:text>,"name": "Namibia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sy'"><xsl:text>,"name": "Syria"</xsl:text></xsl:when>
            <xsl:when test="$val = 'sz'"><xsl:text>,"name": "Switzerland"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ta'"><xsl:text>,"name": "Tajikistan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tar'"><xsl:text>,"name": "Tajik S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'tc'"><xsl:text>,"name": "Turks and Caicos Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tg'"><xsl:text>,"name": "Togo"</xsl:text></xsl:when>
            <xsl:when test="$val = 'th'"><xsl:text>,"name": "Thailand"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ti'"><xsl:text>,"name": "Tunisia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tk'"><xsl:text>,"name": "Turkmenistan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tkr'"><xsl:text>,"name": "Turkmen S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'tl'"><xsl:text>,"name": "Tokelau"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tma'"><xsl:text>,"name": "Tasmania"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tnu'"><xsl:text>,"name": "Tennessee"</xsl:text></xsl:when>
            <xsl:when test="$val = 'to'"><xsl:text>,"name": "Tonga"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tr'"><xsl:text>,"name": "Trinidad and Tobago"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ts'"><xsl:text>,"name": "United Arab Emirates"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tt'"><xsl:text>,"name": "Trust Territory of the Pacific Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tu'"><xsl:text>,"name": "Turkey"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tv'"><xsl:text>,"name": "Tuvalu"</xsl:text></xsl:when>
            <xsl:when test="$val = 'txu'"><xsl:text>,"name": "Texas"</xsl:text></xsl:when>
            <xsl:when test="$val = 'tz'"><xsl:text>,"name": "Tanzania"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ua'"><xsl:text>,"name": "Egypt"</xsl:text></xsl:when>
            <xsl:when test="$val = 'uc'"><xsl:text>,"name": "United States Misc. Caribbean Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ug'"><xsl:text>,"name": "Uganda"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ui'"><xsl:text>,"name": "United Kingdom Misc. Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'uik'"><xsl:text>,"name": "United Kingdom Misc. Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'uk'"><xsl:text>,"name": "United Kingdom"</xsl:text></xsl:when>
            <xsl:when test="$val = 'un'"><xsl:text>,"name": "Ukraine"</xsl:text></xsl:when>
            <xsl:when test="$val = 'unr'"><xsl:text>,"name": "Ukraine"</xsl:text></xsl:when>
            <xsl:when test="$val = 'up'"><xsl:text>,"name": "United States Misc. Pacific Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ur'"><xsl:text>,"name": "Soviet Union"</xsl:text></xsl:when>
            <xsl:when test="$val = 'us'"><xsl:text>,"name": "United States"</xsl:text></xsl:when>
            <xsl:when test="$val = 'utu'"><xsl:text>,"name": "Utah"</xsl:text></xsl:when>
            <xsl:when test="$val = 'uv'"><xsl:text>,"name": "Burkina Faso"</xsl:text></xsl:when>
            <xsl:when test="$val = 'uy'"><xsl:text>,"name": "Uruguay"</xsl:text></xsl:when>
            <xsl:when test="$val = 'uz'"><xsl:text>,"name": "Uzbekistan"</xsl:text></xsl:when>
            <xsl:when test="$val = 'uzr'"><xsl:text>,"name": "Uzbek S.S.R."</xsl:text></xsl:when>
            <xsl:when test="$val = 'vau'"><xsl:text>,"name": "Virginia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'vb'"><xsl:text>,"name": "British Virgin Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'vc'"><xsl:text>,"name": "Vatican City"</xsl:text></xsl:when>
            <xsl:when test="$val = 've'"><xsl:text>,"name": "Venezuela"</xsl:text></xsl:when>
            <xsl:when test="$val = 'vi'"><xsl:text>,"name": "Virgin Islands of the United States"</xsl:text></xsl:when>
            <xsl:when test="$val = 'vm'"><xsl:text>,"name": "Vietnam"</xsl:text></xsl:when>
            <xsl:when test="$val = 'vn'"><xsl:text>,"name": "Vietnam, North"</xsl:text></xsl:when>
            <xsl:when test="$val = 'vp'"><xsl:text>,"name": "Various places"</xsl:text></xsl:when>
            <xsl:when test="$val = 'vra'"><xsl:text>,"name": "Victoria"</xsl:text></xsl:when>
            <xsl:when test="$val = 'vs'"><xsl:text>,"name": "Vietnam, South"</xsl:text></xsl:when>
            <xsl:when test="$val = 'vtu'"><xsl:text>,"name": "Vermont"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wau'"><xsl:text>,"name": "Washington (State)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wb'"><xsl:text>,"name": "West Berlin"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wea'"><xsl:text>,"name": "Western Australia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wf'"><xsl:text>,"name": "Wallis and Futuna"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wiu'"><xsl:text>,"name": "Wisconsin"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wj'"><xsl:text>,"name": "West Bank of the Jordan River"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wk'"><xsl:text>,"name": "Wake Island"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wlk'"><xsl:text>,"name": "Wales"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ws'"><xsl:text>,"name": "Samoa"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wvu'"><xsl:text>,"name": "West Virginia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'wyu'"><xsl:text>,"name": "Wyoming"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xa'"><xsl:text>,"name": "Christmas Island (Indian Ocean)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xb'"><xsl:text>,"name": "Cocos (Keeling) Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xc'"><xsl:text>,"name": "Maldives"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xd'"><xsl:text>,"name": "Saint KittsNevis"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xe'"><xsl:text>,"name": "Marshall Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xf'"><xsl:text>,"name": "Midway Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xga'"><xsl:text>,"name": "Coral Sea Islands Territory"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xh'"><xsl:text>,"name": "Niue"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xi'"><xsl:text>,"name": "Saint KittsNevisAnguilla"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xj'"><xsl:text>,"name": "Saint Helena"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xk'"><xsl:text>,"name": "Saint Lucia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xl'"><xsl:text>,"name": "Saint Pierre and Miquelon"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xm'"><xsl:text>,"name": "Saint Vincent and the Grenadines"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xn'"><xsl:text>,"name": "North Macedonia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xna'"><xsl:text>,"name": "New South Wales"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xo'"><xsl:text>,"name": "Slovakia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xoa'"><xsl:text>,"name": "Northern Territory"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xp'"><xsl:text>,"name": "Spratly Island"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xr'"><xsl:text>,"name": "Czech Republic"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xra'"><xsl:text>,"name": "South Australia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xs'"><xsl:text>,"name": "South Georgia and the South Sandwich Islands"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xv'"><xsl:text>,"name": "Slovenia"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xx'"><xsl:text>,"name": "No place, unknown, or undetermined"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xxc'"><xsl:text>,"name": "Canada"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xxk'"><xsl:text>,"name": "United Kingdom"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xxr'"><xsl:text>,"name": "Soviet Union"</xsl:text></xsl:when>
            <xsl:when test="$val = 'xxu'"><xsl:text>,"name": "United States"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ye'"><xsl:text>,"name": "Yemen"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ykc'"><xsl:text>,"name": "Yukon Territory"</xsl:text></xsl:when>
            <xsl:when test="$val = 'ys'"><xsl:text>,"name": "Yemen (People's Democratic Republic)"</xsl:text></xsl:when>
            <xsl:when test="$val = 'yu'"><xsl:text>,"name": "Serbia and Montenegro"</xsl:text></xsl:when>
            <xsl:when test="$val = 'za'"><xsl:text>,"name": "Zambia"</xsl:text></xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>