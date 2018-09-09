create or replace type pljson_string force under pljson_element (
  
  num number,
  str varchar2(32767),
  extended_str clob,
  
  constructor function pljson_string(str varchar2, esc boolean default true) return self as result,
  constructor function pljson_string(str clob, esc boolean default true) return self as result,
  overriding member function is_string return boolean,
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2,
  
  overriding member function get_string(max_byte_size number default null, max_char_size number default null) return varchar2,
  overriding member function get_clob return clob
  /*
  member procedure get_string(buf in out nocopy clob)
  */
) not final
/
show err

create or replace type body pljson_string as
  
  constructor function pljson_string(str varchar2, esc boolean default true) return self as result as
  begin
    self.typeval := 3;
    if (esc) then self.num := 1; else self.num := 0; end if; --message to pretty printer
    self.str := str;
    return;
  end;

  constructor function pljson_string(str clob, esc boolean default true) return self as result as
    /* E.I.Sarmas (github.com/dsnz)   2016-01-21   limit to 5000 chars */
    amount number := 5000; /* for Unicode text, varchar2 'self.str' not exceed 5000 chars, does not limit size of data */
  begin
    self.typeval := 3;
    if (esc) then self.num := 1; else self.num := 0; end if; --message to pretty printer
    if(dbms_lob.getlength(str) > amount) then
      self.extended_str := str;
    end if;
    -- GHS 20120615: Added IF structure to handle null clobs
    if dbms_lob.getlength(str) > 0 then
      dbms_lob.read(str, amount, 1, self.str);
    end if;
    return;
  end;
  
  overriding member function is_string return boolean as
  begin
    return true;
  end;
  
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    return get_string(max_byte_size, max_char_size);
  end;
  
  overriding member function get_string(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    if (max_byte_size is not null) then
      return substrb(self.str, 1, max_byte_size);
    elsif (max_char_size is not null) then
      return substr(self.str, 1, max_char_size);
    else
      return self.str;
    end if;
  end;
  
  overriding member function get_clob return clob as
  begin
    if(extended_str is not null) then
      --dbms_lob.copy(buf, extended_str, dbms_lob.getlength(extended_str));
      return self.extended_str;
    else
      --dbms_lob.writeappend(buf, length(self.str), self.str);
      return self.str;
    end if;
  end;
  
  /*
  member procedure get_string(buf in out nocopy clob) as
  begin
    if (extended_str is not null) then
      dbms_lob.copy(buf, extended_str, dbms_lob.getlength(extended_str));
    else
      dbms_lob.writeappend(buf, length(self.str), self.str);
    end if;
  end;
  */
end;
/
show err