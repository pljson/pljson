set define off

create or replace package pljson_ml as
  /*
  Copyright (c) 2010 Jonas Krogsboell

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  */
  
  /* This package contains extra methods to lookup types and
     an easy way of adding date values in json - without changing the structure */

  jsonml_stylesheet xmltype := null;
  xmlgen_stylesheet xmltype := null;

  function xml2json(xml in xmltype) return pljson_list;
  function xml2json(xmlstr in varchar2) return pljson_list;
  function xmlgen2json(xml in xmltype) return clob;
  function xmlgen2json(str in clob) return clob;

end pljson_ml;
/
create or replace package body pljson_ml as
  function get_jsonml_stylesheet return xmltype;
  function get_xmlgen_stylesheet return xmltype;

  function xml2json(xml in xmltype) return pljson_list as
    l_json        xmltype;
    l_returnvalue clob;
  begin
    l_json := xml.transform (get_jsonml_stylesheet);
    l_returnvalue := l_json.getclobval();
    l_returnvalue := dbms_xmlgen.convert (l_returnvalue, dbms_xmlgen.entity_decode);
    --dbms_output.put_line(l_returnvalue);
    return pljson_list(l_returnvalue);
  end xml2json;

  function xml2json(xmlstr in varchar2) return pljson_list as
  begin
    return xml2json(xmltype(xmlstr));
  end xml2json;

  function xmlgen2json(xml in xmltype) return clob as
    l_json        xmltype;
  begin
    return dbms_xmlgen.convert(xml.transform(get_xmlgen_stylesheet).getclobval, dbms_xmlgen.entity_decode);
  end xmlgen2json;

  function xmlgen2json(str in clob) return clob as
  begin
    return xmlgen2json(xmltype(str));
  end xmlgen2json;

  function get_jsonml_stylesheet return xmltype as
  begin
    if(jsonml_stylesheet is null) then
    jsonml_stylesheet := xmltype('<?xml version="1.0" encoding="UTF-8"?>
<!--
		JsonML.xslt

		Created: 2006-11-15-0551
		Modified: 2009-02-14-0927

		Released under an open-source license:
		http://jsonml.org/License.htm

		This transformation converts any XML document into JsonML.
		It omits processing-instructions and comment-nodes.

		To enable comment-nodes to be emitted as JavaScript comments,
		uncomment the Comment() template.
-->
<xsl:stylesheet version="1.0"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="text"
				media-type="application/json"
				encoding="UTF-8"
				indent="no"
				omit-xml-declaration="yes" />

	<!-- constants -->
	<xsl:variable name="XHTML"
				  select="''http://www.w3.org/1999/xhtml''" />

	<xsl:variable name="START_ELEM"
				  select="''[''" />

	<xsl:variable name="END_ELEM"
				  select="'']''" />

	<xsl:variable name="VALUE_DELIM"
				  select="'',''" />

	<xsl:variable name="START_ATTRIB"
				  select="''{''" />

	<xsl:variable name="END_ATTRIB"
				  select="''}''" />

	<xsl:variable name="NAME_DELIM"
				  select="'':''" />

	<xsl:variable name="STRING_DELIM"
				  select="''&#x22;''" />

	<xsl:variable name="START_COMMENT"
				  select="''/*''" />

	<xsl:variable name="END_COMMENT"
				  select="''*/''" />

	<!-- root-node -->
	<xsl:template match="/">
		<xsl:apply-templates select="*" />
	</xsl:template>

	<!-- comments -->
	<xsl:template match="comment()">
	<!-- uncomment to support JSON comments -->
	<!--
		<xsl:value-of select="$START_COMMENT" />

		<xsl:value-of select="."
					  disable-output-escaping="yes" />

		<xsl:value-of select="$END_COMMENT" />
	-->
	</xsl:template>

	<!-- elements -->
	<xsl:template match="*">
		<xsl:value-of select="$START_ELEM" />

		<!-- tag-name string -->
		<xsl:value-of select="$STRING_DELIM" />
		<xsl:choose>
			<xsl:when test="namespace-uri()=$XHTML">
				<xsl:value-of select="local-name()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="name()" />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="$STRING_DELIM" />

		<!-- attribute object -->
		<xsl:if test="count(@*)>0">
			<xsl:value-of select="$VALUE_DELIM" />
			<xsl:value-of select="$START_ATTRIB" />
			<xsl:for-each select="@*">
				<xsl:if test="position()>1">
					<xsl:value-of select="$VALUE_DELIM" />
				</xsl:if>
				<xsl:apply-templates select="." />
			</xsl:for-each>
			<xsl:value-of select="$END_ATTRIB" />
		</xsl:if>

		<!-- child elements and text-nodes -->
		<xsl:for-each select="*|text()">
			<xsl:value-of select="$VALUE_DELIM" />
			<xsl:apply-templates select="." />
		</xsl:for-each>

		<xsl:value-of select="$END_ELEM" />
	</xsl:template>

	<!-- text-nodes -->
	<xsl:template match="text()">
		<xsl:call-template name="escape-string">
			<xsl:with-param name="value"
							select="." />
		</xsl:call-template>
	</xsl:template>

	<!-- attributes -->
	<xsl:template match="@*">
		<xsl:value-of select="$STRING_DELIM" />
		<xsl:choose>
			<xsl:when test="namespace-uri()=$XHTML">
				<xsl:value-of select="local-name()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="name()" />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="$STRING_DELIM" />

		<xsl:value-of select="$NAME_DELIM" />

		<xsl:call-template name="escape-string">
			<xsl:with-param name="value"
							select="." />
		</xsl:call-template>

	</xsl:template>

	<!-- escape-string: quotes and escapes -->
	<xsl:template name="escape-string">
		<xsl:param name="value" />

		<xsl:value-of select="$STRING_DELIM" />

		<xsl:if test="string-length($value)>0">
			<xsl:variable name="escaped-whacks">
				<!-- escape backslashes -->
				<xsl:call-template name="string-replace">
					<xsl:with-param name="value"
									select="$value" />
					<xsl:with-param name="find"
									select="''\''" />
					<xsl:with-param name="replace"
									select="''\\''" />
				</xsl:call-template>
			</xsl:variable>

			<xsl:variable name="escaped-LF">
				<!-- escape line feeds -->
				<xsl:call-template name="string-replace">
					<xsl:with-param name="value"
									select="$escaped-whacks" />
					<xsl:with-param name="find"
									select="''&#x0A;''" />
					<xsl:with-param name="replace"
									select="''\n''" />
				</xsl:call-template>
			</xsl:variable>

			<xsl:variable name="escaped-CR">
				<!-- escape carriage returns -->
				<xsl:call-template name="string-replace">
					<xsl:with-param name="value"
									select="$escaped-LF" />
					<xsl:with-param name="find"
									select="''&#x0D;''" />
					<xsl:with-param name="replace"
									select="''\r''" />
				</xsl:call-template>
			</xsl:variable>

			<xsl:variable name="escaped-tabs">
				<!-- escape tabs -->
				<xsl:call-template name="string-replace">
					<xsl:with-param name="value"
									select="$escaped-CR" />
					<xsl:with-param name="find"
									select="''&#x09;''" />
					<xsl:with-param name="replace"
									select="''\t''" />
				</xsl:call-template>
			</xsl:variable>

			<!-- escape quotes -->
			<xsl:call-template name="string-replace">
				<xsl:with-param name="value"
								select="$escaped-tabs" />
				<xsl:with-param name="find"
								select="''&quot;''" />
				<xsl:with-param name="replace"
								select="''\&quot;''" />
			</xsl:call-template>
		</xsl:if>

		<xsl:value-of select="$STRING_DELIM" />
	</xsl:template>

	<!-- string-replace: replaces occurances of one string with another -->
	<xsl:template name="string-replace">
		<xsl:param name="value" />
		<xsl:param name="find" />
		<xsl:param name="replace" />

		<xsl:choose>
			<xsl:when test="contains($value,$find)">
				<!-- replace and call recursively on next -->
				<xsl:value-of select="substring-before($value,$find)"
							  disable-output-escaping="yes" />
				<xsl:value-of select="$replace"
							  disable-output-escaping="yes" />
				<xsl:call-template name="string-replace">
					<xsl:with-param name="value"
									select="substring-after($value,$find)" />
					<xsl:with-param name="find"
									select="$find" />
					<xsl:with-param name="replace"
									select="$replace" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<!-- no replacement necessary -->
				<xsl:value-of select="$value"
							  disable-output-escaping="yes" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>');
    end if;
    return jsonml_stylesheet;
  end get_jsonml_stylesheet;

    --http://stefan-armbruster.com/index.php/12-it/pl-sql/12-oracle-xml-and-json-goodies
    function get_xmlgen_stylesheet return xmltype as
    begin
      if(xmlgen_stylesheet is null) then
      xmlgen_stylesheet := xmltype('<?xml version="1.0" encoding="UTF-8"?>
        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <!--
          Copyright (c) 2006, Doeke Zanstra
          All rights reserved.

          Redistribution and use in source and binary forms, with or without modification,
          are permitted provided that the following conditions are met:

          Redistributions of source code must retain the above copyright notice, this
          list of conditions and the following disclaimer. Redistributions in binary
          form must reproduce the above copyright notice, this list of conditions and the
          following disclaimer in the documentation and/or other materials provided with
          the distribution.

          Neither the name of the dzLib nor the names of its contributors may be used to
          endorse or promote products derived from this software without specific prior
          written permission.

          THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
          ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
          WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
          IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
          INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
          BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
          DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
          LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
          OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
          THE POSSIBILITY OF SUCH DAMAGE.
        -->

          <xsl:output indent="no" omit-xml-declaration="yes" method="text" encoding="UTF-8" media-type="text/x-json"/>
          <xsl:strip-space elements="*"/>
          <!--contant-->
          <xsl:variable name="d">0123456789</xsl:variable>

          <!-- ignore document text -->
          <xsl:template match="text()[preceding-sibling::node() or following-sibling::node()]"/>

          <!-- string -->
          <xsl:template match="text()">
            <xsl:call-template name="escape-string">
              <xsl:with-param name="s" select="."/>
            </xsl:call-template>
          </xsl:template>

          <!-- Main template for escaping strings; used by above template and for object-properties
               Responsibilities: placed quotes around string, and chain up to next filter, escape-bs-string -->
          <xsl:template name="escape-string">
            <xsl:param name="s"/>
            <xsl:text>"</xsl:text>
            <xsl:call-template name="escape-bs-string">
              <xsl:with-param name="s" select="$s"/>
            </xsl:call-template>
            <xsl:text>"</xsl:text>
          </xsl:template>

          <!-- Escape the backslash (\) before everything else. -->
          <xsl:template name="escape-bs-string">
            <xsl:param name="s"/>
            <xsl:choose>
              <xsl:when test="contains($s,''\'')">
                <xsl:call-template name="escape-quot-string">
                  <xsl:with-param name="s" select="concat(substring-before($s,''\''),''\\'')"/>
                </xsl:call-template>
                <xsl:call-template name="escape-bs-string">
                  <xsl:with-param name="s" select="substring-after($s,''\'')"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="escape-quot-string">
                  <xsl:with-param name="s" select="$s"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:template>

          <!-- Escape the double quote ("). -->
          <xsl:template name="escape-quot-string">
            <xsl:param name="s"/>
            <xsl:choose>
              <xsl:when test="contains($s,'';'')">
                <xsl:call-template name="encode-string">
                  <xsl:with-param name="s" select="concat(substring-before($s,'';''),''&quot;'')"/>
                </xsl:call-template>
                <xsl:call-template name="escape-quot-string">
                  <xsl:with-param name="s" select="substring-after($s,'';'')"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="encode-string">
                  <xsl:with-param name="s" select="$s"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:template>

          <!-- Replace tab, line feed and/or carriage return by its matching escape code. Can''t escape backslash
               or double quote here, because they don''t replace characters (; becomes \t), but they prefix
               characters (\ becomes \\). Besides, backslash should be seperate anyway, because it should be
               processed first. This function can''t do that. -->
          <xsl:template name="encode-string">
            <xsl:param name="s"/>
            <xsl:choose>
              <!-- tab -->
              <xsl:when test="contains($s,'';'')">
                <xsl:call-template name="encode-string">
                  <xsl:with-param name="s" select="concat(substring-before($s,'';''),''\t'',substring-after($s,'';''))"/>
                </xsl:call-template>
              </xsl:when>
              <!-- line feed -->
              <xsl:when test="contains($s,'';'')">
                <xsl:call-template name="encode-string">
                  <xsl:with-param name="s" select="concat(substring-before($s,'';''),''\n'',substring-after($s,'';''))"/>
                </xsl:call-template>
              </xsl:when>
              <!-- carriage return -->
              <xsl:when test="contains($s,'';'')">
                <xsl:call-template name="encode-string">
                  <xsl:with-param name="s" select="concat(substring-before($s,'';''),''\r'',substring-after($s,'';''))"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="$s"/></xsl:otherwise>
            </xsl:choose>
          </xsl:template>

          <!-- number (no support for javascript mantise) -->
          <xsl:template match="text()[not(string(number())=''NaN'')]">
            <xsl:value-of select="."/>
          </xsl:template>

          <!-- boolean, case-insensitive -->
          <xsl:template match="text()[translate(.,''TRUE'',''true'')=''true'']">true</xsl:template>
          <xsl:template match="text()[translate(.,''FALSE'',''false'')=''false'']">false</xsl:template>

          <!-- item:null -->
          <xsl:template match="*[count(child::node())=0]">
            <xsl:call-template name="escape-string">
              <xsl:with-param name="s" select="local-name()"/>
            </xsl:call-template>
            <xsl:text>:null</xsl:text>
            <xsl:if test="following-sibling::*">,</xsl:if>
            <xsl:if test="not(following-sibling::*)">}</xsl:if> <!-- MBR 30.01.2010: added this line as it appeared to be missing from stylesheet -->
          </xsl:template>

          <!-- object -->
          <xsl:template match="*" name="base">
            <xsl:if test="not(preceding-sibling::*)">{</xsl:if>
            <xsl:call-template name="escape-string">
              <xsl:with-param name="s" select="name()"/>
            </xsl:call-template>
            <xsl:text>:</xsl:text>
            <xsl:apply-templates select="child::node()"/>
            <xsl:if test="following-sibling::*">,</xsl:if>
            <xsl:if test="not(following-sibling::*)">}</xsl:if>
          </xsl:template>

          <!-- array -->
          <xsl:template match="*[count(../*[name(../*)=name(.)])=count(../*) and count(../*)&gt;1]">
            <xsl:if test="not(preceding-sibling::*)">[</xsl:if>
            <xsl:choose>
              <xsl:when test="not(child::node())">
                <xsl:text>null</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="child::node()"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="following-sibling::*">,</xsl:if>
            <xsl:if test="not(following-sibling::*)">]</xsl:if>
          </xsl:template>

          <!-- convert root element to an anonymous container -->
          <xsl:template match="/">
            <xsl:apply-templates select="node()"/>
          </xsl:template>

        </xsl:stylesheet>');
      end if;
      return xmlgen_stylesheet;
    end get_xmlgen_stylesheet;

end pljson_ml;
/