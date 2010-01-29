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
  str varchar2(4000),
  num number, /* store 1 as true, 0 as false */
  object_or_array anydata, /* object or array in here */
  
  constructor function json_value(object_or_array anydata) return self as result,
  constructor function json_value(str varchar2) return self as result,
  constructor function json_value(num number) return self as result,
  constructor function json_value(b boolean) return self as result,
  constructor function json_value return self as result,
  static function makenull return json_value,
  
  member function get_type return varchar2,
  member function get_string return varchar2,
  member function get_number return number,
  member function get_bool return boolean,
  member function get_null return varchar2,
  
  member function is_object return boolean,
  member function is_array return boolean,
  member function is_string return boolean,
  member function is_number return boolean,
  member function is_bool return boolean,
  member function is_null return boolean,
  
  member function compare(cmp json_value) return number
);
/

create or replace
type body json_value as

  constructor function json_value(object_or_array anydata) return self as result as
  begin
    case object_or_array.gettypename
      when sys_context('userenv', 'current_schema')||'.JSON_LIST' then self.typeval := 2;
      when sys_context('userenv', 'current_schema')||'.JSON' then self.typeval := 1;
      else raise_application_error(-20102, 'JSON_Value init error (JSON or JSON\_List allowed)');
    end case;
    self.object_or_array := object_or_array;
    return;
  end json_value;

  constructor function json_value(str varchar2) return self as result as
  begin
    self.typeval := 3;
    self.str := str;
    return;
  end json_value;

  constructor function json_value(num number) return self as result as
  begin
    self.typeval := 4;
    self.num := num;
    return;
  end json_value;

  constructor function json_value(b boolean) return self as result as
  begin
    self.typeval := 5;
    self.num := 0;
    if(b) then self.num := 1; end if;
    return;
  end json_value;

  constructor function json_value return self as result as
  begin
    self.typeval := 6; /* for JSON null */
    return;
  end json_value;

  static function makenull return json_value as
  begin
    return json_value;
  end makenull;

  member function get_type return varchar2 as
  begin
    case self.typeval
    when 1 then return 'object';
    when 2 then return 'array';
    when 3 then return 'string';
    when 4 then return 'number';
    when 5 then return 'bool';
    when 6 then return 'null';
    end case;
    
    return 'unknown type';
  end get_type;

  member function get_string return varchar2 as
  begin
    if(self.typeval = 3) then 
      return self.str;
    end if;
    return null;
  end get_string;

  member function get_number return number as
  begin
    if(self.typeval = 4) then 
      return self.num;
    end if;
    return null;
  end get_number;

  member function get_bool return boolean as
  begin
    if(self.typeval = 5) then 
      return self.num = 1;
    end if;
    return null;
  end get_bool;

  member function get_null return varchar2 as
  begin
    if(self.typeval = 6) then 
      return 'null';
    end if;
    return null;
  end get_null;

  member function is_object return boolean as begin return self.typeval = 1; end;
  member function is_array return boolean as begin return self.typeval = 2; end;
  member function is_string return boolean as begin return self.typeval = 3; end;
  member function is_number return boolean as begin return self.typeval = 4; end;
  member function is_bool return boolean as begin return self.typeval = 5; end;
  member function is_null return boolean as begin return self.typeval = 6; end;

  member function compare(cmp json_value) return number as
  begin
    if(cmp is null) then
      --throw an exception? no, just say initialized objects comes before unintialized
      return -1;
    end if;
    if(self.typeval < cmp.typeval) then return -1; end if;
    if(cmp.typeval < self.typeval) then return 1; end if;
    if(self.typeval = 3) then
      return greatest(self.str, cmp.str);
    elsif(self.typeval in (4,5)) then
      /* true - false => 1 */
      /* false - true => -1 */
      /* otherwise => 0 */
      /* 0 - 2 => -2 */
      /* -5 - (-6) => 1 */
      return self.num-cmp.num; 
    end if;
    
    return 0;
  end compare;

end;
/

