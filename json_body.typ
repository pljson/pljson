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
create or replace type body json as

  /* Constructors */
  constructor function json return self as result as
  begin
    self.json_data := json_value_array();
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function json(str varchar2) return self as result as
  begin
    self := json_parser.parser(str);
    self.check_for_duplicate := 1;
    return;
  end;
  
  constructor function json(str in clob) return self as result as
  begin
    self := json_parser.parser(str);
    self.check_for_duplicate := 1;
    return;
  end;  

  constructor function json(cast json_value) return self as result as
    x number;
  begin
    x := cast.object_or_array.getobject(self);
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function json(l in out nocopy json_list) return self as result as
  begin
    for i in 1 .. l.list_data.count loop
      if(l.list_data(i).mapname is null or l.list_data(i).mapname like 'row%') then
      l.list_data(i).mapname := 'row'||i;
      end if;
      l.list_data(i).mapindx := i;
    end loop;

    self.json_data := l.list_data;
    self.check_for_duplicate := 1;
    return;
  end;

  /* Member setter methods */  
  member procedure remove(self in out nocopy json, pair_name varchar2) as
    temp json_value;
    indx pls_integer;
    
    function get_member(pair_name varchar2) return json_value as
      indx pls_integer;
    begin
      indx := json_data.first;
      loop
        exit when indx is null;
        if(pair_name is null and json_data(indx).mapname is null) then return json_data(indx); end if;
        if(json_data(indx).mapname = pair_name) then return json_data(indx); end if;
        indx := json_data.next(indx);
      end loop;
      return null;
    end;
  begin
    temp := get_member(pair_name);
    if(temp is null) then return; end if;
    
    indx := json_data.next(temp.mapindx);
    loop 
      exit when indx is null;
      json_data(indx).mapindx := indx - 1;
      json_data(indx-1) := json_data(indx);
      indx := json_data.next(indx);
    end loop;
    json_data.trim(1);
    --num_elements := num_elements - 1;
  end;

  member procedure put(self in out nocopy json, pair_name varchar2, pair_value json_value, position pls_integer default null) as
    insert_value json_value := nvl(pair_value, json_value.makenull);
    indx pls_integer; x number;
    temp json_value;
    function get_member(pair_name varchar2) return json_value as
      indx pls_integer;
    begin
      indx := json_data.first;
      loop
        exit when indx is null;
        if(pair_name is null and json_data(indx).mapname is null) then return json_data(indx); end if;
        if(json_data(indx).mapname = pair_name) then return json_data(indx); end if;
        indx := json_data.next(indx);
      end loop;
      return null;
    end;
  begin
    --dbms_output.put_line('PN '||pair_name);

--    if(pair_name is null) then 
--      raise_application_error(-20102, 'JSON put-method type error: name cannot be null');
--    end if;
    insert_value.mapname := pair_name;
--    self.remove(pair_name);
    if(self.check_for_duplicate = 1) then temp := get_member(pair_name); else temp := null; end if;
    if(temp is not null) then
      insert_value.mapindx := temp.mapindx;
      json_data(temp.mapindx) := insert_value; 
      return;
    elsif(position is null or position > self.count) then
      --insert at the end of the list
      --dbms_output.put_line('Test');
--      indx := self.count + 1;
      json_data.extend(1);
      json_data(json_data.count) := insert_value;
--      insert_value.mapindx := json_data.count;
      json_data(json_data.count).mapindx := json_data.count;
--      dbms_output.put_line('Test2'||insert_value.mapindx);
--      dbms_output.put_line('Test2'||insert_value.mapname);
--      insert_value.print(false);
--      self.print;
    elsif(position < 2) then
      --insert at the start of the list
      indx := json_data.last;
      json_data.extend;
      loop
        exit when indx is null;
        temp := json_data(indx);
        temp.mapindx := indx+1;
        json_data(temp.mapindx) := temp;
        indx := json_data.prior(indx);
      end loop;
      json_data(1) := insert_value;
      insert_value.mapindx := 1;
    else 
      --insert somewhere in the list
      indx := json_data.last; 
--      dbms_output.put_line('Test '||indx);
      json_data.extend;
--      dbms_output.put_line('Test '||indx);
      loop
--        dbms_output.put_line('Test '||indx);
        temp := json_data(indx);
        temp.mapindx := indx + 1;
        json_data(temp.mapindx) := temp;
        exit when indx = position;
        indx := json_data.prior(indx);
      end loop;
      json_data(position) := insert_value;
      json_data(position).mapindx := position;
    end if;
