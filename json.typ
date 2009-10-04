CREATE OR REPLACE TYPE json AS OBJECT (
  /*
  Copyright (c) 2009 Jonas Krogsboell, based on code from Lewis R Cunningham

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

  /* Variables */
  json_data json_member_array,
  num_elements number,
  
  /* Constructors */
  constructor function json return self as result,
  constructor function json(pair_data in json_member_array) return self as result,
  constructor function json(str varchar2) return self as result,
  constructor function json(str clob) return self as result,
    
  /* Member setter methods */  
  member procedure remove(pair_name varchar2),
  member procedure put(pair_name varchar2, pair_value anydata, position pls_integer default null),
  member procedure put(pair_name varchar2, pair_value varchar2, position pls_integer default null),
  member procedure put(pair_name varchar2, pair_value number, position pls_integer default null),
  member procedure put(pair_name varchar2, pair_value json_bool, position pls_integer default null),
  member procedure put(pair_name varchar2, pair_value json_null, position pls_integer default null),
  member procedure put(pair_name varchar2, pair_value json_list, position pls_integer default null),
  member procedure put(pair_name varchar2, pair_value json, position pls_integer default null),
  
  /* Member getter methods */ 
  member function count return number,
  member function get(pair_name varchar2) return anydata, 
  member function exist(pair_name varchar2) return boolean,
  member function to_char(spaces boolean default true) return varchar2,
  member procedure to_clob(buf in out nocopy clob, spaces boolean default false),
  member procedure print(spaces boolean default true),
  member function to_anydata return anydata,
  
  /* Static conversion methods */  
  static function to_json(v anydata) return json,
  static function to_number(v anydata) return number,
  static function to_varchar2(v anydata) return varchar2,
  static function to_json_list(v anydata) return json_list,
  static function to_json_bool(v anydata) return json_bool,
  static function to_json_null(v anydata) return json_null
  
);
/
sho err

 
