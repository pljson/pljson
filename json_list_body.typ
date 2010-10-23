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

create or replace type body json_list as

  constructor function json_list return self as result as
  begin
    self.list_data := json_value_array();
    return;
  end;

  constructor function json_list(str varchar2) return self as result as
  begin
    self := json_parser.parse_list(str);
    return;
  end;
  
  constructor function json_list(str clob) return self as result as
  begin
    self := json_parser.parse_list(str);
    return;
  end;

  constructor function json_list(cast json_value) return self as result as
    x number;
  begin
    x := cast.object_or_array.getobject(self);
    return;
  end;


  member procedure add_elem(self in out nocopy json_list, elem json_value, position pls_integer default null) as
    indx pls_integer;
    insert_value json_value := NVL(elem, json_value);
  begin
    if(position is null or position > self.count) then --end of list
      indx := self.count + 1;
      self.list_data.extend(1);
      self.list_data(indx) := insert_value;
    elsif(position < 1) then --new first
      indx := self.count;
      self.list_data.extend(1);
      for x in reverse 1 .. indx loop
        self.list_data(x+1) := self.list_data(x);
      end loop;
      self.list_data(1) := insert_value;
    else
      indx := self.count;
      self.list_data.extend(1);
      for x in reverse position .. indx loop
        self.list_data(x+1) := self.list_data(x);
      end loop;
      self.list_data(position) := insert_value;
    end if;

  end;

  member procedure add_elem(self in out nocopy json_list, elem varchar2, position pls_integer default null) as
  begin
    add_elem(json_value(elem), position);
  end;
  
  member procedure add_elem(self in out nocopy json_list, elem number, position pls_integer default null) as
  begin
    if(elem is null) then
      add_elem(json_value(), position);
    else
      add_elem(json_value(elem), position);
    end if;
  end;
  
  member procedure add_elem(self in out nocopy json_list, elem boolean, position pls_integer default null) as
  begin
    if(elem is null) then
      add_elem(json_value(), position);
    else
      add_elem(json_value(elem), position);
    end if;
  end;

  member procedure add_elem(self in out nocopy json_list, elem json_list, position pls_integer default null) as
  begin
    if(elem is null) then
      add_elem(json_value(), position);
    else
      add_elem(elem.to_json_value, position);
    end if;
  end;
  
 member procedure set_elem(self in out nocopy json_list, position pls_integer, elem json_value) as
    insert_value json_value := NVL(elem, json_value);
    indx number;
  begin
    if(position > self.count) then --end of list
      indx := self.count + 1;
      self.list_data.extend(1);
      self.list_data(indx) := insert_value;
    elsif(position < 1) then --maybe an error message here
      null;
    else
      self.list_data(position) := insert_value;
    end if;
  end;
  
  member procedure set_elem(self in out nocopy json_list, position pls_integer, elem varchar2) as
  begin
    set_elem(position, json_value(elem));
  end;
  
  member procedure set_elem(self in out nocopy json_list, position pls_integer, elem number) as
  begin
    if(elem is null) then
      set_elem(position, json_value());
    else
      set_elem(position, json_value(elem));
    end if;
  end;
  
  member procedure set_elem(self in out nocopy json_list, position pls_integer, elem boolean) as 
  begin
    if(elem is null) then
      set_elem(position, json_value());
    else
      set_elem(position, json_value(elem));
    end if;
  end;
  
  member procedure set_elem(self in out nocopy json_list, position pls_integer, elem json_list) as 
  begin
    if(elem is null) then
      set_elem(position, json_value());
    else
      set_elem(position, elem.to_json_value);
    end if;
  end;

  member function count return number as
  begin
    return self.list_data.count;
  end;
  
  member procedure remove_elem(self in out nocopy json_list, position pls_integer) as
  begin
    if(position is null or position < 1 or position > self.count) then return; end if;
    for x in (position+1) .. self.count loop
      self.list_data(x-1) := self.list_data(x);
    end loop;
    self.list_data.trim(1);
  end;
  
  member procedure remove_first(self in out nocopy json_list) as 
  begin
    for x in 2 .. self.count loop
      self.list_data(x-1) := self.list_data(x);
    end loop;
    if(self.count > 0) then 
      self.list_data.trim(1);
    end if;
  end;
  
  member procedure remove_last(self in out nocopy json_list) as
  begin
    if(self.count > 0) then 
      self.list_data.trim(1);
    end if;
  end;
  
  member function get_elem(position pls_integer) return json_value as
  begin
    if(self.count >= position and position > 0) then
      return self.list_data(position);
    end if;
    return null; -- do not throw error, just return null
  end;
  
  member function get_first return json_value as
  begin
    if(self.count > 0) then
      return self.list_data(self.list_data.first);
    end if;
    return null; -- do not throw error, just return null
  end;
  
  member function get_last return json_value as
  begin
    if(self.count > 0) then
      return self.list_data(self.list_data.last);
    end if;
    return null; -- do not throw error, just return null
  end;

  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin
    if(spaces is null) then
      return json_printer.pretty_print_list(self, line_length => chars_per_line);
    else 
      return json_printer.pretty_print_list(self, spaces, line_length => chars_per_line);
    end if;
  end;

  member procedure to_clob(self in json_list, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0) as
  begin
    if(spaces is null) then	
      json_printer.pretty_print_list(self, false, buf, line_length => chars_per_line);
    else 
      json_printer.pretty_print_list(self, spaces, buf, line_length => chars_per_line);
    end if;
  end;

  member procedure print(self in json_list, spaces boolean default true, chars_per_line number default 8192) as --32512 is the real maximum in sqldeveloper
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    json_printer.pretty_print_list(self, spaces, my_clob, case when (chars_per_line>32512) then 32512 else chars_per_line end);
    json_printer.dbms_output_clob(my_clob, json_printer.newline_char);
    dbms_lob.freetemporary(my_clob);  
  end;
  
  member procedure htp(self in json_list, spaces boolean default false, chars_per_line number default 0) as 
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    json_printer.pretty_print_list(self, spaces, my_clob, case when (chars_per_line>32512) then 32512 else chars_per_line end);
    json_printer.htp_output_clob(my_clob);
    dbms_lob.freetemporary(my_clob);  
  end;

  /* json path */
  member function path(json_path varchar2) return json_value as
    cp json_list := self;
  begin
    return json_ext.get_json_value(json(cp), json_path);
  end path;


  /* json path_put */
  member procedure path_put(self in out nocopy json_list, json_path varchar2, elem json_value) as
    objlist json := json(self);
  begin
    json_ext.put(objlist, json_path, elem);
    self := objlist.get_values;
  end path_put;
  
  member procedure path_put(self in out nocopy json_list, json_path varchar2, elem varchar2) as
    objlist json := json(self);
  begin
    json_ext.put(objlist, json_path, elem);
    self := objlist.get_values;
  end path_put;
  
  member procedure path_put(self in out nocopy json_list, json_path varchar2, elem number) as
    objlist json := json(self);
  begin
    if(elem is null) then 
      json_ext.put(objlist, json_path, json_value);
    else 
      json_ext.put(objlist, json_path, elem);
    end if;
    self := objlist.get_values;
  end path_put;

  member procedure path_put(self in out nocopy json_list, json_path varchar2, elem boolean) as
    objlist json := json(self);
  begin
    if(elem is null) then 
      json_ext.put(objlist, json_path, json_value);
    else 
      json_ext.put(objlist, json_path, elem);
    end if;
    self := objlist.get_values;
  end path_put;

  member procedure path_put(self in out nocopy json_list, json_path varchar2, elem json_list) as
    objlist json := json(self);
  begin
    if(elem is null) then 
      json_ext.put(objlist, json_path, json_value);
    else 
      json_ext.put(objlist, json_path, elem);
    end if;
    self := objlist.get_values;
  end path_put;
  
  member function to_json_value return json_value as
  begin
    return json_value(anydata.convertobject(self));
  end;
 
end;
/

sho err
