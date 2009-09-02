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
CREATE TABLE "JSON_TESTSUITE" (
  "COLLECTION" VARCHAR2(20 BYTE), 
  "PASSED" NUMBER, 
  "FAILED" NUMBER, 
  "TOTAL" NUMBER, 
  "FILENAME" VARCHAR2(20 BYTE)
);  
/
--run each test here
@jsonparsertest.sql
@json_test.sql
@json_list_test.sql
@simple_test.sql
@ext_test.sql
@jsonpath.sql

PROMPT Unit-testing of PLJSON implementation:
select * from json_testsuite;
--select 'All tests', sum(passed), sum(failed), sum(total), ' ' from json_testsuite;
drop table json_testsuite;
/
