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
  tempobj json;
  temparray json_list;
begin
  /* What is the PL/JSON definition of JSON Path? */
  -- In languages such as javascript and python, one can interact with a json 
  -- structure in a sensible manner. In PL/JSON every object is converted into
  -- an anydata structure. When the object is converted back, you actually work
  -- on a copy. That makes nested structures quite difficult to work with. The 
  -- aim of JSON Path is to support changes in nested structures.
   
  -- Suppose we want to change e : 7913 to e : 123. Then we might try to do it 
  -- like this:
  tempobj := json(obj.get('c'));
  temparray := json_list(tempobj.get('d'));
  tempobj := json(temparray.last);
  dbms_output.put_line('Got the right inner json?');
  tempobj.print;
  dbms_output.put_line('Yes - now change the value');
  tempobj.put('e',123);
  tempobj.print;
  dbms_output.put_line('Excellent - but wait! Isn''t that reflected in the global object?');
  obj.print;
  dbms_output.put_line('Sadly no - we are working on copies that should be inserted again!');
  
  -- To make it work we should keep the copies and propergate them back into their positions.
  -- We're not gonna do that. Instead let JSON Path deal with it:
  dbms_output.put_line('Can JSON Path in JSON_EXT help us?');
  json_ext.put(obj, 'c.d[3].e', 123);
  obj.print;
  dbms_output.put_line('Great!');
  
  -- Some notes regarding the put methods:
  -- if you provide an invalid path then an error is raised (hopefully)
  -- you can, however, specify a path that doesn't exists but should be created.
  -- arrays are 1-indexed.
  -- spaces are significant outside array notation
  -- when a too large array is specified, the gaps will be filled with json_null's

  dbms_output.put_line('Example 1:');
  obj := json();
  json_ext.put(obj, 'a[2].data.value[1][2].myarray', json_list('[1,2,3]'));
  obj.print;

  -- use put to fill out the "holes"
  dbms_output.put_line('Example 2:');
  json_ext.put(obj, 'a[1]', 'filler1');
  json_ext.put(obj, 'a[2].data.value[1][1]', 'filler2');
  obj.print;
  
  -- replace larger structures:
  dbms_output.put_line('Example 3:');
  json_ext.put(obj, 'a[2].data', 7913);
  obj.print;

  -- the empty string is an error - and it doesn't make sense
end;
/