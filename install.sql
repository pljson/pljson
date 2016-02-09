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
@@src/json_value.typ
@@src/json_list.typ
@@src/json.typ
@@src/json_parser.sql
@@src/json_printer.sql
@@src/json_value_body.typ
@@src/json_ext.sql --extra helper functions
@@src/json_body.typ
@@src/json_list_body.typ
--@@src/grantsandsynonyms.sql --grants to core API
@@src/json_ac.sql --Wrapper to enhance autocompletion
@@src/pljson_table_impl.typ
@@src/pljson_table_impl_body.typ

PROMPT ------------------------------------------;
PROMPT -- Adding optional packages for PL/JSON --;
PROMPT ------------------------------------------;
@@src/addons/json_dyn.sql --dynamic sql execute 
@@src/addons/jsonml.sql --jsonml (xml to json)
@@src/addons/json_xml.sql --json to xml copied from http://www.json.org/java/org/json/XML.java
@@src/addons/json_util_pkg.sql --dynamic sql from http://ora-00001.blogspot.com/2010/02/ref-cursor-to-json.html
@@src/addons/json_helper.sql --Set operations on JSON and JSON_LIST
