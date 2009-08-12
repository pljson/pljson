create or replace package json_ext as
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
  
  --removes the need for gettypename hassle on anydata
  function is_varchar2(v anydata) return boolean;
  function is_number(v anydata) return boolean;
  function is_json(v anydata) return boolean;
  function is_json_list(v anydata) return boolean;
  function is_json_bool(v anydata) return boolean;
  function is_json_null(v anydata) return boolean;
  
  --extra function checks if number has no fraction
  function is_integer(v anydata) return boolean;
  
  format_string varchar2(30) := 'yyyy-mm-dd hh24:mi:ss';
  --extension enables json to store dates without comprimising the implementation
  function to_anydata(d date) return anydata;
  --notice that a date type in json is also a varchar2
  function is_date(v anydata) return boolean;
  --convertion is needed to extract dates 
  --(json_ext.to_date will not work along with the normal to_date function - any fix will be appreciated)
  function to_date2(v anydata) return date;
  
end json_ext;
/
create or replace
package body json_ext as
  --removes the need for gettypename hassle on anydata
  function is_varchar2(v anydata) return boolean as
  begin
    return (v.gettypename = 'SYS.VARCHAR2');
  end;
  
  function is_number(v anydata) return boolean as
  begin
    return (v.gettypename = 'SYS.NUMBER');
  end;

  function is_json(v anydata) return boolean as
  begin
    return (v.gettypename = sys_context('userenv', 'current_schema')||'.JSON');
  end;
  
  function is_json_list(v anydata) return boolean as
  begin
    return (v.gettypename = sys_context('userenv', 'current_schema')||'.JSON_LIST');
  end;
  
  function is_json_bool(v anydata) return boolean as
  begin
    return (v.gettypename = sys_context('userenv', 'current_schema')||'.JSON_BOOL');
  end;
  
  function is_json_null(v anydata) return boolean as
  begin
    return (v.gettypename = sys_context('userenv', 'current_schema')||'.JSON_NULL');
  end;
  
  --extra function checks if number has no fraction
  function is_integer(v anydata) return boolean as
    myint number(38); --the oracle way to specify an integer
  begin
    if(is_number(v)) then
      myint := json.to_number(v);
      return (myint = json.to_number(v)); --no rounding errors?
    else
      return false;
    end if;
  end;
  
  --extension enables json to store dates without comprimising the implementation
  function to_anydata(d date) return anydata as
  begin
    return anydata.convertvarchar2(to_char(d, format_string));
  end;
  
  --notice that a date type in json is also a varchar2
  function is_date(v anydata) return boolean as
    temp date;
  begin
    temp := json_ext.to_date2(v);
    return true;
  exception
    when others then 
      return false;
  end;
  
  --convertion is needed to extract dates
  function to_date2(v anydata) return date as
    temp varchar2(30);
  begin
    if(is_varchar2(v)) then
      temp := json.to_varchar2(v);
      return to_date(temp, format_string);
    else
      raise_application_error(-20110, 'Anydata did not contain a date-value');
    end if;
  exception
    when others then
      raise_application_error(-20110, 'Anydata did not contain a date on the format: '||format_string);
  end;

end json_ext;
/
