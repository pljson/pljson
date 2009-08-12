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
    obj json_bool;
  begin
    obj := json_bool(true);
    assertTrue(obj.is_true);
    assertFalse(obj.is_false);
    obj := json_bool.maketrue;
    assertTrue(obj.is_true);
    assertFalse(obj.is_false);
    assertTrue(obj.to_char = 'true');
    obj := json_bool(false);
    assertFalse(obj.is_true);
    assertTrue(obj.is_false);
    obj := json_bool.makefalse;
    assertFalse(obj.is_true);
    assertTrue(obj.is_false);
    assertTrue(obj.to_char = 'false');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Null test';
  declare
    obj json_null;
  begin
    obj := json_null();
    assertTrue(obj is not null);
    assertTrue(obj.null_data is null);
    obj := json_null(chr(13));
    assertTrue(obj is not null);
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