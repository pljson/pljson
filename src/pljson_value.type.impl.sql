create or replace type body pljson_value as

  constructor function pljson_value(elem pljson_element) return self as result as
  begin
    case
      when elem is of (pljson)      then self.typeval := 1;
      when elem is of (pljson_list) then self.typeval := 2;
      else raise_application_error(-20102, 'PLJSON_VALUE init error (PLJSON or PLJSON_LIST allowed)');
    end case;
    self.object_or_array := elem;
    if(self.object_or_array is null) then self.typeval := 6; end if;

    return;
  end pljson_value;

  constructor function pljson_value(str varchar2, esc boolean default true) return self as result as
  begin
    self.typeval := 3;
    if(esc) then self.num := 1; else self.num := 0; end if; --message to pretty printer
    self.str := str;
    return;
  end pljson_value;

  constructor function pljson_value(str clob, esc boolean default true) return self as result as
    /* E.I.Sarmas (github.com/dsnz)   2016-01-21   limit to 5000 chars */
    amount number := 5000; /* for Unicode text, varchar2 'self.str' not exceed 5000 chars, does not limit size of data */
  begin
    self.typeval := 3;
    if(esc) then self.num := 1; else self.num := 0; end if; --message to pretty printer
    if(dbms_lob.getlength(str) > amount) then
      extended_str := str;
    end if;
    -- GHS 20120615: Added IF structure to handle null clobs
    if dbms_lob.getlength(str) > 0 then
      dbms_lob.read(str, amount, 1, self.str);
    end if;
    return;
  end pljson_value;

  constructor function pljson_value(num number) return self as result as
  begin
    self.typeval := 4;
    self.num := num;
    /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers; typeval not changed, it is still json number */
    self.num_repr_number_p := 't';
    self.num_double := num;
    if (to_number(self.num_double) = self.num) then
      self.num_repr_double_p := 't';
    else
      self.num_repr_double_p := 'f';
    end if;
    /* */
    if(self.num is null) then self.typeval := 6; end if;
    return;
  end pljson_value;

  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers; typeval not changed, it is still json number */
  constructor function pljson_value(num_double binary_double) return self as result as
  begin
    self.typeval := 4;
    self.num_double := num_double;
    self.num_repr_double_p := 't';
    self.num := num_double;
    if (to_binary_double(self.num) = self.num_double) then
      self.num_repr_number_p := 't';
    else
      self.num_repr_number_p := 'f';
    end if;
    if(self.num_double is null) then self.typeval := 6; end if;
    return;
  end pljson_value;

  constructor function pljson_value(b boolean) return self as result as
  begin
    self.typeval := 5;
    self.num := 0;
    if(b) then self.num := 1; end if;
    if(b is null) then self.typeval := 6; end if;
    return;
  end pljson_value;

  constructor function pljson_value return self as result as
  begin
    self.typeval := 6; /* for JSON null */
    return;
  end pljson_value;

  member function get_element return pljson_element as
  begin
    if (self.typeval in (1,2)) then
      return self.object_or_array;
    end if;
    return null;
  end get_element;

  static function makenull return pljson_value as
  begin
    return pljson_value;
  end makenull;

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
  end get_type;

  member function get_string(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    if(self.typeval = 3) then
      if(max_byte_size is not null) then
        return substrb(self.str,1,max_byte_size);
      elsif (max_char_size is not null) then
        return substr(self.str,1,max_char_size);
      else
        return self.str;
      end if;
    end if;
    return null;
  end get_string;

  member procedure get_string(self in pljson_value, buf in out nocopy clob) as
  begin
    if(self.typeval = 3) then
      if(extended_str is not null) then
        dbms_lob.copy(buf, extended_str, dbms_lob.getlength(extended_str));
      else
        dbms_lob.writeappend(buf, length(self.str), self.str);
      end if;
    end if;
  end get_string;

  member function get_clob return clob as
  begin
    if(self.typeval = 3) then
      if(extended_str is not null) then
        --dbms_lob.copy(buf, extended_str, dbms_lob.getlength(extended_str));
        return self.extended_str;
      else
        --dbms_lob.writeappend(buf, length(self.str), self.str);
        return self.str;
      end if;
    end if;
  end get_clob;

  member function get_number return number as
  begin
    if(self.typeval = 4) then
      return self.num;
    end if;
    return null;
  end get_number;

  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  member function get_double return binary_double as
  begin
    if(self.typeval = 4) then
      return self.num_double;
    end if;
    return null;
  end get_double;

  member function get_bool return boolean as
  begin
    if(self.typeval = 5) then
      return self.num = 1;
    end if;
    return null;
  end get_bool;

  member function get_null return varchar2 as
  begin
    if(self.typeval = 6) then
      return 'null';
    end if;
    return null;
  end get_null;

  member function is_object return boolean as begin return self.typeval = 1; end;
  member function is_array return boolean as begin return self.typeval = 2; end;
  member function is_string return boolean as begin return self.typeval = 3; end;
  member function is_number return boolean as begin return self.typeval = 4; end;
  member function is_bool return boolean as begin return self.typeval = 5; end;
  member function is_null return boolean as begin return self.typeval = 6; end;

  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers, is_number is still true, extra check */
  /* return true if 'number' is representable by Oracle number */
  member function is_number_repr_number return boolean is
  begin
    if self.typeval != 4 then
      return false;
    end if;
    return (num_repr_number_p = 't');
  end;

  /* return true if 'number' is representable by Oracle binary_double */
  member function is_number_repr_double return boolean is
  begin
    if self.typeval != 4 then
      return false;
    end if;
    return (num_repr_double_p = 't');
  end;

  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  -- set value for number from string representation; to replace to_number in pljson_parser
  -- can automatically decide and use binary_double if needed (set repr variables)
  -- underflows and overflows count as representable if happen on both type representations
  -- less confusing than new constructor with dummy argument for overloading
  -- centralized parse_number to use everywhere else and replace code in pljson_parser
  --
  -- WARNING:
  --
  -- procedure does not work correctly if called standalone in locales that
  -- use a character other than "." for decimal point
  --
  -- parse_number() is intended to be used inside pljson_parser which
  -- uses session NLS_PARAMETERS to get decimal point and
  -- changes "." to this decimal point before calling parse_number()
  --
  member procedure parse_number(str varchar2) is
  begin
    if self.typeval != 4 then
      return;
    end if;
    self.num := to_number(str);
    self.num_repr_number_p := 't';
    self.num_double := to_binary_double(str);
    self.num_repr_double_p := 't';
    if (to_binary_double(self.num) != self.num_double) then
      self.num_repr_number_p := 'f';
    end if;
    if (to_number(self.num_double) != self.num) then
      self.num_repr_double_p := 'f';
    end if;
  end parse_number;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  -- centralized toString to use everywhere else and replace code in pljson_printer
  member function number_toString return varchar2 is
    num number;
    num_double binary_double;
    buf varchar2(4000);
  begin
    /* unrolled, instead of using two nested fuctions for speed */
    if (self.num_repr_number_p = 't') then
      num := self.num;
      if (num > 1e127d) then
        return '1e309'; -- json representation of infinity !?
      end if;
      if (num < -1e127d) then
        return '-1e309'; -- json representation of infinity !?
      end if;
      buf := STANDARD.to_char(num, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
      if (-1 < num and num < 0 and substr(buf, 1, 2) = '-.') then
        buf := '-0' || substr(buf, 2);
      elsif (0 < num and num < 1 and substr(buf, 1, 1) = '.') then
        buf := '0' || buf;
      end if;
      return buf;
    else
      num_double := self.num_double;
      if (num_double = +BINARY_DOUBLE_INFINITY) then
        return '1e309'; -- json representation of infinity !?
      end if;
      if (num_double = -BINARY_DOUBLE_INFINITY) then
        return '-1e309'; -- json representation of infinity !?
      end if;
      buf := STANDARD.to_char(num_double, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
      if (-1 < num_double and num_double < 0 and substr(buf, 1, 2) = '-.') then
        buf := '-0' || substr(buf, 2);
      elsif (0 < num_double and num_double < 1 and substr(buf, 1, 1) = '.') then
        buf := '0' || buf;
      end if;
      return buf;
    end if;
  end number_toString;

  /* Output methods */
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin
    if(spaces is null) then
      return pljson_printer.pretty_print_any(self, line_length => chars_per_line);
    else
      return pljson_printer.pretty_print_any(self, spaces, line_length => chars_per_line);
    end if;
  end;

  member procedure to_clob(self in pljson_value, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true) as
  begin
    if(spaces is null) then
      pljson_printer.pretty_print_any(self, false, buf, line_length => chars_per_line, erase_clob => erase_clob);
    else
      pljson_printer.pretty_print_any(self, spaces, buf, line_length => chars_per_line, erase_clob => erase_clob);
    end if;
  end;

  member procedure print(self in pljson_value, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null) as --32512 is the real maximum in sqldeveloper
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    pljson_printer.pretty_print_any(self, spaces, my_clob, case when (chars_per_line>32512) then 32512 else chars_per_line end);
    pljson_printer.dbms_output_clob(my_clob, pljson_printer.newline_char, jsonp);
    dbms_lob.freetemporary(my_clob);
  end;

  member procedure htp(self in pljson_value, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null) as
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    pljson_printer.pretty_print_any(self, spaces, my_clob, chars_per_line);
    pljson_printer.htp_output_clob(my_clob, jsonp);
    dbms_lob.freetemporary(my_clob);
  end;

  member function value_of(self in pljson_value, max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    case self.typeval
    when 1 then return 'json object';
    when 2 then return 'json array';
    when 3 then return self.get_string(max_byte_size, max_char_size);
    when 4 then return self.get_number();
    when 5 then if(self.get_bool()) then return 'true'; else return 'false'; end if;
    else return null;
    end case;
  end;

end;
/
sho err