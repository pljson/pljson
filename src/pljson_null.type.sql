create or replace type pljson_null force under pljson_element
(
  constructor function pljson_null return self as result,
  overriding member function is_null return boolean,
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2
) not final
/
show err

create or replace type body pljson_null as
  
  constructor function pljson_null return self as result as
  begin
    self.typeval := 6;
    return;
  end;
  
  overriding member function is_null return boolean as
  begin
    return true;
  end;
  
  overriding member function value_of(max_byte_size number default null, max_char_size number default null) return varchar2 as
  begin
    return 'null';
  end;
end;
/
show err