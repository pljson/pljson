create or replace type body pljson as

  /* constructors */
  constructor function pljson return self as result as
  begin
    self.json_data := pljson_element_array();
    self.typeval := 1;
    self.check_for_duplicate := 1;
    
    --self.object_id := pljson_object_cache.next_id;
    return;
  end;

  constructor function pljson(str varchar2) return self as result as
  begin
    self := pljson_parser.parser(str);
    --self.typeval := 1;
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function pljson(str in clob) return self as result as
  begin
    self := pljson_parser.parser(str);
    --self.typeval := 1;
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function pljson(str in blob, charset varchar2 default 'UTF8') return self as result as
    c_str clob;
  begin
    pljson_ext.blob2clob(str, c_str, charset);
    self := pljson_parser.parser(c_str);
    dbms_lob.freetemporary(c_str);
    --self.typeval := 1;
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function pljson(str_array pljson_varray) return self as result as
    new_pair boolean := True;
    pair_name varchar2(32767);
    pair_value varchar2(32767);
  begin
    self.typeval := 1;
    self.check_for_duplicate := 1;
    self.json_data := pljson_element_array();
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
    
    --self.object_id := pljson_object_cache.next_id;
    return;
  end;

  constructor function pljson(elem pljson_element) return self as result as
  begin
    self := treat(elem as pljson);
    --self.typeval := 1;
    self.check_for_duplicate := 1;
    return;
  end;

  constructor function pljson(l pljson_list) return self as result as
  begin
    self.typeval := 1;
    self.check_for_duplicate := 1;
    self.json_data := pljson_element_array();
    for i in 1 .. l.list_data.count loop
      self.json_data.extend(1);
      self.json_data(i) := l.list_data(i);
      if (l.list_data(i).mapname is null or l.list_data(i).mapname like 'row%') then
        self.json_data(i).mapname := 'row'||i;
      end if;
      self.json_data(i).mapindx := i;
    end loop;
    
    --self.object_id := pljson_object_cache.next_id;
    return;
  end;

  overriding member function is_object return boolean as
  begin
    return true;
  end;

  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    return 'json object';
  end;

  /* member management */
  member procedure remove(self in out nocopy pljson, pair_name varchar2) as
    temp pljson_element;
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

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson_element, position pls_integer default null) as
    insert_value pljson_element;
    indx pls_integer; x number;
    temp pljson_element;
  begin
    --dbms_output.put_line('name: ' || pair_name);

    --if (pair_name is null) then
    --  raise_application_error(-20102, 'JSON put-method type error: name cannot be null');
    --end if;
    insert_value := pair_value;
    if insert_value is null then
      insert_value := pljson_null();
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
    put(pair_name, pljson_string(pair_value), position);
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value clob, position pls_integer default null) as
  begin
    put(pair_name, pljson_string(pair_value), position);
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value number, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_null(), position);
    else
      put(pair_name, pljson_number(pair_value), position);
    end if;
  end;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value binary_double, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_null(), position);
    else
      put(pair_name, pljson_number(pair_value), position);
    end if;
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value boolean, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_null(), position);
    else
      put(pair_name, pljson_bool(pair_value), position);
    end if;
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_null(), position);
    else
      put(pair_name, treat(pair_value as pljson_element), position);
    end if;
  end;

  member procedure put(self in out nocopy pljson, pair_name varchar2, pair_value pljson_list, position pls_integer default null) as
  begin
    if (pair_value is null) then
      put(pair_name, pljson_null(), position);
    else
      put(pair_name, treat(pair_value as pljson_element), position);
    end if;
  end;

  overriding member function count return number as
  begin
    return self.json_data.count;
  end;

  overriding member function get(pair_name varchar2) return pljson_element as
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
    elem pljson_element := get(pair_name);
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
    elem pljson_element := get(pair_name);
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
    elem pljson_element := get(pair_name);
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
    elem pljson_element := get(pair_name);
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
    elem pljson_element := get(pair_name);
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
    elem pljson_element := get(pair_name);
  begin
    /*
    if elem is not null and elem is of (pljson) then
      return treat(elem as pljson);
    end if;
    return null;
    */
    return treat(elem as pljson);
  end;

  member function get_pljson_list(pair_name varchar2) return pljson_list as
    elem pljson_element := get(pair_name);
  begin
    /*
    if elem is not null and elem is of (pljson_list) then
      return treat(elem as pljson_list);
    end if;
    return null;
    */
    return treat(elem as pljson_list);
  end;

  overriding member function get(position pls_integer) return pljson_element as
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

  /* json path */
  overriding member function path(json_path varchar2, base number default 1) return pljson_element as
  begin
    return pljson_ext.get_json_element(self, json_path, base);
  end path;

  /** Private method for internal processing. */
  overriding member procedure get_internal_path(self in pljson, path pljson_path, path_position pls_integer, ret out nocopy pljson_element) as
    indx pls_integer := path(path_position).indx;
  begin
    indx := path(path_position).indx;

    if (indx is null) then
      indx := self.json_data.first;
      loop
        exit when indx is null;

        if ((path(path_position).name is null and self.json_data(indx).mapname is null) or
            (self.json_data(indx).mapname = path(path_position).name))
        then
          if (path_position < path.count) then
            self.json_data(indx).get_internal_path(path, path_position + 1, ret);
          else
            ret := self.json_data(indx);
          end if;

          exit;
        end if;

        indx := self.json_data.next(indx);
      end loop;
    else
      if (indx <= self.json_data.count) then
        if (path_position < path.count) then
          self.json_data(indx).get_internal_path(path, path_position + 1, ret);
        else
          ret := self.json_data(indx);
        end if;
      end if;
    end if;
  end;

  /* json path_put */
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson_element, base number default 1) as
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
      pljson_ext.put(self, json_path, pljson_null(), base);
    else
      pljson_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem binary_double, base number default 1) as
  begin
    if (elem is null) then
      pljson_ext.put(self, json_path, pljson_null(), base);
    else
      pljson_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem boolean, base number default 1) as
  begin
    if (elem is null) then
      pljson_ext.put(self, json_path, pljson_null(), base);
    else
      pljson_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson_list, base number default 1) as
  begin
    if (elem is null) then
      pljson_ext.put(self, json_path, pljson_null(), base);
    else
      pljson_ext.put(self, json_path, elem, base);
    end if;
  end path_put;

  member procedure path_put(self in out nocopy pljson, json_path varchar2, elem pljson, base number default 1) as
  begin
    if (elem is null) then
      pljson_ext.put(self, json_path, pljson_null(), base);
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

  /** Private method for internal processing. */
  overriding member function put_internal_path(self in out nocopy pljson, path pljson_path, elem pljson_element, path_position pls_integer) return boolean as
    indx pls_integer;
    keystring varchar2(4000);
    new_obj pljson;
    new_list pljson_list;
    ret boolean := false;
  begin
    if (path(path_position).indx is null) then
      keystring := path(path_position).name;
    else
      if (path(path_position).indx > self.json_data.count) then
        if (elem is null) then
          return false;
        end if;
        raise_application_error(-20110, 'PLJSON_EXT put error: access object with too few members.');
      end if;

      keystring := self.json_data(path(path_position).indx).mapname;
    end if;

    indx := self.json_data.first;
    loop
      exit when indx is null;

      if ((keystring is null and self.json_data(indx).mapname is null) or (self.json_data(indx).mapname = keystring)) then
        if (path_position < path.count) then
          if (path(path_position + 1).indx is null) then
            if (not self.json_data(indx).is_object()) then
              if (elem is not null) then
                put(keystring, pljson());
              else
                return false;
              end if;
            end if;
          else
            if (not self.json_data(indx).is_object() and not self.json_data(indx).is_array()) then
              if (elem is not null) then
                put(keystring, pljson_list());
              else
                return false;
              end if;
            end if;
          end if;

          if (self.json_data(indx).put_internal_path(path, elem, path_position + 1)) then
            self.remove(keystring);
            return true;
          end if;
        else
          if (elem is null) then
            self.remove(keystring);
            return true;
          else
            self.put(keystring, elem);
          end if;
        end if;

        return false;
      end if;

      indx := self.json_data.next(indx);
    end loop;

    if (elem is not null) then
      if (path_position = path.count) then
        put(keystring, elem);
      else
        if (path(path_position + 1).indx is null) then
          new_obj := pljson();
          ret := new_obj.put_internal_path(path, elem, path_position + 1);
          put(keystring, new_obj);
        else
          new_list := pljson_list();
          ret := new_list.put_internal_path(path, elem, path_position + 1);
          put(keystring, new_list);
        end if;
      end if;
    end if;

    return ret;
  end;
end;
/
show err