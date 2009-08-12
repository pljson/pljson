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
  mylist json_list; --lists are easy to write
  procedure p(v varchar2) as begin dbms_output.put_line(null);dbms_output.put_line(v); end;
begin
  mylist := json_list('["abc", 23, {}, [], true, null]');
  mylist.print;
  if(json_ext.is_varchar2( mylist.get_elem(1) ) ) then p('No need to write SYS.VARCHAR2'); end if;
  if(json_ext.is_number(mylist.get_elem(2))) then p('Hassle free'); end if;
  if(json_ext.is_json(mylist.get_elem(3))) then p('Maybe not'); end if;
  if(json_ext.is_json_list(mylist.get_elem(4))) then p('But anydata should be tested before converted'); end if;
  if(json_ext.is_json_bool(mylist.get_elem(5))) then p('Use the static functions in JSON'); end if;
  if(json_ext.is_json_null(mylist.get_elem(6))) then p('That''s it'); end if;

  p('What about date values - well json doesn''t specify that - so let us put it in a string.');
  declare
    obj json := json();
    testdate date := date '2009-12-24'; --Xmas
  begin
    obj.put('My favorite date', json_ext.to_anydata(testdate));
    obj.print;
    if(json_ext.is_date(obj.get('My favorite date'))) then
      p('We can also test the value');
    end if;
    p('And convert it back');
    dbms_output.put_line(json_ext.to_date2(obj.get('My favorite date')));
  end;

end;
