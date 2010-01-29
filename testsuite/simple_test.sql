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
    obj json_value;
  begin
    obj := json_value(true);
    assertTrue(obj.get_bool);
    assertFalse(not obj.get_bool);
    assertTrue(json_printer.pretty_print_any(obj) = 'true');
    obj := json_value(false);
    assertFalse(obj.get_bool);
    assertTrue(not obj.get_bool);
    assertTrue(json_printer.pretty_print_any(obj) = 'false');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Null test';
  declare
    obj json_value;
  begin
    obj := json_value();
    assertTrue(obj is not null);
    assertTrue(json_printer.pretty_print_any(obj) = 'null');
    --assertTrue(obj.null_data is null); --doesnt matter really
    pass(str);
  exception
    when others then fail(str);
  end;

  begin
    execute immediate 'insert into json_testsuite values (:1, :2, :3, :4, :5)' using
    'Simple type test', pass_count,fail_count,total_count,'simple_test.sql';
  exception
    when others then null;
  end;
end;