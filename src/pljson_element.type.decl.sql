create or replace type pljson_path_segment as object (
  indx number(32),
  name varchar2(4000)
) final
/

create or replace type pljson_path as table of pljson_path_segment
/

create or replace type pljson_element force as object
(
  /* 1 = object, 2 = array, 3 = string, 4 = number, 5 = bool, 6 = null */
  typeval number(1),
  mapname varchar2(4000),
  mapindx number(32),
  object_id number,

  /* not instantiable */
  constructor function pljson_element return self as result,

  member function is_object return boolean,
  member function is_array return boolean,
  member function is_string return boolean,
  member function is_number return boolean,
  member function is_bool return boolean,
  member function is_null return boolean,
  member function get_type return varchar2,
  /* should be overriden */
  member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2,

  /*
    member methods to remove need for treat()
  */
  member function get_string(max_byte_size number default null, max_char_size number default null) return varchar2,
  member function get_clob return clob,
  member function get_number return number,
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  member function get_double return binary_double,
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers, is_number is still true, extra info */
  /* return true if 'number' is representable by Oracle number */
  /** Private method for internal processing. */
  member function is_number_repr_number return boolean,
  /* return true if 'number' is representable by Oracle binary_double */
  /** Private method for internal processing. */
  member function is_number_repr_double return boolean,
  member function get_bool return boolean,

  member function count return number,
  member function get(pair_name varchar2) return pljson_element,
  member function get(position pls_integer) return pljson_element,

  member function path(json_path varchar2, base number default 1) return pljson_element,

  /** Private method for internal processing. */
  member procedure get_internal_path(self in pljson_element, path pljson_path, path_position pls_integer, ret out nocopy pljson_element),

  /* output methods */
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2,
  member procedure to_clob(self in pljson_element, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true),
  member procedure print(self in pljson_element, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null),
  member procedure htp(self in pljson_element, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null),

  /** Private method for internal processing. */
  member function put_internal_path(self in out nocopy pljson_element, path pljson_path, elem pljson_element, path_position pls_integer) return boolean
) not final
/
show err

create or replace type pljson_element_array as table of pljson_element
/