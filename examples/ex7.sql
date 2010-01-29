/*
This software has been released under the MIT license:

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
/*
  Using the JSON_EXT package
*/

set serveroutput on format wrapped;
declare
  obj json := json();
  testdate date := date '2009-12-24'; --Xmas
  procedure p(v varchar2) as begin dbms_output.put_line(null);dbms_output.put_line(v); end;
begin
  obj.put('My favorite date', json_ext.to_json_value(testdate));
  obj.print;
  if(json_ext.is_date(obj.get('My favorite date'))) then
    p('We can also test the value');
  end if;
  p('And convert it back');
  dbms_output.put_line(json_ext.to_date2(obj.get('My favorite date')));
end;
/