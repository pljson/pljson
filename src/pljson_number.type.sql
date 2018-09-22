create or replace type pljson_number force under pljson_element
(
  num number,
  num_double binary_double, -- both num and num_double are set, there is never exception (until Oracle 12c)
  num_repr_number_p varchar2(1),
  num_repr_double_p varchar2(1),
  
  constructor function pljson_number(num number) return self as result,
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  constructor function pljson_number(num_double binary_double) return self as result,
  overriding member function is_number return boolean,
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2,
  
  overriding member function get_number return number,
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  overriding member function get_double return binary_double,
  
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers, is_number is still true, extra info */
  /* return true if 'number' is representable by Oracle number */
  /** Private method for internal processing. */
  overriding member function is_number_repr_number return boolean,
  /* return true if 'number' is representable by Oracle binary_double */
  /** Private method for internal processing. */
  overriding member function is_number_repr_double return boolean,
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  -- set value for number from string representation; to replace to_number in pljson_parser
  -- can automatically decide and use binary_double if needed
  -- less confusing than new constructor with dummy argument for overloading
  -- centralized parse_number to use everywhere else and replace code in pljson_parser
  -- this procedure is meant to be used internally only
  -- procedure does not work correctly if called standalone in locales that
  -- use a character other than "." for decimal point
  member procedure parse_number(str varchar2),

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  -- this procedure is meant to be used internally only
  member function number_toString return varchar2
) not final
/
show err

create or replace type body pljson_number as

 constructor function pljson_number(num number) return self as result as
  begin
    self.typeval := 4;
    self.num := nvl(num, 0);
    /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers; typeval not changed, it is still json number */
    self.num_repr_number_p := 't';
    self.num_double := num;
    if (to_number(self.num_double) = self.num) then
      self.num_repr_double_p := 't';
    else
      self.num_repr_double_p := 'f';
    end if;
    return;
  end;
  
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers; typeval not changed, it is still json number */
  constructor function pljson_number(num_double binary_double) return self as result as
  begin
    self.typeval := 4;
    self.num_double := nvl(num_double, 0);
    self.num_repr_double_p := 't';
    self.num := num_double;
    if (to_binary_double(self.num) = self.num_double) then
      self.num_repr_number_p := 't';
    else
      self.num_repr_number_p := 'f';
    end if;
    return;
  end;
  
  overriding member function is_number return boolean as
  begin
    return true;
  end;
  
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    return self.num;
  end;
  
  overriding member function get_number return number as
  begin
    return self.num;
  end;
  
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers */
  overriding member function get_double return binary_double as
  begin
    return self.num_double;
  end;
  
  /* E.I.Sarmas (github.com/dsnz)   2016-11-03   support for binary_double numbers, is_number is still true, extra check */
  /* return true if 'number' is representable by Oracle number */
  overriding member function is_number_repr_number return boolean is
  begin
    return (num_repr_number_p = 't');
  end;
  
  /* return true if 'number' is representable by Oracle binary_double */
  overriding member function is_number_repr_double return boolean is
  begin
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
end;
/
show err