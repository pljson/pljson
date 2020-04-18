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

@@src/pljson_element.type.decl.sql
@@src/pljson_list.type.decl.sql
@@src/pljson.type.decl.sql
@@src/pljson_string.type.sql
@@src/pljson_number.type.sql
@@src/pljson_bool.type.sql
@@src/pljson_null.type.sql
@@src/pljson_ext.decl.sql
@@src/pljson_parser.decl.sql
@@src/pljson_parser.impl.sql
@@src/pljson_printer.package.sql
@@src/pljson_ext.impl.sql
@@src/pljson_element.type.impl.sql
@@src/pljson_list.type.impl.sql
@@src/pljson.type.impl.sql

/* @@src/pljson_ac.package.sql --wrapper to enhance autocompletion */

PROMPT ------------------------------------------;
PROMPT -- Adding optional packages for PL/JSON --;
PROMPT ------------------------------------------;
@@src/addons/pljson_dyn.package.sql --dynamic sql execute
@@src/addons/pljson_ml.package.sql  --jsonml (xml to json)
@@src/addons/pljson_xml.package.sql --json to xml copied from http://www.json.org/java/org/json/XML.java
@@src/addons/pljson_util_pkg.package.sql --dynamic sql from http://ora-00001.blogspot.com/2010/02/ref-cursor-to-json.html
@@src/addons/pljson_helper.package.sql   --set operations on JSON and JSON_LIST
@@src/addons/pljson_object_cache.decl.sql    -- object cache
@@src/addons/pljson_object_cache.impl.sql    -- object cache
@@src/addons/pljson_table_impl.type.decl.sql -- dynamic table from json document
@@src/addons/pljson_table_impl.type.impl.sql -- dynamic table from json document

@@testsuite/pljson_ut.package.sql -- pljson unit test mini framework