/**
 * Test of PLSQL JSON Object by Jonas Krogsboell
 **/
set serveroutput on format wrapped
declare
  pass_count number := 0;
  fail_count number := 0;
  total_count number := 0;
  str varchar2(200);
  
  procedure pass(str varchar2) as
  begin
    pass_count := pass_count + 1;
    total_count := total_count + 1;
    dbms_output.put_line('OK: '||str);
  end;
  
  procedure fail(str varchar2) as
  begin
    fail_count := fail_count + 1;
    total_count := total_count + 1;
    dbms_output.put_line('FAILED: '||str);
  end;
  
  procedure assertTrue(b boolean) as
  begin
    if(not b) then raise_application_error(-20111, 'Test error'); end if;
  end;
  
  procedure assertFalse(b boolean) as
  begin
    if(b) then raise_application_error(-20111, 'Test error'); end if;
  end;

begin
  dbms_output.put_line('pljson_simple test:');
  
  str := 'Bool test';
  declare
    obj pljson_value;
  begin
    obj := pljson_value(true);
    assertTrue(obj.get_bool);
    assertFalse(not obj.get_bool);
    assertTrue(pljson_printer.pretty_print_any(obj) = 'true');
    obj := pljson_value(false);
    assertFalse(obj.get_bool);
    assertTrue(not obj.get_bool);
    assertTrue(pljson_printer.pretty_print_any(obj) = 'false');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Null test';
  declare
    obj pljson_value;
  begin
    obj := pljson_value();
    assertTrue(obj is not null);
    assertTrue(pljson_printer.pretty_print_any(obj) = 'null');
    --assertTrue(obj.null_data is null); --doesnt matter really
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Very small number test'; -- issue #69
  declare
    obj pljson_value;
  begin
    obj := pljson_value(0.5);
    dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '0.5');
    
    obj := pljson_value(-0.5);
    dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '-0.5');
    
    obj := pljson_value(1.1E-63);
    dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '1.1E-63');
    
    obj := pljson_value(-1.1e-63d); -- test double too
    dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '-1.1E-63');
    
    obj := pljson_value(3.141592653589793238462643383279e-63);
    dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '3.141592653589793238462643383279E-63');

    obj := pljson_value(2.718281828459e-210d); -- test double too
    dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    assertTrue(pljson_printer.pretty_print_any(obj) = '2.718281828459E-210');
    
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Parser/Printer number/binary_double handling test'; -- issue #70
  declare
    obj pljson_list;
  begin
    obj := pljson_list('[1.23456789012e-360]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = True);
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e-308]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = False);
    assertTrue(obj.get(1).is_number_repr_double = True);
    
    obj := pljson_list('[1.23456789012e-308]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = False);
    assertTrue(obj.get(1).is_number_repr_double = True);
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e-129]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = False);
    
    obj := pljson_list('[1.23456789012e-129]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = False); -- false because double is approximate
    
    obj := pljson_list('[0]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = True);
    
    obj := pljson_list('[1]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = True);
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = False);
    
    obj := pljson_list('[1.23456789012]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = False); -- false because double is approximate
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e125]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = False);
    
    obj := pljson_list('[1.23456789012e125]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = True);
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e308]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = False);
    assertTrue(obj.get(1).is_number_repr_double = True);
    
    obj := pljson_list('[1.23456789012e308]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = False);
    assertTrue(obj.get(1).is_number_repr_double = True);
    
    obj := pljson_list('[9.23456789012e308]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = True);
    assertTrue(pljson_printer.pretty_print_list(obj) = '[1e309]');
    
    obj := pljson_list('[-9.23456789012e308]');
    dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    assertTrue(obj.get(1).is_number_repr_number = True);
    assertTrue(obj.get(1).is_number_repr_double = True);
    assertTrue(pljson_printer.pretty_print_list(obj) = '[-1e309]');
    
    pass(str);
  --exception
  --  when others then fail(str);
  end;
  
  begin
    execute immediate 'insert into pljson_testsuite values (:1, :2, :3, :4, :5)' using
    'pljson simple type test', pass_count, fail_count, total_count, 'pljson_simple_test.sql';
  exception
    when others then null;
  end;
end;
/