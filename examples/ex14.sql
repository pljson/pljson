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
/* Base64 binary support */

set serveroutput on;
declare 
  obj json_list;
  binarydata blob := utl_raw.cast_to_raw('ABC');
  getback blob;
begin
  obj := json_ext.base64(binarydata);
  obj.print;
  getback := json_ext.base64(obj);
  dbms_output.put_line(utl_raw.cast_to_varchar2(getback));
end;
/
declare 
  obj json_value;
  binarydata blob := utl_raw.cast_to_raw('ABC');
  getback blob;
begin
  obj := json_ext.encode(binarydata);
  obj.print;
  getback := json_ext.decode(obj);
  dbms_output.put_line(utl_raw.cast_to_varchar2(getback));
end;
/