create or replace package pljson_ac as
  --json type methods
  
  procedure object_remove(p_self in out nocopy pljson, pair_name varchar2);
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value pljson_value, position pls_integer default null);
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value varchar2, position pls_integer default null);
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value number, position pls_integer default null);
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value binary_double, position pls_integer default null);
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value boolean, position pls_integer default null);
  procedure object_check_duplicate(p_self in out nocopy pljson, v_set boolean);
  procedure object_remove_duplicates(p_self in out nocopy pljson);
  
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value pljson, position pls_integer default null);
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value pljson_list, position pls_integer default null);
  
  function object_count(p_self in pljson) return number;
  function object_get(p_self in pljson, pair_name varchar2) return pljson_value;
  function object_get(p_self in pljson, position pls_integer) return pljson_value;
  function object_index_of(p_self in pljson, pair_name varchar2) return number;
  function object_exist(p_self in pljson, pair_name varchar2) return boolean;
  
  function object_to_char(p_self in pljson, spaces boolean default true, chars_per_line number default 0) return varchar2;
  procedure object_to_clob(p_self in pljson, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true);
  procedure object_print(p_self in pljson, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null);
  procedure object_htp(p_self in pljson, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null);
  
  function object_to_json_value(p_self in pljson) return pljson_value;
  function object_path(p_self in pljson, json_path varchar2, base number default 1) return pljson_value;
  
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem pljson_value, base number default 1);
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem varchar2  , base number default 1);
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem number    , base number default 1);
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem binary_double, base number default 1);
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem boolean   , base number default 1);
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem pljson_list , base number default 1);
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem pljson      , base number default 1);
  
  procedure object_path_remove(p_self in out nocopy pljson, json_path varchar2, base number default 1);
  
  function object_get_values(p_self in pljson) return pljson_list;
  function object_get_keys(p_self in pljson) return pljson_list;
  
  --json_list type methods
  procedure array_append(p_self in out nocopy pljson_list, elem pljson_value, position pls_integer default null);
  procedure array_append(p_self in out nocopy pljson_list, elem varchar2, position pls_integer default null);
  procedure array_append(p_self in out nocopy pljson_list, elem number, position pls_integer default null);
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure array_append(p_self in out nocopy pljson_list, elem binary_double, position pls_integer default null);
  procedure array_append(p_self in out nocopy pljson_list, elem boolean, position pls_integer default null);
  procedure array_append(p_self in out nocopy pljson_list, elem pljson_list, position pls_integer default null);
  
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem pljson_value);
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem varchar2);
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem number);
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem binary_double);
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem boolean);
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem pljson_list);
  
  function array_count(p_self in pljson_list) return number;
  procedure array_remove(p_self in out nocopy pljson_list, position pls_integer);
  procedure array_remove_first(p_self in out nocopy pljson_list);
  procedure array_remove_last(p_self in out nocopy pljson_list);
  function array_get(p_self in pljson_list, position pls_integer) return pljson_value;
  function array_head(p_self in pljson_list) return pljson_value;
  function array_last(p_self in pljson_list) return pljson_value;
  function array_tail(p_self in pljson_list) return pljson_list;
  
  function array_to_char(p_self in pljson_list, spaces boolean default true, chars_per_line number default 0) return varchar2;
  procedure array_to_clob(p_self in pljson_list, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true);
  procedure array_print(p_self in pljson_list, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null);
  procedure array_htp(p_self in pljson_list, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null);
  
  function array_path(p_self in pljson_list, json_path varchar2, base number default 1) return pljson_value;
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem pljson_value, base number default 1);
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem varchar2  , base number default 1);
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem number    , base number default 1);
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem binary_double, base number default 1);
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem boolean   , base number default 1);
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem pljson_list , base number default 1);
  
  procedure array_path_remove(p_self in out nocopy pljson_list, json_path varchar2, base number default 1);
  
  function array_to_json_value(p_self in pljson_list) return pljson_value;
  
  --json_value
  
  
  function jv_get_type(p_self in pljson_value) return varchar2;
  function jv_get_string(p_self in pljson_value, max_byte_size number default null, max_char_size number default null) return varchar2;
  procedure jv_get_string(p_self in pljson_value, buf in out nocopy clob);
  function jv_get_number(p_self in pljson_value) return number;
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  function jv_get_double(p_self in pljson_value) return binary_double;
  function jv_get_bool(p_self in pljson_value) return boolean;
  function jv_get_null(p_self in pljson_value) return varchar2;
  
  function jv_is_object(p_self in pljson_value) return boolean;
  function jv_is_array(p_self in pljson_value) return boolean;
  function jv_is_string(p_self in pljson_value) return boolean;
  function jv_is_number(p_self in pljson_value) return boolean;
  function jv_is_bool(p_self in pljson_value) return boolean;
  function jv_is_null(p_self in pljson_value) return boolean;
  
  function jv_to_char(p_self in pljson_value, spaces boolean default true, chars_per_line number default 0) return varchar2;
  procedure jv_to_clob(p_self in pljson_value, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true);
  procedure jv_print(p_self in pljson_value, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null);
  procedure jv_htp(p_self in pljson_value, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null);
  
  function jv_value_of(p_self in pljson_value, max_byte_size number default null, max_char_size number default null) return varchar2;


