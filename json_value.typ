create or replace
type json_value as object
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

  typeval number(1), /* 1 = object, 2 = array, 3 = string, 4 = number, 5 = bool, 6 = null */
  str varchar2(32767),
  num number, /* store 1 as true, 0 as false */
  object_or_array sys.anydata, /* object or array in here */
  extended_str clob,
  
  /* mapping */
  mapname varchar2(4000),
  mapindx number(32),  
  
  constructor function json_value(object_or_array sys.anydata) return self as result,
  constructor function json_value(str varchar2, esc boolean default true) return self as result,
  constructor function json_value(str clob, esc boolean default true) return self as result,
  constructor function json_value(num number) return self as result,
  constructor function json_value(b boolean) return self as result,
  constructor function json_value return self as result,
  static function makenull return json_value,
  
  member function get_type return varchar2,
  member function get_string(max_byte_size number default null, max_char_size number default null) return varchar2,
  member procedure get_string(self in json_value, buf in out nocopy clob),
  member function get_number return number,
  member function get_bool return boolean,
  member function get_null return varchar2,
  
  member function is_object return boolean,
  member function is_array return boolean,
  member function is_string return boolean,
  member function is_number return boolean,
  member function is_bool return boolean,
  member function is_null return boolean,
  
  /* Output methods */ 
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2,
  member procedure to_clob(self in json_value, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true),
  member procedure print(self in json_value, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null), --32512 is maximum
  member procedure htp(self in json_value, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null),
  
  member function value_of(self in json_value, max_byte_size number default null, max_char_size number default null) return varchar2
  
) not final;
/

create or replace type json_value_array as table of json_value;
/

sho err
