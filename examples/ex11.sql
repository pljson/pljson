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
  Using the TO_CLOB method
*/

set serveroutput on;

declare
  obj json;
  my_clob clob := '{
  "a" : true,
  "b" : [1,2,"3"],
  "c" : {
    "d" : [["array of array"], null, { "e": 7913 }]
  }
}';
  
begin
  obj := json(my_clob);
  obj.print;
  dbms_lob.trim(my_clob, 0); --empty the lob
  obj.to_clob(my_clob);
  dbms_output.put_line('----');
  dbms_output.put_line(my_clob);
  --example with temperary clob
  my_clob := empty_clob();
  dbms_lob.createtemporary(my_clob, true);
  obj.to_clob(my_clob, true);
  dbms_output.put_line('----');
  dbms_output.put_line(my_clob);
  dbms_lob.freetemporary(my_clob);
  
  --if you want to update a json-clob in a table, then first open the clob for update:
  --select "JSON-CLOB" into my_clob from my_json_table where j_id = 23 for update
  
  --parse it into a json object:
  --obj := json(my_clob);
  
  --then modify the object:
  --json_ext.put(obj, 'mypath[2]', 123);
  
  --finally, update the clob and commit:
  --dbms_lob.trim(my_clob, 0); --empty the lob
  --obj.to_clob(my_clob);
  --commit;
  
  --That's it!

end;
/
