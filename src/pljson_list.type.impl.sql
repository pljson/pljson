create or replace type body pljson_list as

  /* constructors */
  constructor function pljson_list return self as result as
  begin
    self.typeval := 2;
    self.list_data := pljson_element_array();
    return;
  end;

  constructor function pljson_list(str varchar2) return self as result as
  begin
    self.typeval := 2;
    self := pljson_parser.parse_list(str);
    return;
  end;

  constructor function pljson_list(str clob) return self as result as
  begin
    self.typeval := 2;
    self := pljson_parser.parse_list(str);
    return;
  end;

  constructor function pljson_list(str blob, charset varchar2 default 'UTF8') return self as result as
    c_str clob;
  begin
    self.typeval := 2;
    pljson_ext.blob2clob(str, c_str, charset);
    self := pljson_parser.parse_list(c_str);
    dbms_lob.freetemporary(c_str);
    return;
  end;

  constructor function pljson_list(str_array pljson_varray) return self as result as
  begin
    self.typeval := 2;
    self.list_data := pljson_element_array();
    for i in str_array.FIRST .. str_array.LAST loop
      append(str_array(i));
    end loop;
    return;
  end;

  constructor function pljson_list(num_array pljson_narray) return self as result as
  begin
    self.typeval := 2;
    self.list_data := pljson_element_array();
    for i in num_array.FIRST .. num_array.LAST loop
      append(num_array(i));
    end loop;
    return;
  end;
  
  constructor function pljson_list(elem pljson_element) return self as result as
  begin
    self.typeval := 2;
    self := treat(elem as pljson_list);
    return;
  end;

  overriding member function is_array return boolean as
  begin
    return true;
  end;

  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    return 'json array';
  end;

  /* list management */
  member procedure append(self in out nocopy pljson_list, elem pljson_element, position pls_integer default null) as
    indx pls_integer;
    insert_value pljson_element;
  begin
    insert_value := elem;
    if insert_value is null then
      insert_value := pljson_null();
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
    append(pljson_string(elem), position);
  end;

  member procedure append(self in out nocopy pljson_list, elem clob, position pls_integer default null) as
  begin
    append(pljson_string(elem), position);
  end;

  member procedure append(self in out nocopy pljson_list, elem number, position pls_integer default null) as
  begin
    if (elem is null) then
      append(pljson_null(), position);
    else
      append(pljson_number(elem), position);
    end if;
  end;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure append(self in out nocopy pljson_list, elem binary_double, position pls_integer default null) as
  begin
    if (elem is null) then
      append(pljson_null(), position);
    else
      append(pljson_number(elem), position);
    end if;
  end;

  member procedure append(self in out nocopy pljson_list, elem boolean, position pls_integer default null) as
  begin
    if (elem is null) then
      append(pljson_null(), position);
    else
      append(pljson_bool(elem), position);
    end if;
  end;

  member procedure append(self in out nocopy pljson_list, elem pljson_list, position pls_integer default null) as
  begin
    if (elem is null) then
      append(pljson_null(), position);
    else
      append(treat(elem as pljson_element), position);
    end if;
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem pljson_element) as
    insert_value pljson_element;
    indx number;
  begin
    insert_value := elem;
    if insert_value is null then
      insert_value := pljson_null();
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
    replace(position, pljson_string(elem));
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem clob) as
  begin
    replace(position, pljson_string(elem));
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem number) as
  begin
    if (elem is null) then
      replace(position, pljson_null());
    else
      replace(position, pljson_number(elem));
    end if;
  end;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem binary_double) as
  begin
    if (elem is null) then
      replace(position, pljson_null());
    else
      replace(position, pljson_number(elem));
    end if;
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem boolean) as
  begin
    if (elem is null) then
      replace(position, pljson_null());
    else
      replace(position, pljson_bool(elem));
    end if;
  end;

  member procedure replace(self in out nocopy pljson_list, position pls_integer, elem pljson_list) as
  begin
    if (elem is null) then
      replace(position, pljson_null());
    else
      replace(position, elem);
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

  member function get(position pls_integer) return pljson_element as
  begin
    if (self.count >= position and position > 0) then
      return self.list_data(position);
    end if;
    return null; -- do not throw error, just return null
  end;

  member function get_string(position pls_integer) return varchar2 as
    elem pljson_element := get(position);
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
    elem pljson_element := get(position);
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
    elem pljson_element := get(position);
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
    elem pljson_element := get(position);
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
    elem pljson_element := get(position);
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
    elem pljson_element := get(position);
  begin
    /*
    if elem is not null and elem is of (pljson_list) then
      return treat(elem as pljson_list);
    end if;
    return null;
    */
    return treat(elem as pljson_list);
  end;

  member function head return pljson_element as
  begin
    if (self.count > 0) then
      return self.list_data(self.list_data.first);
    end if;
    return null; -- do not throw error, just return null
  end;

  member function last return pljson_element as
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
      t := self; --pljson_list(self);
      t.remove(1);
      return t;
    else
      return pljson_list();
    end if;
  end;

  /* json path */
  member function path(json_path varchar2, base number default 1) return pljson_element as
    cp pljson_list := self;
  begin
    return pljson_ext.get_json_element(pljson(cp), json_path, base);
  end path;

  /* json path_put */
  member procedure path_put(self in out nocopy pljson_list, json_path varchar2, elem pljson_element, base number default 1) as
    objlist pljson;
    jp pljson_list := pljson_ext.parsePath(json_path, base);
  begin
    while (jp.head().get_number() > self.count) loop
      self.append(pljson_null());
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
      self.append(pljson_null());
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
      self.append(pljson_null());
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
      self.append(pljson_null());
    end loop;

    objlist := pljson(self);
    if (elem is null) then
      pljson_ext.put(objlist, json_path, pljson_null(), base);
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
      self.append(pljson_null());
    end loop;

    objlist := pljson(self);
    if (elem is null) then
      pljson_ext.put(objlist, json_path, pljson_null(), base);
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
      self.append(pljson_null());
    end loop;

    objlist := pljson(self);
    if (elem is null) then
      pljson_ext.put(objlist, json_path, pljson_null(), base);
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
      self.append(pljson_null());
    end loop;

    objlist := pljson(self);
    if (elem is null) then
      pljson_ext.put(objlist, json_path, pljson_null(), base);
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
end;
/
show err