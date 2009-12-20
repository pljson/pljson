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
  Using the JSON Path part of the JSON_EXT package
*/

set serveroutput on;
declare
  obj json := json(
'{
  "a" : true,
  "b" : [1,2,"3"],
  "c" : {
    "d" : [["array of array"], null, { "e": 7913 }]
  }
}');
begin
  -- Having understood ex8.sql and ex9.sql, we now what to delete elements with
  -- JSON Path. The JSON Path remove method does only remove an element if it 
  -- exists. Unlike put, it does not build up a structure but uses get to 
  -- investigate if the structure exists. The only time remove should fail, is 
  -- when you ask it to remove the entire structure. 
  -- (Which you could easily do yourself >> obj := json() << )

  dbms_output.put_line('Example 1: remove a');
  json_ext.remove(obj, 'a');
  obj.print;

  dbms_output.put_line('Example 2: remove third element of b');
  json_ext.remove(obj, 'b[3]');
  obj.print;

  dbms_output.put_line('Example 3: remove first element of b');
  json_ext.remove(obj, 'b[1]');
  obj.print;
  
  dbms_output.put_line('Example 4: remove e in d in c');
  json_ext.remove(obj, 'c.d[3].e');
  obj.print;

  dbms_output.put_line('Example 5: remove array of array in d');
  json_ext.remove(obj, 'c.d[1]');
  obj.print;

  dbms_output.put_line('Example 6: remove null element in d');
  json_ext.remove(obj, 'c.d[1]');
  obj.print;

  dbms_output.put_line('Example 7: remove b and c');
  json_ext.remove(obj, 'c');
  json_ext.remove(obj, 'b');
  obj.print;

  -- thats it!
end;
/