end pljson_ac;
/

create or replace package body pljson_ac as
  procedure object_remove(p_self in out nocopy pljson, pair_name varchar2) as
  begin p_self.remove(pair_name); end;
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value pljson_value, position pls_integer default null) as
  begin p_self.put(pair_name, pair_value, position); end;
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value varchar2, position pls_integer default null) as
  begin p_self.put(pair_name, pair_value, position); end;
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value number, position pls_integer default null) as
  begin p_self.put(pair_name, pair_value, position); end;
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value binary_double, position pls_integer default null) as
  begin p_self.put(pair_name, pair_value, position); end;
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value boolean, position pls_integer default null) as
  begin p_self.put(pair_name, pair_value, position); end;
  procedure object_check_duplicate(p_self in out nocopy pljson, v_set boolean) as
  begin p_self.check_duplicate(v_set); end;
  procedure object_remove_duplicates(p_self in out nocopy pljson) as
  begin p_self.remove_duplicates; end;
  
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value pljson, position pls_integer default null) as
  begin p_self.put(pair_name, pair_value, position); end;
  procedure object_put(p_self in out nocopy pljson, pair_name varchar2, pair_value pljson_list, position pls_integer default null) as
  begin p_self.put(pair_name, pair_value, position); end;
  
  function object_count(p_self in pljson) return number as
  begin return p_self.count; end;
  function object_get(p_self in pljson, pair_name varchar2) return pljson_value as
  begin return p_self.get(pair_name); end;
  function object_get(p_self in pljson, position pls_integer) return pljson_value as
  begin return p_self.get(position); end;
  function object_index_of(p_self in pljson, pair_name varchar2) return number as
  begin return p_self.index_of(pair_name); end;
  function object_exist(p_self in pljson, pair_name varchar2) return boolean as
  begin return p_self.exist(pair_name); end;
  
  function object_to_char(p_self in pljson, spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin return p_self.to_char(spaces, chars_per_line); end;
  procedure object_to_clob(p_self in pljson, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true) as
  begin p_self.to_clob(buf, spaces, chars_per_line, erase_clob); end;
  procedure object_print(p_self in pljson, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null) as
  begin p_self.print(spaces, chars_per_line, jsonp); end;
  procedure object_htp(p_self in pljson, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null) as
  begin p_self.htp(spaces, chars_per_line, jsonp); end;
  
  function object_to_json_value(p_self in pljson) return pljson_value as
  begin return p_self.to_json_value; end;
  function object_path(p_self in pljson, json_path varchar2, base number default 1) return pljson_value as
  begin return p_self.path(json_path, base); end;
  
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem pljson_value, base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem varchar2  , base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem number    , base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem binary_double, base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem boolean   , base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem pljson_list , base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  procedure object_path_put(p_self in out nocopy pljson, json_path varchar2, elem pljson      , base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  
  procedure object_path_remove(p_self in out nocopy pljson, json_path varchar2, base number default 1) as
  begin p_self.path_remove(json_path, base); end;
  
  function object_get_values(p_self in pljson) return pljson_list as
  begin return p_self.get_values; end;
  function object_get_keys(p_self in pljson) return pljson_list as
  begin return p_self.get_keys; end;
  
  --json_list type
  procedure array_append(p_self in out nocopy pljson_list, elem pljson_value, position pls_integer default null) as
  begin p_self.append(elem, position); end;
  procedure array_append(p_self in out nocopy pljson_list, elem varchar2, position pls_integer default null) as
  begin p_self.append(elem, position); end;
  procedure array_append(p_self in out nocopy pljson_list, elem number, position pls_integer default null) as
  begin p_self.append(elem, position); end;
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure array_append(p_self in out nocopy pljson_list, elem binary_double, position pls_integer default null) as
  begin p_self.append(elem, position); end;
  procedure array_append(p_self in out nocopy pljson_list, elem boolean, position pls_integer default null) as
  begin p_self.append(elem, position); end;
  procedure array_append(p_self in out nocopy pljson_list, elem pljson_list, position pls_integer default null) as
  begin p_self.append(elem, position); end;
  
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem pljson_value) as
  begin p_self.replace(position, elem); end;
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem varchar2) as
  begin p_self.replace(position, elem); end;
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem number) as
  begin p_self.replace(position, elem); end;
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem binary_double) as
  begin p_self.replace(position, elem); end;
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem boolean) as
  begin p_self.replace(position, elem); end;
  procedure array_replace(p_self in out nocopy pljson_list, position pls_integer, elem pljson_list) as
  begin p_self.replace(position, elem); end;
  
  function array_count(p_self in pljson_list) return number as
  begin return p_self.count; end;
  procedure array_remove(p_self in out nocopy pljson_list, position pls_integer) as
  begin p_self.remove(position); end;
  procedure array_remove_first(p_self in out nocopy pljson_list) as
  begin p_self.remove_first; end;
  procedure array_remove_last(p_self in out nocopy pljson_list) as
  begin p_self.remove_last; end;
  function array_get(p_self in pljson_list, position pls_integer) return pljson_value as
  begin return p_self.get(position); end;
  function array_head(p_self in pljson_list) return pljson_value as
  begin return p_self.head; end;
  function array_last(p_self in pljson_list) return pljson_value as
  begin return p_self.last; end;
  function array_tail(p_self in pljson_list) return pljson_list as
  begin return p_self.tail; end;
  
  function array_to_char(p_self in pljson_list, spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin return p_self.to_char(spaces, chars_per_line); end;
  procedure array_to_clob(p_self in pljson_list, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true) as
  begin p_self.to_clob(buf, spaces, chars_per_line, erase_clob); end;
  procedure array_print(p_self in pljson_list, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null) as
  begin p_self.print(spaces, chars_per_line, jsonp); end;
  procedure array_htp(p_self in pljson_list, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null) as
  begin p_self.htp(spaces, chars_per_line, jsonp); end;
  
  function array_path(p_self in pljson_list, json_path varchar2, base number default 1) return pljson_value as
  begin return p_self.path(json_path, base); end;
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem pljson_value, base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem varchar2  , base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem number    , base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem binary_double, base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem boolean   , base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  procedure array_path_put(p_self in out nocopy pljson_list, json_path varchar2, elem pljson_list , base number default 1) as
  begin p_self.path_put(json_path, elem, base); end;
  
  procedure array_path_remove(p_self in out nocopy pljson_list, json_path varchar2, base number default 1) as
  begin p_self.path_remove(json_path, base); end;
  
  function array_to_json_value(p_self in pljson_list) return pljson_value as
  begin return p_self.to_json_value; end;
  
  --json_value
  
  
  function jv_get_type(p_self in pljson_value) return varchar2 as
  begin return p_self.get_type; end;
  function jv_get_string(p_self in pljson_value, max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin return p_self.get_string(max_byte_size, max_char_size); end;
  procedure jv_get_string(p_self in pljson_value, buf in out nocopy clob) as
  begin p_self.get_string(buf); end;
  function jv_get_number(p_self in pljson_value) return number as
  begin return p_self.get_number; end;
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  function jv_get_double(p_self in pljson_value) return binary_double as
  begin return p_self.get_double; end;
  function jv_get_bool(p_self in pljson_value) return boolean as
  begin return p_self.get_bool; end;
  function jv_get_null(p_self in pljson_value) return varchar2 as
  begin return p_self.get_null; end;
  
  function jv_is_object(p_self in pljson_value) return boolean as
  begin return p_self.is_object; end;
  function jv_is_array(p_self in pljson_value) return boolean as
  begin return p_self.is_array; end;
  function jv_is_string(p_self in pljson_value) return boolean as
  begin return p_self.is_string; end;
  function jv_is_number(p_self in pljson_value) return boolean as
  begin return p_self.is_number; end;
  function jv_is_bool(p_self in pljson_value) return boolean as
  begin return p_self.is_bool; end;
  function jv_is_null(p_self in pljson_value) return boolean as
  begin return p_self.is_null; end;
  
  function jv_to_char(p_self in pljson_value, spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin return p_self.to_char(spaces, chars_per_line); end;
  procedure jv_to_clob(p_self in pljson_value, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true) as
  begin p_self.to_clob(buf, spaces, chars_per_line, erase_clob); end;
  procedure jv_print(p_self in pljson_value, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null) as
  begin p_self.print(spaces, chars_per_line, jsonp); end;
  procedure jv_htp(p_self in pljson_value, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null) as
  begin p_self.htp(spaces, chars_per_line, jsonp); end;
  
  function jv_value_of(p_self in pljson_value, max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin return p_self.value_of(max_byte_size, max_char_size); end;

end pljson_ac;
/
