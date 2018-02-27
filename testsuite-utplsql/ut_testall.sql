/*
  Copyright (c) 2009 Jonas Krogsboell
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

PROMPT run with NLS_LANG='AMERICAN_AMERICA.AL32UTF8'

set trimspool on
set echo off
set feedback off
set verify off
set linesize 32767
set pagesize 0
set long 200000000
set longchunksize 1000000
set serveroutput on size unlimited format truncated

clear screen

PROMPT Installing tests
@@ut_pljson_parser_test.sql
@@ut_pljson_test.sql
@@ut_pljson_list_test.sql
@@ut_pljson_simple_test.sql
@@ut_pljson_ext_test.sql
@@ut_pljson_path_test.sql
@@ut_pljson_helper_test.sql
@@ut_pljson_unicode_test.sql

PROMPT Executing tests
REM exec ut.run(ut_coverage_html_reporter());
exec ut.run(USER);

drop package ut_pljson_parser_test;
drop package ut_pljson_test;
drop package ut_pljson_list_test;
drop package ut_pljson_simple_test;
drop package ut_pljson_ext_test;
drop package ut_pljson_path_test;
drop package ut_pljson_helper_test;
drop package ut_pljson_unicode_test;
