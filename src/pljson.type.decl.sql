set termout off
create or replace type pljson_varray as table of varchar2(32767);
/

set termout on
create or replace type pljson force under pljson_element (

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
  json_data pljson_element_array,
  check_for_duplicate number,

  /* constructors */
  constructor function pljson return self as result,
  constructor function pljson(str varchar2) return self as result,
  constructor function pljson(str in clob) return self as result,
  constructor function pljson(str in blob, charset varchar2 default 'UTF8') return self as result,
  constructor function pljson(str_array pljson_varray) return self as result,
  constructor function pljson(elem pljson_element) return self as result,
  constructor function pljson(l pljson_list) return self as result,
  overriding member function is_object return boolean,
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2,

  /* member management */
  member procedure remove(pair_name varchar2),

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson_element, position pls_integer default null),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value varchar2, position pls_integer default null),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value clob, position pls_integer default null),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value number, position pls_integer default null),
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value binary_double, position pls_integer default null),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value boolean, position pls_integer default null),

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson, position pls_integer default null),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson_list, position pls_integer default null),

  overriding member function count return number,
  overriding member function get(pair_name varchar2) return pljson_element,

  member function get_string(pair_name varchar2) return varchar2,
  member function get_clob(pair_name varchar2) return clob,
  member function get_number(pair_name varchar2) return number,
  member function get_double(pair_name varchar2) return binary_double,
  member function get_bool(pair_name varchar2) return boolean,
  member function get_pljson(pair_name varchar2) return pljson,
  member function get_pljson_list(pair_name varchar2) return pljson_list,

  overriding member function get(position pls_integer) return pljson_element,
  member function index_of(pair_name varchar2) return number,
  member function exist(pair_name varchar2) return boolean,

  member procedure check_duplicate(self in out nocopy pljson, v_set boolean),
  member procedure remove_duplicates(self in out nocopy pljson),

  /* json path */
  overriding member function path(json_path varchar2, base number default 1) return pljson_element,

  /** Private method for internal processing. */
  overriding member procedure get_internal_path(self in pljson, path pljson_path, path_position pls_integer, ret out nocopy pljson_element),

  /* json path_put */
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson_element, base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem varchar2, base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem clob, base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem number, base number default 1),
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem binary_double, base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem boolean, base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson, base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson_list, base number default 1),

  /* json path_remove */
  member procedure path_remove(self in out nocopy pljson, json_path varchar2, base number default 1),

  /* map functions */
  member function get_keys return pljson_list,
  member function get_values return pljson_list,

  /** Private method for internal processing. */
  overriding member function put_internal_path(self in out nocopy pljson, path pljson_path, elem pljson_element, path_position pls_integer) return boolean
) not final;
/
show err