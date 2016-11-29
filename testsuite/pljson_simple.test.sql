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
  
  str := 'Number test'; -- issue #69
  declare
    obj pljson_value;
  begin
    obj := pljson_value(0.5);
    assertTrue(pljson_printer.pretty_print_any(obj) = '0.5');
    
    obj := pljson_value(-0.5);
    assertTrue(pljson_printer.pretty_print_any(obj) = '-0.5');
    
    obj := pljson_value(1.1E-63);
    assertTrue(pljson_printer.pretty_print_any(obj) = '1.1E-63');
    
    obj := pljson_value(-1.1E-63);
    assertTrue(pljson_printer.pretty_print_any(obj) = '-1.1E-63');
    
    pass(str);
  exception
    when others then fail(str);
  end;
  
  begin
    execute immediate 'insert into pljson_testsuite values (:1, :2, :3, :4, :5)' using
    'pljson simple type test', pass_count, fail_count, total_count, 'pljson_simple_test.sql';
  exception
    when others then null;
  end;
end;
/
