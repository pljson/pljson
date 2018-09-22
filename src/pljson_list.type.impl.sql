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

create or replace type body pljson_list as

  /* constructors */
  constructor function pljson_list return self as result as
  begin
    self.list_data := pljson_value_array();
    return;
  end;

  constructor function pljson_list(str varchar2) return self as result as
  begin
    self := pljson_parser.parse_list(str);
    return;
  end;

  constructor function pljson_list(str clob) return self as result as
  begin
    self := pljson_parser.parse_list(str);
    return;
  end;

  constructor function pljson_list(str blob, charset varchar2 default 'UTF8') return self as result as
    c_str clob;
  begin
    pljson_ext.blob2clob(str, c_str, charset);
    self := pljson_parser.parse_list(c_str);
    dbms_lob.freetemporary(c_str);
    return;
  end;

  constructor function pljson_list(str_array pljson_varray) return self as result as
  begin
    self.list_data := pljson_value_array();
    for i in str_array.FIRST .. str_array.LAST loop
      append(str_array(i));
    end loop;
    return;
  end;

  constructor function pljson_list(num_array pljson_narray) return self as result as
  begin
    self.list_data := pljson_value_array();
    for i in num_array.FIRST .. num_array.LAST loop
      append(num_array(i));
    end loop;
    return;
  end;

  constructor function pljson_list(elem pljson_value) return self as result as
  begin
    self := treat(elem.object_or_array as pljson_list);
    return;
  end;

  /* list management */
  member procedure append(self in out nocopy pljson_list, elem pljson_value, position pls_integer default null) as
    indx pls_integer;
    insert_value pljson_value;
  begin
    insert_value := elem;
    if insert_value is null then
      insert_value := pljson_value();
    end if;
    if (position is null or position > self.count) then --end of list
      indx := self.count + 1;
      self.list_data.extend(1);
      self.list_data(indx) := insert_value;
    elsif (position < 1) then --new first
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

  member procedure append(self in out nocopy pljson_list, elem varchar2, position pls_integer default null) as
  begin
    append(pljson_value(elem), position);
  end;

  member procedure append(self in out nocopy pljson_list, elem clob, position pls_integer default null) as
  begin
    append(pljson_value(elem), position);
  end;

  member procedure append(self in out nocopy pljson_list, elem number, position pls_integer default null) as
  begin
    if (elem is null) then
      append(pljson_value(), position);
    else
      append(pljson_value(elem), position);
    end if;
  end;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure append(self in out nocopy pljson_list, elem binary_double, position pls_integer default null) as
  begin
    if (elem is null) then
      append(pljson_value(), position);
    else
      append(pljson_value(elem), position);
    end if;
  end;

  member procedure append(self in out nocopy pljson_list, elem boolean, position pls_integer default null) as
  begin
    if (elem is null) then
      append(pljson_value(), position);
    else
      append(pljson_value(elem), position);
    end if;
  end;

  member procedure append(self in out nocopy pljson_list, elem pljson_list, position pls_integer default null) as
  begin
    if (elem is null) then
      append(pljson_value(), position);
    else
      append(elem.to_json_value, position);
    end if;
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem pljson_value) as
    insert_value pljson_value;
    indx number;
  begin
    insert_value := elem;
    if insert_value is null then
      insert_value := pljson_value();
    end if;
    if (position > self.count) then --end of list
      indx := self.count + 1;
      self.list_data.extend(1);
      self.list_data(indx) := insert_value;
    elsif (position < 1) then --maybe an error message here
      null;
    else
      self.list_data(position) := insert_value;
    end if;
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem varchar2) as
  begin
    replace(position, pljson_value(elem));
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem clob) as
  begin
    replace(position, pljson_value(elem));
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem number) as
  begin
    if (elem is null) then
      replace(position, pljson_value());
    else
      replace(position, pljson_value(elem));
    end if;
  end;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem binary_double) as
  begin
    if (elem is null) then
      replace(position, pljson_value());
    else
      replace(position, pljson_value(elem));
    end if;
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem boolean) as
  begin
    if (elem is null) then
      replace(position, pljson_value());
    else
      replace(position, pljson_value(elem));
    end if;
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem pljson_list) as
  begin
    if (elem is null) then
      replace(position, pljson_value());
    else
      replace(position, elem.to_json_value);
    end if;
  end;

  member procedure remove(self in out nocopy pljson_list, position pls_integer) as
  begin
    if (position is null or position < 1 or position > self.count) then return; end if;
    for x in (position+1) .. self.count loop
      self.list_data(x-1) := self.list_data(x);
    end loop;
    self.list_data.trim(1);
  end;

  member procedure remove_first(self in out nocopy pljson_list) as
  begin
    for x in 2 .. self.count loop
      self.list_data(x-1) := self.list_data(x);
    end loop;
    if (self.count > 0) then
      self.list_data.trim(1);
    end if;
  end;

  member procedure remove_last(self in out nocopy pljson_list) as
  begin
    if (self.count > 0) then
      self.list_data.trim(1);
    end if;
  end;

  member function count return number as
  begin
    return self.list_data.count;
  end;

  member function get(position pls_integer) return pljson_value as
  begin
    if (self.count >= position and position > 0) then
      return self.list_data(position);
    end if;
    return null; -- do not throw error, just return null
  end;

  member function get_string(position pls_integer) return varchar2 as
    elem pljson_value := get(position);
  begin
    /*
    if elem is not null and elem is of (pljson_string) then
      return elem.get_string();
    end if;
    return null;
    */
    return elem.get_string();
  end;

  member function get_clob(position pls_integer) return clob as
    elem pljson_value := get(position);
  begin
    /*
    if elem is not null and elem is of (pljson_string) then
      return elem.get_clob();
    end if;
    return null;
    */
    return elem.get_clob();
  end;

  member function get_number(position pls_integer) return number as
    elem pljson_value := get(position);
  begin
    /*
    if elem is not null and elem is of (pljson_number) then
      return elem.get_number();
    end if;
    return null;
    */
    return elem.get_number();
  end;

  member function get_double(position pls_integer) return binary_double as
    elem pljson_value := get(position);
  begin
    /*
    if elem is not null and elem is of (pljson_number) then
      return elem.get_double();
    end if;
    return null;
    */
    return elem.get_double();
  end;

  member function get_bool(position pls_integer) return boolean as
    elem pljson_value := get(position);
  begin
    /*
    if elem is not null and elem is of (pljson_bool) then
      return elem.get_bool();
    end if;
    return null;
    */
    return elem.get_bool();
  end;

  member function get_pljson_list(position pls_integer) return pljson_list as
    elem pljson_value := get(position);
  begin
    /*
    if elem is not null and elem is of (pljson_list) then
      return treat(elem as pljson_list);
    end if;
    return null;
    */
    return treat(elem.object_or_array as pljson_list);
  end;

  member function head return pljson_value as
  begin
    if (self.count > 0) then
      return self.list_data(self.list_data.first);
    end if;
    return null; -- do not throw error, just return null
  end;

  member function last return pljson_value as
  begin
    if (self.count > 0) then
      return self.list_data(self.list_data.last);
    end if;
    return null; -- do not throw error, just return null
  end;

  member function tail return pljson_list as
    t pljson_list;
  begin
    if (self.count > 0) then
      t := self; --pljson_list(self.to_json_value);
      t.remove(1);
      return t;
    else
      return pljson_list();
    end if;
  end;

  member function to_json_value return pljson_value as
  begin
    return pljson_value(self);
  end;

  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin
    if (spaces is null) then
      return pljson_printer.pretty_print_list(self, line_length => chars_per_line);
    else
      return pljson_printer.pretty_print_list(self, spaces, line_length => chars_per_line);
    end if;
  end;

  member procedure to_clob(self in pljson_list, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true) as
  begin
    if (spaces is null) then
      pljson_printer.pretty_print_list(self, false, buf, line_length => chars_per_line, erase_clob => erase_clob);
    else
      pljson_printer.pretty_print_list(self, spaces, buf, line_length => chars_per_line, erase_clob => erase_clob);
    end if;
  end;

  member procedure print(self in pljson_list, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null) as --32512 is the real maximum in sqldeveloper
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    pljson_printer.pretty_print_list(self, spaces, my_clob, case when (chars_per_line>32512) then 32512 else chars_per_line end);
    pljson_printer.dbms_output_clob(my_clob, pljson_printer.newline_char, jsonp);
    dbms_lob.freetemporary(my_clob);
  end;

  member procedure htp(self in pljson_list, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null) as
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    pljson_printer.pretty_print_list(self, spaces, my_clob, chars_per_line);
    pljson_printer.htp_output_clob(my_clob, jsonp);
    dbms_lob.freetemporary(my_clob);
  end;

  /* json path */
  member function path(json_path varchar2, base number default 1) return pljson_value as
    cp pljson_list := self;
  begin
    return pljson_ext.get_json_value(pljson(cp), json_path, base);
  end path;


  /* json path_put */
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem pljson_value, base number default 1) as
    objlist pljson;
    jp pljson_list := pljson_ext.parsePath(json_path, base);
  begin
    while (jp.head().get_number() > self.count) loop
      self.append(pljson_value());
    end loop;

    objlist := pljson(self);
    pljson_ext.put(objlist, json_path, elem, base);
    self := objlist.get_values;
  end path_put;

  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem varchar2, base number default 1) as
    objlist pljson;
    jp pljson_list := pljson_ext.parsePath(json_path, base);
  begin
    while (jp.head().get_number() > self.count) loop
      self.append(pljson_value());
    end loop;

    objlist := pljson(self);
    pljson_ext.put(objlist, json_path, elem, base);
    self := objlist.get_values;
  end path_put;

  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem clob, base number default 1) as
    objlist pljson;
    jp pljson_list := pljson_ext.parsePath(json_path, base);
  begin
    while (jp.head().get_number() > self.count) loop
      self.append(pljson_value());
    end loop;

    objlist := pljson(self);
    pljson_ext.put(objlist, json_path, elem, base);
    self := objlist.get_values;
  end path_put;

  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem number, base number default 1) as
    objlist pljson;
    jp pljson_list := pljson_ext.parsePath(json_path, base);
  begin
    while (jp.head().get_number() > self.count) loop
      self.append(pljson_value());
    end loop;

    objlist := pljson(self);
    if (elem is null) then
      pljson_ext.put(objlist, json_path, pljson_value(), base);
    else
      pljson_ext.put(objlist, json_path, elem, base);
    end if;
    self := objlist.get_values;
  end path_put;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem binary_double, base number default 1) as
    objlist pljson;
    jp pljson_list := pljson_ext.parsePath(json_path, base);
  begin
    while (jp.head().get_number() > self.count) loop
      self.append(pljson_value());
    end loop;

    objlist := pljson(self);
    if (elem is null) then
      pljson_ext.put(objlist, json_path, pljson_value(), base);
    else
      pljson_ext.put(objlist, json_path, elem, base);
    end if;
    self := objlist.get_values;
  end path_put;

  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem boolean, base number default 1) as
    objlist pljson;
    jp pljson_list := pljson_ext.parsePath(json_path, base);
  begin
    while (jp.head().get_number() > self.count) loop
      self.append(pljson_value());
    end loop;

    objlist := pljson(self);
    if (elem is null) then
      pljson_ext.put(objlist, json_path, pljson_value(), base);
    else
      pljson_ext.put(objlist, json_path, elem, base);
    end if;
    self := objlist.get_values;
  end path_put;

  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem pljson_list, base number default 1) as
    objlist pljson;
    jp pljson_list := pljson_ext.parsePath(json_path, base);
  begin
    while (jp.head().get_number() > self.count) loop
      self.append(pljson_value());
    end loop;

    objlist := pljson(self);
    if (elem is null) then
      pljson_ext.put(objlist, json_path, pljson_value(), base);
    else
      pljson_ext.put(objlist, json_path, elem, base);
    end if;
    self := objlist.get_values;
  end path_put;

  /* json path_remove */
  member procedure path_remove(self in out nocopy pljson_list, json_path varchar2, base number default 1) as
    objlist pljson := pljson(self);
  begin
    pljson_ext.remove(objlist, json_path, base);
    self := objlist.get_values;
  end path_remove;

  /* --backwards compatibility
  member procedure add_elem(self in out nocopy json_list, elem json_value, position pls_integer default null) as begin append(elem,position); end;
  member procedure add_elem(self in out nocopy json_list, elem varchar2, position pls_integer default null) as begin append(elem,position); end;
  member procedure add_elem(self in out nocopy json_list, elem number, position pls_integer default null) as begin append(elem,position); end;
  member procedure add_elem(self in out nocopy json_list, elem boolean, position pls_integer default null) as begin append(elem,position); end;
  member procedure add_elem(self in out nocopy json_list, elem json_list, position pls_integer default null) as begin append(elem,position); end;

  member procedure set_elem(self in out nocopy json_list, position pls_integer, elem json_value) as begin replace(position,elem); end;
  member procedure set_elem(self in out nocopy json_list, position pls_integer, elem varchar2) as begin replace(position,elem); end;
  member procedure set_elem(self in out nocopy json_list, position pls_integer, elem number) as begin replace(position,elem); end;
  member procedure set_elem(self in out nocopy json_list, position pls_integer, elem boolean) as begin replace(position,elem); end;
  member procedure set_elem(self in out nocopy json_list, position pls_integer, elem json_list) as begin replace(position,elem); end;

  member procedure remove_elem(self in out nocopy json_list, position pls_integer) as begin remove(position); end;
  member function get_elem(position pls_integer) return json_value as begin return get(position); end;
  member function get_first return json_value as begin return head(); end;
  member function get_last return json_value as begin return last(); end;
--*/

end;
/
show err