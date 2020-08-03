set termout off
create or replace type pljson_varray as table of varchar2(32767);
/
create or replace type pljson_narray as table of number;
/

set termout on
create or replace type pljson_list force under pljson_element (

  /*
  Copyright (c) 2010 Jonas Krogsboell

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

  /* variables */
  list_data pljson_element_array,

  /* constructors */
  constructor function pljson_list return self as result,
  constructor function pljson_list(str varchar2) return self as result,
  constructor function pljson_list(str clob) return self as result,
  constructor function pljson_list(str blob, charset varchar2 default 'UTF8') return self as result,
  constructor function pljson_list(str_array pljson_varray) return self as result,
  constructor function pljson_list(num_array pljson_narray) return self as result,
  constructor function pljson_list(elem pljson_element) return self as result,
  constructor function pljson_list(elem_array pljson_element_array) return self as result,
  overriding member function is_array return boolean,
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2,

  /* list management */
  member procedure append(self in out nocopy pljson_list, elem pljson_element, position pls_integer default null),
  member procedure append(self in out nocopy pljson_list, elem varchar2, position pls_integer default null),
  member procedure append(self in out nocopy pljson_list, elem clob, position pls_integer default null),
  member procedure append(self in out nocopy pljson_list, elem number, position pls_integer default null),
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure append(self in out nocopy pljson_list, elem binary_double, position pls_integer default null),
  member procedure append(self in out nocopy pljson_list, elem boolean, position pls_integer default null),
  member procedure append(self in out nocopy pljson_list, elem pljson_list, position pls_integer default null),

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem pljson_element),
  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem varchar2),
  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem clob),
  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem number),
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem binary_double),
  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem boolean),
  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem pljson_list),

  member procedure remove(self in out nocopy pljson_list, position pls_integer),
  member procedure remove_first(self in out nocopy pljson_list),
  member procedure remove_last(self in out nocopy pljson_list),

  overriding member function count return number,
  overriding member function get(position pls_integer) return pljson_element,
  member function get_string(position pls_integer) return varchar2,
  member function get_clob(position pls_integer) return clob,
  member function get_number(position pls_integer) return number,
  member function get_double(position pls_integer) return binary_double,
  member function get_bool(position pls_integer) return boolean,
  member function get_pljson_list(position pls_integer) return pljson_list,
  member function head return pljson_element,
  member function last return pljson_element,
  member function tail return pljson_list,

  /* json path */
  overriding member function path(json_path varchar2, base number default 1) return pljson_element,

  /** Private method for internal processing. */
  overriding member procedure get_internal_path(self in pljson_list, path pljson_path, path_position pls_integer, ret out nocopy pljson_element),

  /* json path_put */
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem pljson_element, base number default 1),
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem varchar2, base number default 1),
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem clob, base number default 1),
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem number, base number default 1),
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem binary_double, base number default 1),
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem boolean, base number default 1),
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem pljson_list, base number default 1),

  /* json path_remove */
  member procedure path_remove(self in out nocopy pljson_list, json_path varchar2, base number default 1),

  /** Private method for internal processing. */
  overriding member function put_internal_path(self in out nocopy pljson_list, path pljson_path, elem pljson_element, path_position pls_integer) return boolean
) not final;
/
show err