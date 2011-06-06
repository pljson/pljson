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
  Building JSON_List with the API
*/

set serveroutput on format wrapped;
declare
  obj json_list;
  procedure p(v varchar2) as begin dbms_output.put_line(null);dbms_output.put_line(v); end;
begin
  p('Building the first list');
  obj := json_list(); --an empty structure
  obj.append('a little string');
  obj.append(123456789);
  obj.append(true);
  obj.append(false);
  obj.append(json_value);
  obj.print;
  p('add with position');
  obj.append('Wow thats great!', 5);
  obj.print;
  p('remove with position');
  obj.remove(4);
  obj.print;
  p('remove first');
  obj.remove_first;
  obj.print;
  p('remove last');
  obj.remove_last;
  obj.print;
  p('you can display the size of an list');
  dbms_output.put_line(obj.count);
  p('you can also add json or json_lists as values:');
  obj := json_list(); --fresh list;
  obj.append(json('{"lazy construction": true}').to_json_value);
  obj.append(json_list('[1,2,3,4,5]'));
  obj.print;
  p('however notice that we had to use the "to_json_value" function on the json object');
end;
/