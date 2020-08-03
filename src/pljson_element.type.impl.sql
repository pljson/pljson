create or replace type body pljson_element as

  constructor function pljson_element return self as result as
  begin
    raise_application_error(-20000, 'pljson_element is not instantiable');
  end;

  /* all the is_ methods can
    test against typeval or
    return false and be overriden in children
  */
  member function is_object return boolean as
  begin
    return false;
  end;

  member function is_array return boolean as
  begin
    return false;
  end;

  member function is_string return boolean as
  begin
    return false;
  end;

  member function is_number return boolean as
  begin
    return false;
  end;

  member function is_bool return boolean as
  begin
    return false;
  end;

  member function is_null return boolean as
  begin
    return false;
  end;

  member function get_type return varchar2 as
  begin
    case self.typeval
      when 1 then return 'object';
      when 2 then return 'array';
      when 3 then return 'string';
      when 4 then return 'number';
      when 5 then return 'bool';
      when 6 then return 'null';
    end case;

    return 'unknown type';
  end;

  member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    raise_application_error(-20002, 'value_of() method should be overriden');
  end;

  /*
    member methods to remove need for treat()
  */
  member function get_string(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    raise_application_error(-20003, 'get_string() method is not supported by object of type:'  || get_type());
  end;

  member function get_clob return clob as
  begin
    raise_application_error(-20004, 'get_clob() method is not supported by object of type:'  || get_type());
  end;

  member function get_number return number as
  begin
    raise_application_error(-20005, 'get_number() method is not supported by object of type:'  || get_type());
  end;

  member function get_double return binary_double as
  begin
    raise_application_error(-20006, 'get_double() method is not supported by object of type:'  || get_type());
  end;

  member function is_number_repr_number return boolean as
  begin
    raise_application_error(-20008, 'is_number_repr_number() method is not supported by object of type:'  || get_type());
  end;

  member function is_number_repr_double return boolean as
  begin
    raise_application_error(-20009, 'is_number_repr_double() method is not supported by object of type:'  || get_type());
  end;

  member function get_bool return boolean as
  begin
    raise_application_error(-20007, 'get_bool() method is not supported by object of type:'  || get_type());
  end;

  member function count return number as
  begin
    raise_application_error(-20012, 'count() method is not supported by object of type:'  || get_type());
  end;
  member function get(pair_name varchar2) return pljson_element as
  begin
    raise_application_error(-20020, 'get(name) method is not supported by object of type:'  || get_type());
  end;
  member function get(position pls_integer) return pljson_element as
  begin
    raise_application_error(-20021, 'get(position) method is not supported by object of type:'  || get_type());
  end;

  member function path(json_path varchar2, base number default 1) return pljson_element as
  begin
    raise_application_error(-20010, 'path() method is not supported by object of type:'  || get_type());
  end;

  /** Private method for internal processing. */
  member procedure get_internal_path(self in pljson_element, path pljson_path, path_position pls_integer, ret out nocopy pljson_element) as
  begin
    raise_application_error(-20010, 'path() method is not supported by object of type:'  || get_type());
  end;

  /* output methods */
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin
    if (spaces is null) then
      return pljson_printer.pretty_print_any(self, line_length => chars_per_line);
    else
      return pljson_printer.pretty_print_any(self, spaces, line_length => chars_per_line);
    end if;
  end;

  member procedure to_clob(self in pljson_element, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true) as
  begin
    if (spaces is null) then
      pljson_printer.pretty_print_any(self, false, buf, line_length => chars_per_line, erase_clob => erase_clob);
    else
      pljson_printer.pretty_print_any(self, spaces, buf, line_length => chars_per_line, erase_clob => erase_clob);
    end if;
  end;

  member procedure print(self in pljson_element, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null) as --32512 is the real maximum in sqldeveloper
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    pljson_printer.pretty_print_any(self, spaces, my_clob, case when (chars_per_line>32512) then 32512 else chars_per_line end);
    pljson_printer.dbms_output_clob(my_clob, pljson_printer.newline_char, jsonp);
    dbms_lob.freetemporary(my_clob);
  end;

  member procedure htp(self in pljson_element, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null) as
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    pljson_printer.pretty_print_any(self, spaces, my_clob, chars_per_line);
    pljson_printer.htp_output_clob(my_clob, jsonp);
    dbms_lob.freetemporary(my_clob);
  end;

  /** Private method for internal processing. */
  member function put_internal_path(self in out nocopy pljson_element, path pljson_path, elem pljson_element, path_position pls_integer) return boolean as
  begin
    return false;
  end;
end;
/
show err