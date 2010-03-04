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

/* Demonstrates: fast insertion with duplicate check off
                 remove_duplicates
                 index_of
                 get(indx)
*/
set serveroutput on;
declare 
  obj json;
  indx number;
begin
  --fast construction of json
  obj := json();
  obj.check_duplicate(false); --enables fast construction without checks for duplicate keys
  for i in 1 .. 10000 loop
    obj.put('A'||i, true);
  end loop;
  obj.put('A'||5565, 'tada');
  obj.check_duplicate(true);
  obj.remove_duplicates(); --fix the possible duplicates but does not preserve order

  dbms_output.put_line('Total count: '||obj.count);
  indx := obj.index_of('A5565');
  dbms_output.put_line('Index of A5565: '||indx);
  dbms_output.put_line('Entry at '||indx||': '||obj.get(indx).to_char);

end;
/