--    num_elements := num_elements + 1;
  end;
  
  member procedure put(self in out nocopy json, pair_name varchar2, pair_value varchar2, position pls_integer default null) as
  begin
    put(pair_name, json_value(pair_value), position);
  end;
  
  member procedure put(self in out nocopy json, pair_name varchar2, pair_value number, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_value(), position);
    else 
      put(pair_name, json_value(pair_value), position);
    end if;
  end;
  
  member procedure put(self in out nocopy json, pair_name varchar2, pair_value boolean, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_value(), position);
    else 
      put(pair_name, json_value(pair_value), position);
    end if;
  end;
  
  member procedure check_duplicate(self in out nocopy json, v_set boolean) as
  begin
    if(v_set) then 
      check_for_duplicate := 1;
    else 
      check_for_duplicate := 0;
    end if;
  end; 

  /* deprecated putters */
 
  member procedure put(self in out nocopy json, pair_name varchar2, pair_value json, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_value(), position);
    else 
      put(pair_name, pair_value.to_json_value, position);
    end if;
  end;

  member procedure put(self in out nocopy json, pair_name varchar2, pair_value json_list, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_value(), position);
    else 
      put(pair_name, pair_value.to_json_value, position);
    end if;
  end;

  /* Member getter methods */ 
  member function count return number as
  begin
    return self.json_data.count;
  end;

  member function get(pair_name varchar2) return json_value as
    indx pls_integer;
  begin
    indx := json_data.first;
    loop
      exit when indx is null;
      if(pair_name is null and json_data(indx).mapname is null) then return json_data(indx); end if;
      if(json_data(indx).mapname = pair_name) then return json_data(indx); end if;
      indx := json_data.next(indx);
    end loop;
    return null;
  end;
  
  member function get(position pls_integer) return json_value as
  begin
    if(self.count >= position and position > 0) then
      return self.json_data(position);
    end if;
    return null; -- do not throw error, just return null
  end;
  
  member function index_of(pair_name varchar2) return number as
    indx pls_integer;
  begin
    indx := json_data.first;
    loop
      exit when indx is null;
      if(pair_name is null and json_data(indx).mapname is null) then return indx; end if;
      if(json_data(indx).mapname = pair_name) then return indx; end if;
      indx := json_data.next(indx);
    end loop;
    return -1;
  end;

  member function exist(pair_name varchar2) return boolean as
  begin
    return (self.get(pair_name) is not null);
  end;
  
  /* Output methods */  
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin
    if(spaces is null) then
      return json_printer.pretty_print(self, line_length => chars_per_line);
    else 
      return json_printer.pretty_print(self, spaces, line_length => chars_per_line);
    end if;
  end;

  member procedure to_clob(self in json, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true) as
  begin
    if(spaces is null) then	
      json_printer.pretty_print(self, false, buf, line_length => chars_per_line, erase_clob => erase_clob);
    else 
      json_printer.pretty_print(self, spaces, buf, line_length => chars_per_line, erase_clob => erase_clob);
    end if;
  end;

  member procedure print(self in json, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null) as --32512 is the real maximum in sqldeveloper
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    json_printer.pretty_print(self, spaces, my_clob, case when (chars_per_line>32512) then 32512 else chars_per_line end);
    json_printer.dbms_output_clob(my_clob, json_printer.newline_char, jsonp);
    dbms_lob.freetemporary(my_clob);  
  end;
  
  member procedure htp(self in json, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null) as 
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    json_printer.pretty_print(self, spaces, my_clob, chars_per_line);
    json_printer.htp_output_clob(my_clob, jsonp);
    dbms_lob.freetemporary(my_clob);  
  end;

  member function to_json_value return json_value as
  begin
    return json_value(sys.anydata.convertobject(self));
  end;

  /* json path */
  member function path(json_path varchar2, base number default 1) return json_value as
  begin
    return json_ext.get_json_value(self, json_path, base);
  end path;

  /* json path_put */
  member procedure path_put(self in out nocopy json, json_path varchar2, elem json_value, base number default 1) as
  begin
    json_ext.put(self, json_path, elem, base);
  end path_put;
  
  member procedure path_put(self in out nocopy json, json_path varchar2, elem varchar2, base number default 1) as
  begin
    json_ext.put(self, json_path, elem, base);
  end path_put;
  
  member procedure path_put(self in out nocopy json, json_path varchar2, elem number, base number default 1) as
  begin
    if(elem is null) then 
      json_ext.put(self, json_path, json_value(), base);
    else 
      json_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_put(self in out nocopy json, json_path varchar2, elem boolean, base number default 1) as
  begin
    if(elem is null) then 
      json_ext.put(self, json_path, json_value(), base);
    else 
      json_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_put(self in out nocopy json, json_path varchar2, elem json_list, base number default 1) as
  begin
    if(elem is null) then 
      json_ext.put(self, json_path, json_value(), base);
    else 
      json_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_put(self in out nocopy json, json_path varchar2, elem json, base number default 1) as
  begin
    if(elem is null) then 
      json_ext.put(self, json_path, json_value(), base);
    else 
      json_ext.put(self, json_path, elem, base);
    end if;
  end path_put;
  
  member procedure path_remove(self in out nocopy json, json_path varchar2, base number default 1) as
  begin 
    json_ext.remove(self, json_path, base);
  end path_remove;

  /* Thanks to Matt Nolan */
  member function get_keys return json_list as
    keys json_list;
    indx pls_integer;
  begin
    keys := json_list();
    indx := json_data.first;
    loop
      exit when indx is null;
      keys.append(json_data(indx).mapname);
      indx := json_data.next(indx);
    end loop;
    return keys;
  end;
  
  member function get_values return json_list as
    vals json_list := json_list();
  begin
    vals.list_data := self.json_data;
    return vals;
  end;
  
  member procedure remove_duplicates(self in out nocopy json) as
  begin
    json_parser.remove_duplicates(self);
  end remove_duplicates;


end;
/ 
sho err
