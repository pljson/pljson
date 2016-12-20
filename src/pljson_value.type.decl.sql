create or replace type pljson_value as object
(
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
   * <p>Underlying type for all of <em>PL/JSON</em>. Each <code>pljson</code>
   * or <code>pljson_list</code> object is composed of
   * <code>pljson_value</code> objects.</p>
   *
   * <p>Generally, you should not need to directly the constructors provided
   * by this portion of the API. The methods on <code>pljson</code> and
   * <code>pljson_list</code> should be used instead.</p>
   *
   * @headcom
   */

  /**
   * <p>Internal property that indicates the JSON type represented:<p>
   * <ol>
   *   <li><code>object</code></li>
   *   <li><code>array</code></li>
   *   <li><code>string</code></li>
   *   <li><code>number</code></li>
   *   <li><code>bool</code></li>
   *   <li><code>null</code></li>
   * </ol>
   */
  typeval number(1), /* 1 = object, 2 = array, 3 = string, 4 = number, 5 = bool, 6 = null */
  /** Private variable for internal processing. */
  str varchar2(32767),
  /** Private variable for internal processing. */
  num number, /* store 1 as true, 0 as false */
  /** Private variable for internal processing. */
  num_double binary_double, -- both num and num_double are set, there is never exception (until Oracle 12c)
  /** Private variable for internal processing. */
  num_repr_number_p varchar2(1),
  /** Private variable for internal processing. */
  num_repr_double_p varchar2(1),
  /** Private variable for internal processing. */
  object_or_array sys.anydata, /* object or array in here */
  /** Private variable for internal processing. */
  extended_str clob,

  /* mapping */
  /** Private variable for internal processing. */
  mapname varchar2(4000),
  /** Private variable for internal processing. */
  mapindx number(32),

  constructor function pljson_value(object_or_array sys.anydata) return self as result,
  constructor function pljson_value(str varchar2, esc boolean default true) return self as result,
  constructor function pljson_value(str clob, esc boolean default true) return self as result,
  constructor function pljson_value(num number) return self as result,
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  constructor function pljson_value(num_double binary_double) return self as result,
  constructor function pljson_value(b boolean) return self as result,
  constructor function pljson_value return self as result,
  static function makenull return pljson_value,

  /**
   * <p>Retrieve the name of the type represented by the <code>pljson_value</code>.</p>
   * <p>Possible return values:</p>
   * <ul>
   *   <li><code>object</code></li>
   *   <li><code>array</code></li>
   *   <li><code>string</code></li>
   *   <li><code>number</code></li>
   *   <li><code>bool</code></li>
   *   <li><code>null</code></li>
   * </ul>
   *
   * @return The name of the type represented.
   */
  member function get_type return varchar2,
  member function get_string(max_byte_size number default null, max_char_size number default null) return varchar2,
  member procedure get_string(self in pljson_value, buf in out nocopy clob),
  member function get_number return number,
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  member function get_double return binary_double,
  member function get_bool return boolean,
  member function get_null return varchar2,

  member function is_object return boolean,
  member function is_array return boolean,
  member function is_string return boolean,
  member function is_number return boolean,
  member function is_bool return boolean,
  member function is_null return boolean,
  
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers, is_number is still true, extra info */
  /* return true if 'number' is representable by number */
  member function is_number_repr_number return boolean,
  /* return true if 'number' is representable by binary_double */
  member function is_number_repr_double return boolean,
  
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  -- set value for number from string representation; to replace to_number in pljson_parser
  -- can automatically decide and use binary_double if needed
  -- less confusing than new constructor with dummy argument for overloading
  -- centralized parse_number to use everywhere else and replace code in pljson_parser
  member procedure parse_number(str varchar2),
  
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  -- centralized toString to use everywhere else and replace code in pljson_printer
  member function number_toString return varchar2,
  
  /* Output methods */
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2,
  member procedure to_clob(self in pljson_value, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true),
  member procedure print(self in pljson_value, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null), --32512 is maximum
  member procedure htp(self in pljson_value, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null),

  member function value_of(self in pljson_value, max_byte_size number default null, max_char_size number default null) return varchar2

) not final;
/

create or replace type pljson_value_array as table of pljson_value;
/
sho err
