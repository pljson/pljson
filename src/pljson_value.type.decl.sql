create or replace type pljson_value force as object (

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
   * <p>Generally, you should not need to directly use the constructors provided
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
  object_or_array pljson_element, /* object or array in here */
  /** Private variable for internal processing. */
  extended_str clob,

  /* mapping */
  /** Private variable for internal processing. */
  mapname varchar2(4000),
  /** Private variable for internal processing. */
  mapindx number(32),

  constructor function pljson_value(elem pljson_element) return self as result,
  constructor function pljson_value(str varchar2, esc boolean default true) return self as result,
  constructor function pljson_value(str clob, esc boolean default true) return self as result,
  constructor function pljson_value(num number) return self as result,
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  constructor function pljson_value(num_double binary_double) return self as result,
  constructor function pljson_value(b boolean) return self as result,
  constructor function pljson_value return self as result,

  member function get_element return pljson_element,

  /**
   * <p>Create an empty <code>pljson_value</code>.</p>
   *
   * <pre>
   * declare
   *   myval pljson_value := pljson_value.makenull();
   * begin
   *   myval.parse_number('42');
   *   myval.print(); // => dbms_output.put_line('42');
   * end;
   * </pre>
   *
   * @return An instance of <code>pljson_value</code>.
   */
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

  /**
   * <p>Retrieve the value as a string (<code>varchar2</code>).</p>
   *
   * @param max_byte_size Retrieve the value up to a specific number of bytes, max = bytes for 5000 characters. Default: <code>null</code>.
   * @param max_char_size Retrieve the value up to a specific number of characters, max = 5000. Default: <code>null</code>.
   * @return An instance of <code>varchar2</code> or <code>null</code> if the value is not a string.
   */
  member function get_string(max_byte_size number default null, max_char_size number default null) return varchar2,

  /**
   * <p>Retrieve the value as a string represented by a <code>CLOB</code>.</p>
   *
   * @param buf The <code>CLOB</code> in which to store the string.
   */
  member procedure get_string(self in pljson_value, buf in out nocopy clob),

  /**
   * <p>Retrieve the value as a string of clob type (<code>clob</code>).</p>
   *
   * @return the internal <code>clob</code> or <code>null</code> if the value is not a string.
   */
  member function get_clob return clob,

  /**
   * <p>Retrieve the value as a <code>number</code>.</p>
   *
   * @return An instance of <code>number</code> or <code>null</code> if the value is not a number.
   */
  member function get_number return number,

  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  /**
   * <p>Retrieve the value as a <code>binary_double</code>.</p>
   *
   * @return An instance of <code>binary_double</code> or <code>null</code> if the value is not a number.
   */
  member function get_double return binary_double,

  /**
   * <p>Retrieve the value as a <code>boolean</code>.</p>
   *
   * @return An instance of <code>boolean</code> or <code>null</code> if the value is not a boolean.
   */
  member function get_bool return boolean,

  /**
   * <p>Retrieve the value as a string <code>'null'<code>.</p>
   *
   * @return A <code>varchar2</code> with the value <code>'null'</code> or
   * an actual <code>null</code> if the value isn't a JSON "null".
   */
  member function get_null return varchar2,

  /**
   * <p>Determine if the value represents an "object" type.</p>
   *
   * @return <code>true</code> if the value is an object, <code>false</code> otherwise.
   */
  member function is_object return boolean,

  /**
   * <p>Determine if the value represents an "array" type.</p>
   *
   * @return <code>true</code> if the value is an array, <code>false</code> otherwise.
   */
  member function is_array return boolean,

  /**
   * <p>Determine if the value represents a "string" type.</p>
   *
   * @return <code>true</code> if the value is a string, <code>false</code> otherwise.
   */
  member function is_string return boolean,

  /**
   * <p>Determine if the value represents a "number" type.</p>
   *
   * @return <code>true</code> if the value is a number, <code>false</code> otherwise.
   */
  member function is_number return boolean,

  /**
   * <p>Determine if the value represents a "boolean" type.</p>
   *
   * @return <code>true</code> if the value is a boolean, <code>false</code> otherwise.
   */
  member function is_bool return boolean,

  /**
   * <p>Determine if the value represents a "null" type.</p>
   *
   * @return <code>true</code> if the value is a null, <code>false</code> otherwise.
   */
  member function is_null return boolean,

  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers, is_number is still true, extra info */
  /* return true if 'number' is representable by Oracle number */
  /** Private method for internal processing. */
  member function is_number_repr_number return boolean,
  /* return true if 'number' is representable by Oracle binary_double */
  /** Private method for internal processing. */
  member function is_number_repr_double return boolean,

  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  -- set value for number from string representation; to replace to_number in pljson_parser
  -- can automatically decide and use binary_double if needed
  -- less confusing than new constructor with dummy argument for overloading
  -- centralized parse_number to use everywhere else and replace code in pljson_parser
  /**
   * <p>Parses a string into a number. This method will automatically cast to
   * a <code>binary_double</code> if it is necessary.</p>
   *
   * <pre>
   * declare
   *   mynum pljson_value := pljson_value('42');
   * begin
   *   dbms_output.put_line('mynum is a string: ' || mynum.is_string()); // 'true'
   *   mynum.parse_number('42');
   *   dbms_output.put_line('mynum is a number: ' || mynum.is_number()); // 'true'
   * end;
   * </pre>
   *
   * @param str A <code>varchar2</code> to parse into a number.
   */
  -- this procedure is meant to be used internally only
  -- procedure does not work correctly if called standalone in locales that
  -- use a character other than "." for decimal point
  member procedure parse_number(str varchar2),

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  /**
   * <p>Return a <code>varchar2</code> representation of a <code>number</code>
   * type. This is primarily intended to be used within PL/JSON internally.</p>
   *
   * @return A <code>varchar2</code> up to 4000 characters.
   */
  -- this procedure is meant to be used internally only
  member function number_toString return varchar2,

  /* Output methods */
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2,
  member procedure to_clob(self in pljson_value, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true),
  member procedure print(self in pljson_value, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null), --32512 is maximum
  member procedure htp(self in pljson_value, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null),

  member function value_of(self in pljson_value, max_byte_size number default null, max_char_size number default null) return varchar2

) not final;
/
show err

create or replace type pljson_value_array as table of pljson_value;
/
show err
