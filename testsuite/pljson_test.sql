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
  
  str := 'Empty PLJSON test';
  declare
    obj pljson;
  begin
    obj := pljson();
    assertTrue(obj.count = 0);
    assertTrue(obj.to_char(false) = '{}');
    --obj.print;
    obj := pljson('{     }');
    assertTrue(obj.count = 0);
    assertTrue(obj.to_char(false) = '{}');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Put method PLJSON test';
  declare
    obj pljson; tester varchar2(4000);
    temp varchar2(10); --indent
    test_no pls_integer := 1;
  begin
    obj := pljson();
    obj.put('A', 1);
    obj.put('B', 1);
    obj.put('C', 1);
    assertTrue(obj.count = 3);
    obj.put('C', 2);
    assertTrue(obj.count = 3);
    --obj.put('A', 'AAA');
    obj.put('A', 'E'); -- issue #32 test too
    assertTrue(obj.count = 3);
    temp := pljson_printer.indent_string;
    pljson_printer.indent_string := '  ';
    tester := obj.to_char(false); --avoid newline problems
    pljson_printer.indent_string := temp;
    assertTrue(substr(tester, 2, 3) = '"A"');
    pass(str);
    test_no := 2;
    assertTrue(substr(tester, 6, 3) = '"E"'); -- issue #32 test too
    pass('issue #32');
  exception
    when others then
      if (test_no = 1) then
        fail(str);
      elsif (test_no = 2) then
        fail('issue #32');
      end if;
  end;
  
  str := 'Put method PLJSON test with position';
  declare
    obj pljson; tester varchar2(4000);
  begin
    obj := pljson();
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
      assertTrue(obj.json_data(i).mapindx = i);
      assertTrue(obj.json_data(i).mapname = obj.json_data(i).get_string);
    end loop;
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Put method type test';
  declare
    obj pljson; tester varchar2(4000);
  begin
    obj := pljson();
    obj.put('A', 'varchar2');
    obj.put('A', 2);
    obj.put('A', pljson_value(true));
    obj.put('A', pljson_value());
    obj.put('A', pljson());
    obj.put('A', pljson_list('[34,34]'));
    assertTrue(obj.count = 1);
    --obj.print;
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).mapindx = i);
    end loop;
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Remove method test';
  declare
    obj pljson;
  begin
    obj := pljson();
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
      assertTrue(obj.json_data(i).mapindx = i);
    end loop;
    obj := pljson();
    obj.put('A', 'A', 1);
    obj.remove('A');
    assertTrue(obj.count = 0);
    obj.remove('A');
    assertTrue(obj.count = 0);
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).mapindx = i);
    end loop;
    
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Get method test';
  declare
    obj pljson;
  begin
    obj := pljson();
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
    obj := pljson();
    assertTrue(obj.get('F') is null);
    
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Number null insert test';
  declare
    obj pljson := pljson();
    x number := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertTrue(n.is_null); --may seem odd -- but initialized vars are best!
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Varchar2 null insert test';
  declare
    obj pljson := pljson();
    x1 varchar2(20) := null;
    x2 varchar2(20) := '';
  begin
    obj.put('X1', x1);
    obj.put('X2', x2);
    x1 := obj.get('X1').get_string;
    x2 := obj.get('X2').get_string;
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Bool null insert test';
  declare
    obj pljson := pljson();
    x boolean := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertFalse(n is null); --may seem odd -- but initialized vars are best!
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Null null insert test';
  declare
    obj pljson := pljson();
    x pljson_value := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertFalse(n is null); --may seem odd -- but initialized vars are best!
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'pljson null insert test';
  declare
    obj pljson := pljson();
    x pljson := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertFalse(n is null); --may seem odd -- but initialized vars are best!
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'pljson_list null insert test';
  declare
    obj pljson := pljson();
    x pljson_list := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertFalse(n is null); --may seem odd -- but initialized vars are best!
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'pljson null pair_name insert test';
  declare
    obj pljson := pljson();
  begin
    obj.put(null, 'test');
    pass(str); -- new behavior
  exception
    when others then fail(str);
  end;
  
  begin
    execute immediate 'insert into pljson_testsuite values (:1, :2, :3, :4, :5)' using
    'pljson test', pass_count, fail_count, total_count,'pljson_test.sql';
  exception
    when others then null;
  end;
end;
/
