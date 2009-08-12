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
  
  str := 'Empty JSON test';
  declare
    obj json;
  begin
    obj := json();
    assertTrue(obj.count = 0);
    assertTrue(obj.to_char = '{'||chr(13)||'}');
    --obj.print;
    obj := json('{     }');
    assertTrue(obj.count = 0);
    assertTrue(obj.to_char = '{'||chr(13)||'}');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Put method JSON test';
  declare
    obj json; tester varchar2(4000);
  begin
    obj := json();
    obj.put('A', 1);
    obj.put('B', 1);
    obj.put('C', 1);
    assertTrue(obj.count = 3);
    obj.put('C', 2);
    assertTrue(obj.count = 3);
    obj.put('A', 'AAA');
    assertTrue(obj.count = 3);
    tester := obj.to_char;
    tester := substr(tester, 5,3);
    assertTrue(tester = '"A"');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Put method JSON test with position';
  declare
    obj json; tester varchar2(4000);
  begin
    obj := json();
    obj.put('A', 'A', 1);
    obj.put('B', 'B', 1);
    obj.put('C', 'C', 2);
    obj.put('D', 'E', 2);
    obj.put('D', 'D', 3);--correct
    obj.put('E', 'E', 3);
    obj.put('F', 'F', 5);
    obj.put('G', 'G', 7);
    assertTrue(obj.count = 7);
    --obj.print;
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).id = i);
      assertTrue(obj.json_data(i).member_name = json.to_varchar2(obj.json_data(i).member_data));
    end loop;
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Put method type test';
  declare
    obj json; tester varchar2(4000);
  begin
    obj := json();
    obj.put('A', 'varchar2');
    obj.put('A', 2);
    obj.put('A', json_bool(true));
    obj.put('A', json_null());
    obj.put('A', json());
    obj.put('A', json_list('[34,34]'));
    assertTrue(obj.count = 1);
    --obj.print;
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).id = i);
    end loop;
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Remove method test';
  declare
    obj json;
  begin
    obj := json();
    obj.put('A', 'A', 1);
    obj.put('B', 'B', 1);
    obj.put('C', 'C', 2);
    obj.put('D', 'E', 2);
    obj.put('D', 'D', 3);--correct
    obj.put('E', 'E', 3);
    obj.put('F', 'F', 5);
    obj.put('G', 'G', 7);
    assertTrue(obj.count = 7);
    obj.remove('F');
    assertTrue(obj.count = 6);
    obj.remove('F');
    assertTrue(obj.count = 6);
    obj.remove('D');
    assertTrue(obj.count = 5);
    assertFalse(obj.exist('D'));
    --obj.print;
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).id = i);
    end loop;
    obj := json();
    obj.put('A', 'A', 1);
    obj.remove('A');
    assertTrue(obj.count = 0);
    obj.remove('A');
    assertTrue(obj.count = 0);
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).id = i);
    end loop;

    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Get method test';
  declare
    obj json;
  begin
    obj := json();
    obj.put('A', 'A', 1);
    obj.put('B', 'B', 1);
    obj.put('C', 'C', 2);
    obj.put('D', 'E', 2);
    obj.put('D', 'D', 3);--correct
    obj.put('E', 'E', 3);
    obj.put('F', 'F', 5);
    obj.put('G', 'G', 7);
    assertFalse(obj.get('A') is null);
    assertFalse(obj.get('B') is null);
    assertFalse(obj.get('C') is null);
    assertFalse(obj.get('D') is null);
    assertFalse(obj.get('E') is null);
    assertFalse(obj.get('F') is null);
    --obj.print;
    obj := json();
    assertTrue(obj.get('F') is null);

    pass(str);
  exception
    when others then fail(str);
  end;

  begin
    execute immediate 'insert into json_testsuite values (:1, :2, :3, :4, :5)' using
    'JSON testing', pass_count,fail_count,total_count,'json_test.sql';
  exception
    when others then null;
  end;
end;