
create or replace
type body json_value as

  constructor function json_value(object_or_array sys.anydata) return self as result as
  begin
    case object_or_array.gettypename
      when sys_context('userenv', 'current_schema')||'.JSON_LIST' then self.typeval := 2;
      when sys_context('userenv', 'current_schema')||'.JSON' then self.typeval := 1;
      else raise_application_error(-20102, 'JSON_Value init error (JSON or JSON\_List allowed)');
    end case;
    self.object_or_array := object_or_array;
    if(self.object_or_array is null) then self.typeval := 6; end if;
    
    return;
  end json_value;

  constructor function json_value(str varchar2, esc boolean default true) return self as result as
  begin
    self.typeval := 3;
    if(esc) then self.num := 1; else self.num := 0; end if; --message to pretty printer
    self.str := str;
    return;
  end json_value;

  constructor function json_value(str clob, esc boolean default true) return self as result as
    amount number := 5000; /* for Unicode text, all text/loops max 5000 CHAR) */
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
  end json_value;

  constructor function json_value(num number) return self as result as
  begin
    self.typeval := 4;
    self.num := num;
    if(self.num is null) then self.typeval := 6; end if;
    return;
  end json_value;

  constructor function json_value(b boolean) return self as result as
  begin
    self.typeval := 5;
    self.num := 0;
    if(b) then self.num := 1; end if;
    if(b is null) then self.typeval := 6; end if;
    return;
  end json_value;

  constructor function json_value return self as result as
  begin
    self.typeval := 6; /* for JSON null */
    return;
  end json_value;

  static function makenull return json_value as
  begin
    return json_value;
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
  
  member procedure get_string(self in json_value, buf in out nocopy clob) as
  begin
    if(self.typeval = 3) then 
      if(extended_str is not null) then
        dbms_lob.copy(buf, extended_str, dbms_lob.getlength(extended_str));
      else
        dbms_lob.writeappend(buf, length(self.str), self.str);      
      end if;
    end if;
  end get_string;


  member function get_number return number as
  begin
    if(self.typeval = 4) then 
      return self.num;
    end if;
    return null;
  end get_number;

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

  /* Output methods */  
  member function to_char(spaces boolean default true, chars_per_line number default 0) return varchar2 as
  begin
    if(spaces is null) then
      return json_printer.pretty_print_any(self, line_length => chars_per_line);
    else 
      return json_printer.pretty_print_any(self, spaces, line_length => chars_per_line);
    end if;
  end;

  member procedure to_clob(self in json_value, buf in out nocopy clob, spaces boolean default false, chars_per_line number default 0, erase_clob boolean default true) as
  begin
    if(spaces is null) then	
      json_printer.pretty_print_any(self, false, buf, line_length => chars_per_line, erase_clob => erase_clob);
    else 
      json_printer.pretty_print_any(self, spaces, buf, line_length => chars_per_line, erase_clob => erase_clob);
    end if;
  end;

  member procedure print(self in json_value, spaces boolean default true, chars_per_line number default 8192, jsonp varchar2 default null) as --32512 is the real maximum in sqldeveloper
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    json_printer.pretty_print_any(self, spaces, my_clob, case when (chars_per_line>32512) then 32512 else chars_per_line end);
    json_printer.dbms_output_clob(my_clob, json_printer.newline_char, jsonp);
    dbms_lob.freetemporary(my_clob);  
  end;
  
  member procedure htp(self in json_value, spaces boolean default false, chars_per_line number default 0, jsonp varchar2 default null) as 
    my_clob clob;
  begin
    my_clob := empty_clob();
    dbms_lob.createtemporary(my_clob, true);
    json_printer.pretty_print_any(self, spaces, my_clob, chars_per_line);
    json_printer.htp_output_clob(my_clob, jsonp);
    dbms_lob.freetemporary(my_clob);  
  end;

  member function value_of(self in json_value, max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    case self.typeval
    when 1 then return 'json object';
    when 2 then return 'json array';
    when 3 then return self.get_string(max_byte_size,max_char_size);
    when 4 then return self.get_number();
    when 5 then if(self.get_bool()) then return 'true'; else return 'false'; end if;
    else return null;
    end case;
  end;

end;
/

sho err
