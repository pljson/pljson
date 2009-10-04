create or replace type json_list as object (
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

  list_data json_element_array,
  constructor function json_list return self as result,
  constructor function json_list(str varchar2) return self as result,
  constructor function json_list(str clob) return self as result,
  member procedure add_elem(elem anydata, position pls_integer default null),
  member procedure add_elem(elem varchar2, position pls_integer default null),
  member procedure add_elem(elem number, position pls_integer default null),
  member procedure add_elem(elem json_bool, position pls_integer default null),
  member procedure add_elem(elem json_null, position pls_integer default null),
  member procedure add_elem(elem json_list, position pls_integer default null),
  member function count return number,
  member procedure remove_elem(position pls_integer),
  member procedure remove_first,
  member procedure remove_last,
  member function get_elem(position pls_integer) return anydata,
  member function get_first return anydata,
  member function get_last return anydata,
  member function to_char(spaces boolean default true) return varchar2,
  member procedure to_clob(buf in out nocopy clob, spaces boolean default false),
  member procedure print(spaces boolean default true)
);
/

sho err

