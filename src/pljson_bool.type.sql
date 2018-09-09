create or replace type pljson_bool force under pljson_element (
  
  num number(1),
  
  constructor function pljson_bool (b in boolean) return self as result,
  overriding member function is_bool return boolean,
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2,
  
  overriding member function get_bool return boolean
) not final
/
show err

create or replace type body pljson_bool as
  
  constructor function pljson_bool (b in boolean) return self as result as
  begin
    self.typeval := 5;
    self.num := 0;
    if b then self.num := 1; end if;
    return;
  end;
  
  overriding member function is_bool return boolean as
  begin
    return true;
  end;
  
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    if self.num = 1 then return 'true'; else return 'false'; end if;
  end;
  
  overriding member function get_bool return boolean as
  begin
    return self.num = 1;
  end;
end;
/
show err