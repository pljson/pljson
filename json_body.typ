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
    self.num_elements := 0;
    self.json_data := json_member_array();
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function json(str varchar2) return self as result as
  begin
    self := json_parser.parser(str);
    self.check_for_duplicate := 1;
    return;
  end;
  
  constructor function json(str clob) return self as result as
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

  member procedure put(pair_name varchar2, pair_value json_value, position pls_integer default null) as
    insert_value json_value := nvl(pair_value, json_value);
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

--    self.remove(pair_name);
    if(self.check_for_duplicate = 1) then temp := get_member(pair_name); else temp := null; end if;
    if(temp is not null) then
      json_data(temp.id).member_data := insert_value;
      return;
    elsif(position is null or position > self.count) then
      --insert at the end of the list
      --dbms_output.put_line('Test');
      indx := self.count + 1;
      json_data.extend;
      json_data(indx) := json_member(indx, pair_name, insert_value);
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
      json_data(1) := json_member(1, pair_name, insert_value);
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
      json_data(position) := json_member(position, pair_name, insert_value);
    end if;
    num_elements := num_elements + 1;
  end;
  
  member procedure put(pair_name varchar2, pair_value varchar2, position pls_integer default null) as
  begin
    put(pair_name, json_value(pair_value), position);
  end;
  
  member procedure put(pair_name varchar2, pair_value number, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_value(), position);
    else 
      put(pair_name, json_value(pair_value), position);
    end if;
  end;
  
  member procedure put(pair_name varchar2, pair_value boolean, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_value(), position);
    else 
      put(pair_name, json_value(pair_value), position);
    end if;
  end;
  
  member procedure check_duplicate(set boolean) as
  begin
    if(set) then 
      check_for_duplicate := 1;
    else 
      check_for_duplicate := 0;
    end if;
  end; 

  /* deprecated putters */
 
  member procedure put(pair_name varchar2, pair_value json, position pls_integer default null) as
  begin
    if(pair_value is null) then
      put(pair_name, json_value(), position);
    else 
      put(pair_name, pair_value.to_json_value, position);
    end if;
  end;

  member procedure put(pair_name varchar2, pair_value json_list, position pls_integer default null) as
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
    return self.num_elements;
  end;

  member function get(pair_name varchar2) return json_value as
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
  
  member function to_json_value return json_value as
  begin
    return json_value(anydata.convertobject(self));
  end;

end;
/ 
sho err
