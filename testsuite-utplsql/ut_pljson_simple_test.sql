
create or replace package ut_pljson_simple_test is
  
  --%suite(pljson simple test)
  --%suitepath(core)
  
  --%test(Test Bool)
  procedure test_bool;
  
  --%test(Test Null)  
  procedure test_null;
  
  --%test(Test very small number, issue #69)  
  procedure test_very_small_number;
  
  --%test(Test parser/printer number/binary_double handling, issue #70) 
  procedure test_binary_double;

end ut_pljson_simple_test;
/

create or replace package body ut_pljson_simple_test is
  
  EOL varchar2(10) := chr(13);
  
  -- INDENT_1 varchar2(10) := '  ';
  INDENT_2 varchar2(10) := '  ';
  
  procedure pass(test_name varchar2 := null) as
  begin
    if (test_name is not null) then
      dbms_output.put_line(INDENT_2 || 'OK: '|| test_name);
    end if;
    --ut.expect(true, str).to_be_true;
  end;
  
  procedure fail(test_name varchar2 := null) as
  begin
    if (test_name is not null) then
      dbms_output.put_line(INDENT_2 || 'FAILED: '|| test_name);
    end if;
    ut.fail(test_name);
    --ut.expect(true, str).to_be_true;
  end;
  
  procedure assertTrue(b boolean, test_name varchar2 := null) as
  begin
    if (b) then
      pass(test_name);
    else
      fail(test_name);
    end if;
  end;
  
  procedure assertFalse(b boolean, test_name varchar2 := null) as
  begin
    if (not b) then
      pass(test_name);
    else
      fail(test_name);
    end if;
  end;
  
  -- Bool
  procedure test_bool is
    obj pljson_value;
  begin
    obj := pljson_value(true);
    assertTrue(obj.get_bool, 'obj.get_bool');
    assertFalse(not obj.get_bool, 'not obj.get_bool');
    assertTrue(pljson_printer.pretty_print_any(obj) = 'true', 'pljson_printer.pretty_print_any(obj) = ''true''');
    obj := pljson_value(false);
    assertFalse(obj.get_bool, 'obj.get_bool');
    assertTrue(not obj.get_bool, 'not obj.get_bool');
    assertTrue(pljson_printer.pretty_print_any(obj) = 'false', 'pljson_printer.pretty_print_any(obj) = ''false''');
  end;
  
  -- Null
  procedure test_null is
    obj pljson_value;
  begin
    obj := pljson_value();
    assertTrue(obj is not null, 'obj is not null');
    assertTrue(pljson_printer.pretty_print_any(obj) = 'null', 'pljson_printer.pretty_print_any(obj) = ''null''');
    --assertTrue(obj.null_data is null, 'obj.null_data is null'); --doesnt matter really
  end;
  
  -- very small number, issue #69
  procedure test_very_small_number is
    obj pljson_value;
  begin
    obj := pljson_value(0.5);
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '0.5', 'pljson_printer.pretty_print_any(obj) = ''0.5''');
    
    obj := pljson_value(-0.5);
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '-0.5', 'pljson_printer.pretty_print_any(obj) = ''-0.5''');
    
    obj := pljson_value(1.1E-63);
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '1.1E-63', 'pljson_printer.pretty_print_any(obj) = ''1.1E-63''');
    
    obj := pljson_value(-1.1e-63d); -- test double too
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '-1.1E-63', 'pljson_printer.pretty_print_any(obj) = ''-1.1E-63''');
    
    obj := pljson_value(3.141592653589793238462643383279e-63);
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '3.141592653589793238462643383279E-63', 'pljson_printer.pretty_print_any(obj) = ''3.141592653589793238462643383279E-63''');
    
    obj := pljson_value(2.718281828459e-210d); -- test double too
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '2.718281828459E-210', 'pljson_printer.pretty_print_any(obj) = ''2.718281828459E-210''');
  end;
  
  -- parser/printer number/binary_double handling, issue #70
  procedure test_binary_double is
    obj pljson_list;
  begin
    obj := pljson_list('[1.23456789012e-360]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e-308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = False, 'obj.get(1).is_number_repr_number = False');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.23456789012e-308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = False, 'obj.get(1).is_number_repr_number = False');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e-129]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False');
    
    obj := pljson_list('[1.23456789012e-129]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False'); -- false because double is approximate
    
    obj := pljson_list('[0]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False');
    
    obj := pljson_list('[1.23456789012]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False'); -- false because double is approximate
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e125]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False');
    
    obj := pljson_list('[1.23456789012e125]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = False, 'obj.get(1).is_number_repr_number = False');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.23456789012e308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = False, 'obj.get(1).is_number_repr_number = False');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[9.23456789012e308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    assertTrue(pljson_printer.pretty_print_list(obj) = '[1e309]', 'pljson_printer.pretty_print_list(obj) = ''[1e309]''');
    
    obj := pljson_list('[-9.23456789012e308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    assertTrue(pljson_printer.pretty_print_list(obj) = '[-1e309]', 'pljson_printer.pretty_print_list(obj) = ''[-1e309]''');
  end;
  
end ut_pljson_simple_test;
/