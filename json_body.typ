create or replace type body json as
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

  /* Constructors */
  constructor function json return self as result as
  begin
    self.num_elements := 0;
    self.json_data := json_member_array();
    return;
  end;
  
  constructor function json(pair_data in json_member_array) return self as result as
  begin
    self.num_elements := pair_data.count;
    self.json_data := pair_data;
    return;
  end;

  constructor function json(str varchar2) return self as result as
  begin
    self := json_parser.parser(str);
    return;
  end;
  
  constructor function json(str clob) return self as result as
  begin
    self := json_parser.parser(str);
    return;
  end;  

  /* Member setter methods */  
  member procedure remove(pair_name varchar2) as
    temp json_member;
    indx pls_integer;
    
    function get_member(pair_name varchar2) return json_member as
      indx pls_integer;
    begin
      indx := json_data.first;
      loop
        exit when indx is null;
        if(json_data(indx).member_name = pair_name) then return json_data(indx); end if;
        indx := json_data.next(indx);
      end loop;
      return null;
    end;
  begin
    temp := get_member(pair_name);
    if(temp is null) then return; end if;
    
    indx := json_data.next(temp.id);
    loop 
      exit when indx is null;
      json_data(indx).id := indx - 1;
      json_data(indx-1) := json_data(indx);
      indx := json_data.next(indx);
    end loop;
    json_data.trim(1);
    num_elements := num_elements - 1;
  end;

  member procedure put(pair_name varchar2, pair_value anydata, position pls_integer default null) as
    indx pls_integer; x number;
    temp json_member;
    function get_member(pair_name varchar2) return json_member as
      indx pls_integer;
    begin
      indx := json_data.first;
      loop
        exit when indx is null;
        if(json_data(indx).member_name = pair_name) then return json_data(indx); end if;
        indx := json_data.next(indx);
      end loop;
      return null;
    end;
  begin
    if(pair_name is null) then 
      raise_application_error(-20102, 'JSON put-method type error: name cannot be null');
    end if;
    case pair_value.gettypename
      when 'SYS.VARCHAR2' then null;
      when 'SYS.NUMBER' then null;
      when sys_context('userenv', 'current_schema')||'.JSON_BOOL' then null;
      when sys_context('userenv', 'current_schema')||'.JSON_NULL' then null;
      when sys_context('userenv', 'current_schema')||'.JSON_LIST' then null;
      when sys_context('userenv', 'current_schema')||'.JSON' then null;
      else raise_application_error(-20102, 'JSON put-method type error');
    end case;

--    self.remove(pair_name);
    temp := get_member(pair_name);
    if(temp is not null) then
      json_data(temp.id).member_data := pair_value;
      return;
    elsif(position is null or position > self.count) then
      --insert at the end of the list
      --dbms_output.put_line('Test');
      indx := self.count + 1;
      json_data.extend;
      json_data(indx) := json_member(indx, pair_name, pair_value);
      --dbms_output.put_line('Test2');
    elsif(position < 2) then
      --insert at the start of the list
      indx := json_data.last;
      json_data.extend;
      loop
        exit when indx is null;
        temp := json_data(indx);
        temp.id := indx+1;
        json_data(temp.id) := temp;
        indx := json_data.prior(indx);
      end loop;
      json_data(1) := json_member(1, pair_name, pair_value);
    else 
      --insert somewhere in the list
      indx := json_data.last; 
--      dbms_output.put_line('Test '||indx);
      json_data.extend;
--      dbms_output.put_line('Test '||indx);
      loop
--        dbms_output.put_line('Test '||indx);
        temp := json_data(indx);
        temp.id := indx + 1;
        json_data(temp.id) := temp;
        exit when indx = position;
        indx := json_data.prior(indx);
      end loop;
      json_data(position) := json_member(position, pair_name, pair_value);
    end if;
    num_elements := num_elements + 1;
  end;
  
  member procedure put(pair_name varchar2, pair_value varchar2, position pls_integer default null) as
  begin
    put(pair_name, anydata.convertvarchar2(pair_value), position);
  end;
  
  member procedure put(pair_name varchar2, pair_value number, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_null(), position);
    else 
      put(pair_name, anydata.convertnumber(pair_value), position);
    end if;
  end;
  
  member procedure put(pair_name varchar2, pair_value json_bool, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_null(), position);
    else 
      put(pair_name, anydata.convertobject(pair_value), position);
    end if;
  end;

  member procedure put(pair_name varchar2, pair_value json_null, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_null(), position);
    else 
      put(pair_name, anydata.convertobject(pair_value), position);
    end if;
  end;
  
  member procedure put(pair_name varchar2, pair_value json_list, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_null(), position);
    else 
      put(pair_name, anydata.convertobject(pair_value), position);
    end if;
  end;

  member procedure put(pair_name varchar2, pair_value json, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_null(), position);
    else 
      put(pair_name, anydata.convertobject(pair_value), position);
    end if;
  end;

 
  /* Member getter methods */ 
  member function count return number as
  begin
    return self.num_elements;
  end;

  member function get(pair_name varchar2) return anydata as
    indx pls_integer;
  begin
    indx := json_data.first;
    loop
      exit when indx is null;
      if(json_data(indx).member_name = pair_name) then return json_data(indx).member_data; end if;
      indx := json_data.next(indx);
    end loop;
    return null;
  end;
  
  member function exist(pair_name varchar2) return boolean as
  begin
    return (self.get(pair_name) is not null);
  end;
  
  member function to_char(spaces boolean default true) return varchar2 as
  begin
    if(spaces is null) then	
      return json_printer.pretty_print(self);
    else 
      return json_printer.pretty_print(self, spaces);
    end if;
  end;
  
  member procedure to_clob(buf in out nocopy clob, spaces boolean default false) as
  begin
    if(spaces is null) then	
      json_printer.pretty_print(self, false, buf);
    else 
      json_printer.pretty_print(self, spaces, buf);
    end if;
  end;

  member procedure print(spaces boolean default true) as
  begin
    dbms_output.put_line(self.to_char(spaces));
  end;
  
  member function to_anydata return anydata as
  begin
    return anydata.convertobject(self);
  end;

  /* Static conversion methods */  
  static function to_json(v anydata) return json as
    temp json; x number;
  begin
    x := v.getobject(temp);
    return temp;
  end;
  
  static function to_number(v anydata) return number as 
    temp number; x number;
  begin
    x := v.getnumber(temp);
    return temp;
  end;

  static function to_varchar2(v anydata) return varchar2 as
    temp varchar2(4000); x number;
  begin
    x := v.getvarchar2(temp);
    return temp;
  end;
  
  static function to_json_list(v anydata) return json_list as 
    temp json_list; x number;
  begin
    x := v.getobject(temp);
    return temp;
  end;

  static function to_json_bool(v anydata) return json_bool as
    temp json_bool; x number;
  begin
    x := v.getobject(temp);
    return temp;
  end;

  static function to_json_null(v anydata) return json_null as
    temp json_null; x number;
  begin
    x := v.getobject(temp);
    return temp;
  end;
 
end;
/ 
sho err
