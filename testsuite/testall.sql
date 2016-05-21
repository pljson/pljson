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

CREATE TABLE pljson_testsuite (
  COLLECTION VARCHAR2(30 BYTE),
  PASSED NUMBER,
  FAILED NUMBER,
  TOTAL NUMBER,
  FILENAME VARCHAR2(30 BYTE)
);

--run each test here
@@pljson_parser_test.sql
@@pljson_test.sql
@@pljson_list_test.sql
@@pljson_simple_test.sql
@@pljson_ext_test.sql
@@pljson_path_test.sql
@@pljson_helper_test.sql
@@pljson_unicode_test.sql

PROMPT Unit-testing of PLJSON implementation:
COLUMN PASSED HEADING 'PASS' FORMAT 999
COLUMN FAILED HEADING 'FAIL' FORMAT 999
COLUMN TOTAL  HEADING 'TOT'  FORMAT 999
select * from pljson_testsuite;
--select 'All tests', sum(passed), sum(failed), sum(total), ' ' from pljson_testsuite;
drop table pljson_testsuite;
