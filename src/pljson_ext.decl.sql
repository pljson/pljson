create or replace package pljson_ext as
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

  /* This package contains extra methods to lookup types and
     an easy way of adding date values in json - without changing the structure */
  function parsePath(json_path varchar2, base number default 1) return pljson_list;

  --JSON pre-parsed path getters
  function get_json_element(obj pljson, path pljson_list) return pljson_element;
  function get_string(obj pljson, path pljson_list) return varchar2;
  function get_number(obj pljson, path pljson_list) return number;
  function get_double(obj pljson, path pljson_list) return binary_double;
  function get_json(obj pljson, path pljson_list) return pljson;
  function get_json_list(obj pljson, path pljson_list) return pljson_list;
  function get_bool(obj pljson, path pljson_list) return boolean;
  function get_date(obj pljson, path pljson_list) return date;

  --saved original code, in case of future bug troubleshooting
  function get_json_element_original(obj pljson, v_path varchar2, base number default 1) return pljson_element;
  
  --JSON Path getters
  function get_json_element(obj pljson, v_path varchar2, base number default 1) return pljson_element;
  function get_string(obj pljson, path varchar2,       base number default 1) return varchar2;
  function get_number(obj pljson, path varchar2,       base number default 1) return number;
  function get_double(obj pljson, path varchar2,       base number default 1) return binary_double;
  function get_json(obj pljson, path varchar2,         base number default 1) return pljson;
  function get_json_list(obj pljson, path varchar2,    base number default 1) return pljson_list;
  function get_bool(obj pljson, path varchar2,         base number default 1) return boolean;

  --JSON pre-parsed path putters
  procedure put(obj in out nocopy pljson, path pljson_list, elem varchar2);
  procedure put(obj in out nocopy pljson, path pljson_list, elem number);
  procedure put(obj in out nocopy pljson, path pljson_list, elem binary_double);
  procedure put(obj in out nocopy pljson, path pljson_list, elem pljson);
  procedure put(obj in out nocopy pljson, path pljson_list, elem pljson_list);
  procedure put(obj in out nocopy pljson, path pljson_list, elem boolean);
  procedure put(obj in out nocopy pljson, path pljson_list, elem pljson_element);
  procedure put(obj in out nocopy pljson, path pljson_list, elem date);

  --JSON Path putters
  procedure put(obj in out nocopy pljson, path varchar2, elem varchar2,   base number default 1);
  procedure put(obj in out nocopy pljson, path varchar2, elem number,     base number default 1);
  procedure put(obj in out nocopy pljson, path varchar2, elem binary_double, base number default 1);
  procedure put(obj in out nocopy pljson, path varchar2, elem pljson,       base number default 1);
  procedure put(obj in out nocopy pljson, path varchar2, elem pljson_list,  base number default 1);
  procedure put(obj in out nocopy pljson, path varchar2, elem boolean,    base number default 1);
  procedure put(obj in out nocopy pljson, path varchar2, elem pljson_element, base number default 1);

  procedure remove(obj in out nocopy pljson, path pljson_list);
  procedure remove(obj in out nocopy pljson, path varchar2, base number default 1);

  --Pretty print with JSON Path - obsolete in 0.9.4 - obj.path(v_path).(to_char,print,htp)
  function pp(obj pljson, v_path varchar2) return varchar2;
  procedure pp(obj pljson, v_path varchar2); --using dbms_output.put_line
  procedure pp_htp(obj pljson, v_path varchar2); --using htp.print

  --extra function checks if number has no fraction
  function is_integer(v pljson_element) return boolean;

  format_string varchar2(30 char) := 'yyyy-mm-dd hh24:mi:ss';
  --extension enables json to store dates without compromising the implementation
  function to_json_string(d date) return pljson_string;
  --notice that a date type in json is also a varchar2
  function is_date(v pljson_element) return boolean;
  --conversion is needed to extract dates
  function to_date(v pljson_element) return date;
  -- alias so that old code doesn't break
  function to_date2(v pljson_element) return date;
  --JSON Path with date
  function get_date(obj pljson, path varchar2, base number default 1) return date;
  procedure put(obj in out nocopy pljson, path varchar2, elem date, base number default 1);

  /*
    encoding in lines of 64 chars ending with CR+NL
  */
  function encodeBase64Blob2Clob(p_blob in  blob) return clob;
  /*
    assumes single base64 string or broken into equal length lines of max 64 or 76 chars
    (as specified by RFC-1421 or RFC-2045)
    line ending can be CR+NL or NL
  */
  function decodeBase64Clob2Blob(p_clob clob) return blob;

  function base64(binarydata blob) return pljson_list;
  function base64(l pljson_list) return blob;

  function encode(binarydata blob) return pljson_string;
  function decode(v pljson_string) return blob;

  /*
    implemented as a procedure to force you to declare the CLOB so you can free it later
  */
  procedure blob2clob(b blob, c out clob, charset varchar2 default 'UTF8');
end pljson_ext;
/
show err