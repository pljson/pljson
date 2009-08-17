create or replace type body json_list as
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

  constructor function json_list return self as result as
  begin
    self.list_data := json_element_array();
    return;
  end;

  constructor function json_list(str varchar2) return self as result as
  begin
    self := json_parser.parse_list(str);
    return;
  end;

  member procedure add_elem(elem anydata, position pls_integer default null) as
    indx pls_integer;
  begin
    case elem.gettypename
      when 'SYS.VARCHAR2' then null;
      when 'SYS.NUMBER' then null;
      when sys_context('userenv', 'current_schema')||'.JSON_BOOL' then null;
      when sys_context('userenv', 'current_schema')||'.JSON_NULL' then null;
      when sys_context('userenv', 'current_schema')||'.JSON_LIST' then null;
      when sys_context('userenv', 'current_schema')||'.JSON' then null;
      else raise_application_error(-20102, 'JSON_LIST add_elem method type error');
    end case;

    if(position is null or position > self.count) then --end of list
      indx := self.count + 1;
      self.list_data.extend(1);
      self.list_data(indx) := json_element(indx, elem);
    elsif(position < 1) then --new first
      indx := self.count;
      self.list_data.extend(1);
      for x in reverse 1 .. indx loop
        self.list_data(x+1) := self.list_data(x);
        self.list_data(x+1).element_id := x+1;
      end loop;
      self.list_data(1) := json_element(1, elem);
    else
      indx := self.count;
      self.list_data.extend(1);
      for x in reverse position .. indx loop
        self.list_data(x+1) := self.list_data(x);
        self.list_data(x+1).element_id := x+1;
      end loop;
      self.list_data(position) := json_element(position, elem);
    end if;

  end;

  member procedure add_elem(elem varchar2, position pls_integer default null) as
  begin
    add_elem(anydata.convertvarchar2(elem), position);
  end;
  
  member procedure add_elem(elem number, position pls_integer default null) as
  begin
    if(elem is null) then
      add_elem(json_null(), position);
    else
      add_elem(anydata.convertnumber(elem), position);
    end if;
  end;
  
  member procedure add_elem(elem json_bool, position pls_integer default null) as
  begin
    if(elem is null) then
      add_elem(json_null(), position);
    else
      add_elem(anydata.convertobject(elem), position);
    end if;
  end;
  
  member procedure add_elem(elem json_null, position pls_integer default null) as
  begin
    if(elem is null) then
      add_elem(json_null(), position);
    else
      add_elem(anydata.convertobject(elem), position);
    end if;
  end;
  
  member procedure add_elem(elem json_list, position pls_integer default null) as
  begin
    if(elem is null) then
      add_elem(json_null(), position);
    else
      add_elem(anydata.convertobject(elem), position);
    end if;
  end;
  
  member function count return number as
  begin
    return self.list_data.count;
  end;
  
  member procedure remove_elem(position pls_integer) as
  begin
    if(position is null or position < 1 or position > self.count) then return; end if;
    for x in (position+1) .. self.count loop
      self.list_data(x-1) := self.list_data(x);
      self.list_data(x-1).element_id := x-1;
    end loop;
    self.list_data.trim(1);
  end;
  
  member procedure remove_first as 
  begin
    for x in 2 .. self.count loop
      self.list_data(x-1) := self.list_data(x);
      self.list_data(x-1).element_id := x-1;
    end loop;
    if(self.count > 0) then 
      self.list_data.trim(1);
    end if;
  end;
  
  member procedure remove_last as
  begin
    if(self.count > 0) then 
      self.list_data.trim(1);
    end if;
  end;
  
  member function get_elem(position pls_integer) return anydata as
  begin
    if(self.count >= position and position > 0) then
      return self.list_data(position).element_data;
    end if;
    return null; -- do not throw error, just return null
  end;
  
  member function get_first return anydata as
  begin
    if(self.count > 0) then
      return self.list_data(self.list_data.first).element_data;
    end if;
    return null; -- do not throw error, just return null
  end;
  
  member function get_last return anydata as
  begin
    if(self.count > 0) then
      return self.list_data(self.list_data.last).element_data;
    end if;
    return null; -- do not throw error, just return null
  end;

  member function to_char return varchar2 as
  begin
    return json_printer.pretty_print_list(self);
  end;

  member procedure print as
  begin
    dbms_output.put_line(self.to_char);
  end;
  
end;
/

sho err
