PROMPT -- Setting optimize level --

/*
11g
ALTER SESSION SET PLSQL_OPTIMIZE_LEVEL = 3;
ALTER SESSION SET plsql_code_type = 'NATIVE';
*/
ALTER SESSION SET PLSQL_OPTIMIZE_LEVEL = 2;

/*
This software has been released under the MIT license:

  Copyright (c) 2010 Jonas Krogsboell inspired by code from Lewis R Cunningham

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
PROMPT -----------------------------------;
PROMPT -- Compiling objects for PL/JSON --;
PROMPT -----------------------------------;
@@uninstall.sql

@@src/pljson_value.typ
@@src/pljson_list.typ
@@src/pljson.typ
@@src/pljson_parser.sql
@@src/pljson_printer.sql
@@src/pljson_value_body.typ
@@src/pljson_ext.sql --extra helper functions
@@src/pljson_body.typ
@@src/pljson_list_body.typ
--@@src/grantsandsynonyms.sql --grants to core API
@@src/pljson_ac.sql --Wrapper to enhance autocompletion

PROMPT ------------------------------------------;
PROMPT -- Adding optional packages for PL/JSON --;
PROMPT ------------------------------------------;
@@src/addons/pljson_dyn.sql --dynamic sql execute 
@@src/addons/pljson_ml.sql --jsonml (xml to json)
@@src/addons/pljson_xml.sql --json to xml copied from http://www.json.org/java/org/json/XML.java
@@src/addons/pljson_util_pkg.sql --dynamic sql from http://ora-00001.blogspot.com/2010/02/ref-cursor-to-json.html
@@src/addons/pljson_helper.sql --Set operations on JSON and JSON_LIST
@@src/addons/pljson_table_impl.typ -- dynamic table from json document
@@src/addons/pljson_table_impl_body.typ -- dynamic table from json document
-- synonyms for backwards compatibility
create synonym json_parser for pljson_parser;
create synonym json_printer for pljson_printer;
create synonym json_ext for pljson_ext;
create synonym json_dyn for pljson_dyn;
create synonym json_ml for pljson_ml;
create synonym json_xml for pljson_xml;
create synonym json_util_pkg for pljson_util_pkg;
create synonym json_helper for pljson_helper;
create synonym json_ac for pljson_ac;
create synonym json for pljson;
create synonym json_list for pljson_list;
create synonym json_value_array for pljson_value_array;
create synonym json_value for pljson_value;
create synonym json_table for pljson_table;
