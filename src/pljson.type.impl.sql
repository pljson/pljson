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

create or replace type body pljson as

  /* constructors */
  constructor function pljson return self as result as
  begin
    self.json_data := pljson_value_array();
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function pljson(str varchar2) return self as result as
  begin
    self := pljson_parser.parser(str);
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function pljson(str in clob) return self as result as
  begin
    self := pljson_parser.parser(str);
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function pljson(str in blob, charset varchar2 default 'UTF8') return self as result as
    c_str clob;
  begin
    pljson_ext.blob2clob(str, c_str, charset);
    self := pljson_parser.parser(c_str);
    self.check_for_duplicate := 1;
    dbms_lob.freetemporary(c_str);
    return;
  end;

  constructor function pljson(str_array pljson_varray) return self as result as
    new_pair boolean := True;
    pair_name varchar2(32767);
    pair_value varchar2(32767);
  begin
    self.json_data := pljson_value_array();
    self.check_for_duplicate := 1;
    for i in str_array.FIRST .. str_array.LAST loop
      if new_pair then
        pair_name := str_array(i);
        new_pair := False;
      else
        pair_value := str_array(i);
        put(pair_name, pair_value);
        new_pair := True;
      end if;
    end loop;
    return;
  end;

  constructor function pljson(elem pljson_value) return self as result as
  begin
    self := treat(elem.object_or_array as pljson);
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function pljson(l in out nocopy pljson_list) return self as result as
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

  /* member management */
  member procedure remove(self in out nocopy pljson, pair_name varchar2) as
    temp pljson_value;
    indx pls_integer;
  begin
    temp := get(pair_name);
    if (temp is null) then return; end if;

    indx := json_data.next(temp.mapindx);
    loop
      exit when indx is null;
      json_data(indx).mapindx := indx - 1;
      json_data(indx-1) := json_data(indx);
      indx := json_data.next(indx);
    end loop;
    json_data.trim(1);
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson_value, position pls_integer default null) as
    insert_value pljson_value;
    indx pls_integer; x number;
    temp pljson_value;
  begin
    --dbms_output.put_line('name: ' || pair_name);

    --if (pair_name is null) then
    --  raise_application_error(-20102, 'JSON put-method type error: name cannot be null');
    --end if;
    insert_value := pair_value;
    if insert_value is null then
      insert_value := pljson_value();
    end if;
    insert_value.mapname := pair_name;
    if (self.check_for_duplicate = 1) then temp := get(pair_name); else temp := null; end if;
    if (temp is not null) then
      insert_value.mapindx := temp.mapindx;
      json_data(temp.mapindx) := insert_value;
      return;
    elsif (position is null or position > self.count) then
      --insert at the end of the list
      --dbms_output.put_line('insert end');
      json_data.extend(1);
      /* changed to common style of updating mapindx; fix bug in assignment order */
      insert_value.mapindx := json_data.count;
      json_data(json_data.count) := insert_value;
      --dbms_output.put_line('mapindx: ' || insert_value.mapindx);
      --dbms_output.put_line('mapname: ' || insert_value.mapname);
    elsif (position < 2) then
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
      /* changed to common style of updating mapindx; fix bug in assignment order */
      insert_value.mapindx := 1;
      json_data(1) := insert_value;
    else
      --insert somewhere in the list
      indx := json_data.last;
      --dbms_output.put_line('indx: ' || indx);
      json_data.extend;
      loop
        --dbms_output.put_line('indx: ' || indx);
        temp := json_data(indx);
        temp.mapindx := indx + 1;
        json_data(temp.mapindx) := temp;
        exit when indx = position;
        indx := json_data.prior(indx);
      end loop;
      /* changed to common style of updating mapindx; fix bug in assignment order */
      insert_value.mapindx := position;
      json_data(position) := insert_value;
    end if;
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value varchar2, position pls_integer default null) as
  begin
    put(pair_name, pljson_value(pair_value), position);
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value clob, position pls_integer default null) as
  begin
    put(pair_name, pljson_value(pair_value), position);
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value number, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_value(), position);
    else
      put(pair_name, pljson_value(pair_value), position);
    end if;
  end;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value binary_double, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_value(), position);
    else
      put(pair_name, pljson_value(pair_value), position);
    end if;
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value boolean, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_value(), position);
    else
      put(pair_name, pljson_value(pair_value), position);
    end if;
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_value(), position);
    else
      put(pair_name, pair_value.to_json_value, position);
    end if;
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson_list, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_value(), position);
    else
      put(pair_name, pair_value.to_json_value, position);
    end if;
  end;

  member function count return number as
  begin
    return self.json_data.count;
  end;

  member function get(pair_name varchar2) return pljson_value as
    indx pls_integer;
  begin
    indx := json_data.first;
    loop
      exit when indx is null;
      if (pair_name is null and json_data(indx).mapname is null) then return json_data(indx); end if;
      if (json_data(indx).mapname = pair_name) then return json_data(indx); end if;
      indx := json_data.next(indx);
    end loop;
    return null;
  end;

  member function get_string(pair_name varchar2) return varchar2 as
    elem pljson_value := get(pair_name);
  begin
    /*
    if elem is not null and elem is of (pljson_string) then
      return elem.get_string();
    end if;
    return null;
    */
    return elem.get_string();
  end;

  member function get_clob(pair_name varchar2) return clob as
    elem pljson_value := get(pair_name);
  begin
    /*
    if elem is not null and elem is of (pljson_string) then
      return elem.get_clob();
    end if;
    return null;
    */
    return elem.get_clob();
  end;

  member function get_number(pair_name varchar2) return number as
    elem pljson_value := get(pair_name);
  begin
    /*
    if elem is not null and elem is of (pljson_number) then
      return elem.get_number();
    end if;
    return null;
    */
    return elem.get_number();
  end;

  member function get_double(pair_name varchar2) return binary_double as
    elem pljson_value := get(pair_name);
  begin
    /*
    if elem is not null and elem is of (pljson_number) then
      return elem.get_double();
    end if;
    return null;
    */
    return elem.get_double();
  end;

  member function get_bool(pair_name varchar2) return boolean as
    elem pljson_value := get(pair_name);
  begin
    /*
    if elem is not null and elem is of (pljson_bool) then
      return elem.get_bool();
    end if;
    return null;
    */
    return elem.get_bool();
  end;

  member function get_pljson(pair_name varchar2) return pljson as
    elem pljson_value := get(pair_name);
  begin
    /*
    if elem is not null and elem is of (pljson) then
      return treat(elem.object_or_array as pljson);
    end if;
    return null;
    */
    return treat(elem.object_or_array as pljson);
  end;

  member function get_pljson_list(pair_name varchar2) return pljson_list as
    elem pljson_value := get(pair_name);
  begin
    /*
    if elem is not null and elem is of (pljson_list) then
      return treat(elem.object_or_array as pljson_list);
    end if;
    return null;
    */
    return treat(elem.object_or_array as pljson_list);
  end;

  member function get(position pls_integer) return pljson_value as
  begin
    if (self.count >= position and position > 0) then
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
      if (pair_name is null and json_data(indx).mapname is null) then return indx; end if;
      if (json_data(indx).mapname = pair_name) then return indx; end if;
      indx := json_data.next(indx);
    end loop;
    return -1;
  end;

  member function exist(pair_name varchar2) return boolean as
  begin
    return (get(pair_name) is not null);
  end;

  member function to_json_value return pljson_value as
  begin
    return pljson_value(self);
  end;

  member procedure check_duplicate(self in out nocopy pljson, v_set boolean) as
  begin
    if (v_set) then
      check_for_duplicate := 1;
    else
      check_for_duplicate := 0;
    end if;
  end;

  member procedure remove_duplicates(self in out nocopy pljson) as
  begin
    pljson_parser.remove_duplicates(self);
  end remove_duplicates;

  /* output methods */
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin
    if(spaces is null) then
      return pljson_printer.pretty_print(self, line_length => chars_per_line);
    else
      return pljson_printer.pretty_print(self, spaces, line_length => chars_per_line);
    end if;
  end;

  member procedure to_clob(self in pljson, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true) as
  begin
    if(spaces is null) then
      pljson_printer.pretty_print(self, false, buf, line_length => chars_per_line, erase_clob => erase_clob);
    else
      pljson_printer.pretty_print(self, spaces, buf, line_length => chars_per_line, erase_clob => erase_clob);
    end if;
  end;

  member procedure print(self in pljson, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null) as --32512 is the real maximum in sqldeveloper
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    pljson_printer.pretty_print(self, spaces, my_clob, case when (chars_per_line>32512) then 32512 else chars_per_line end);
    pljson_printer.dbms_output_clob(my_clob, pljson_printer.newline_char, jsonp);
    dbms_lob.freetemporary(my_clob);
  end;

  member procedure htp(self in pljson, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null) as
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    pljson_printer.pretty_print(self, spaces, my_clob, chars_per_line);
    pljson_printer.htp_output_clob(my_clob, jsonp);
    dbms_lob.freetemporary(my_clob);
  end;

  /* json path */
  member function path(json_path varchar2, base number default 1) return pljson_value as
  begin
    return pljson_ext.get_json_value(self, json_path, base);
  end path;

  /* json path_put */
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson_value, base number default 1) as
  begin
    pljson_ext.put(self, json_path, elem, base);
  end path_put;

  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem varchar2, base number default 1) as
  begin
    pljson_ext.put(self, json_path, elem, base);
  end path_put;

  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem clob, base number default 1) as
  begin
    pljson_ext.put(self, json_path, elem, base);
  end path_put;

  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem number, base number default 1) as
  begin
    if (elem is null) then
      pljson_ext.put(self, json_path, pljson_value(), base);
    else
      pljson_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem binary_double, base number default 1) as
  begin
    if (elem is null) then
      pljson_ext.put(self, json_path, pljson_value(), base);
    else
      pljson_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem boolean, base number default 1) as
  begin
    if (elem is null) then
      pljson_ext.put(self, json_path, pljson_value(), base);
    else
      pljson_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson_list, base number default 1) as
  begin
    if (elem is null) then
      pljson_ext.put(self, json_path, pljson_value(), base);
    else
      pljson_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson, base number default 1) as
  begin
    if (elem is null) then
      pljson_ext.put(self, json_path, pljson_value(), base);
    else
      pljson_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_remove(self in out nocopy pljson, json_path varchar2, base number default 1) as
  begin
    pljson_ext.remove(self, json_path, base);
  end path_remove;

  /* Thanks to Matt Nolan */
  member function get_keys return pljson_list as
    keys pljson_list;
    indx pls_integer;
  begin
    keys := pljson_list();
    indx := json_data.first;
    loop
      exit when indx is null;
      keys.append(json_data(indx).mapname);
      indx := json_data.next(indx);
    end loop;
    return keys;
  end;

  member function get_values return pljson_list as
    vals pljson_list := pljson_list();
  begin
    vals.list_data := self.json_data;
    return vals;
  end;
end;
/
show err