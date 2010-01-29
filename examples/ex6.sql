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
  Variables are copied on insertion
*/

set serveroutput on format wrapped;
declare
  obj json;
  obj2 json;
  str varchar2(20);
  pair_value json_value;
  procedure p(v varchar2) as begin dbms_output.put_line(null);dbms_output.put_line(v); end;
begin
  p('Variables are copies');
  obj := json(); --an empty structure
  str := 'ABC';
  obj.put('N1', str);
  str := 'DEF';
  obj.print;
  obj.put('N2', str);
  obj.print;
  
  p('Even nested json are copies');
  obj2 := json('{"a":true}');
  obj.put('N1', obj2);
  obj2.remove('a');
  obj.put('N2', obj2);
  obj.print;
  
  p('Extract data from json');
  pair_value := obj.get('N1');
  --what to do with json_value? get the content into the right type!
  obj2 := json(pair_value); --json construtor with json_value only works if json_value contains a json
  obj2.print;
  --JSON_LIST works in the same manner.
end;
/