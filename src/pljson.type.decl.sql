create or replace type pljson as object (
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

  /**
   * <p>This package defines <em>PL/JSON</em>'s representation of the JSON
   * object type, e.g.:</p>
   *
   * <pre>
   * {
   *   "foo": "bar",
   *   "baz": 42
   * }
   * </pre>
   *
   * <p>The primary method exported by this package is the <code>pljson</code>
   * method.</p>
   *
   * @headcom
   */

  /* Variables */
  /** Private variable for internal processing. */
  json_data pljson_value_array,
  /** Private variable for internal processing. */
  check_for_duplicate number,

  /* Constructors */

  /**
   * <p>Primary constructor that creates an empty object.</p>
   *
   * <pre>
   *   decleare
   *     myjson pljson := pljson();
   *   begin
   *     myjson.put('foo', 'bar');
   *     dbms_output.put_line(myjson.get('foo')); // "bar"
   *   end;
   * </pre>
   *
   * @return A <code>pljson</code> instance.
   */
  constructor function pljson return self as result,

  /**
   * <p>Construct a <code>pljson</code> instance from a given string of JSON.</p>
   *
   * <pre>
   *   decleare
   *     myjson pljson := pljson('{"foo": "bar"}');
   *   begin
   *     dbms_output.put_line(myjson.get('foo')); // "bar"
   *   end;
   * </pre>
   *
   * @return A <code>pljson</code> instance.
   */
  constructor function pljson(str varchar2) return self as result,
  constructor function pljson(str in clob) return self as result,
  constructor function pljson(cast pljson_value) return self as result,
  constructor function pljson(l in out nocopy pljson_list) return self as result,

  /* Member setter methods */
  member procedure remove(pair_name varchar2),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson_value, position pls_integer default null),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value varchar2, position pls_integer default null),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value number, position pls_integer default null),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value boolean, position pls_integer default null),
  member procedure check_duplicate(self in out nocopy pljson, v_set boolean),
  member procedure remove_duplicates(self in out nocopy pljson),

  /* deprecated putter use pljson_value */
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson, position pls_integer default null),
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson_list, position pls_integer default null),

  /* Member getter methods */
  member function count return number,
  member function get(pair_name varchar2) return pljson_value,
  member function get(position pls_integer) return pljson_value,
  member function index_of(pair_name varchar2) return number,
  member function exist(pair_name varchar2) return boolean,

  /* Output methods */
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2,
  member procedure to_clob(self in pljson, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true),
  member procedure print(self in pljson, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null), --32512 is maximum
  member procedure htp(self in pljson, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null),

  member function to_json_value return pljson_value,
  /* json path */
  member function path(json_path varchar2, base number default 1) return pljson_value,

  /* json path_put */
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson_value, base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem varchar2  , base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem number    , base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem boolean   , base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson_list , base number default 1),
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson      , base number default 1),

  /* json path_remove */
  member procedure path_remove(self in out nocopy pljson, json_path varchar2, base number default 1),

  /* map functions */
  member function get_values return pljson_list,
  member function get_keys return pljson_list

) not final;
/
sho err
