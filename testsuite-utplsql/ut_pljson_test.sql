
create or replace package ut_pljson_test is
  
  --%suite(pljson test)
  --%suitepath(core)
  
  --%test(Test empty pljson)
  procedure test_empty;
  
  --%test(Test put method)  
  procedure test_put_method;
  
  --%test(Test put method with position)  
  procedure test_put_method_position;
  
  --%test(Test put method with binary double number) 
  procedure test_put_double;
  
  --%test(Test put method type)   
  procedure test_put_method_type;
  
  --%test(Test remove method)
  procedure test_remove_method;
  
  --%test(Test get method)
  procedure test_get_method;
  
  --%test(Test insert null number)
  procedure test_insert_null_number;
  
  --%test(Test insert null varchar2)
  procedure test_insert_null_varchar2;
  
  --%test(Test insert null boolean)
  procedure test_insert_null_boolean;
  
  --%test(Test insert null pljson_value)
  procedure test_insert_null_pljson_value;
  
  --%test(Test insert null pljson)
  procedure test_insert_null_pljson;
  
  --%test(Test insert null pljson_list)
  procedure test_insert_null_pljson_list;
  
  --%test(Test insert null pair name)
  procedure test_insert_null_pair_name;
  
end ut_pljson_test;
/

create or replace package body ut_pljson_test is
  
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
  
  -- empty pljson
  procedure test_empty is
    obj pljson;
  begin
    obj := pljson();
    assertTrue(obj.count = 0, 'obj.count = 0');
    assertTrue(obj.to_char(false) = '{}', 'obj.to_char(false) = ''{}''');
    --obj.print;
    obj := pljson('{     }');
    assertTrue(obj.count = 0, 'obj.count = 0');
    assertTrue(obj.to_char(false) = '{}', 'obj.to_char(false) = ''{}''');
  end;
  
  -- put method 
  procedure test_put_method is
    obj pljson;
    tester varchar2(4000);
    temp varchar2(10); --indent
  begin
    obj := pljson();
    obj.put('A', 1);
    obj.put('B', 1);
    obj.put('C', 1);
    assertTrue(obj.count = 3, 'obj.count = 3');
    obj.put('C', 2);
    assertTrue(obj.count = 3, 'obj.count = 3');
    --obj.put('A', 'AAA');
    obj.put('A', 'E'); -- issue #32 test too
    assertTrue(obj.count = 3, 'obj.count = 3');
    temp := pljson_printer.indent_string;
    pljson_printer.indent_string := '  ';
    tester := obj.to_char(false); --avoid newline problems
    pljson_printer.indent_string := temp;
    assertTrue(substr(tester, 2, 3) = '"A"', 'substr(tester, 2, 3) = ''"A"''');
    assertTrue(substr(tester, 6, 3) = '"E"', 'substr(tester, 6, 3) = ''"E"'''); -- issue #32 test too
  end;
  
  -- put method with position
  procedure test_put_method_position is
    obj pljson;
    tester varchar2(4000);
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
    assertTrue(obj.count = 7, 'obj.count = 7');
    --obj.print;
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).mapindx = i, 'obj.json_data(i).mapindx = i = ' || i);
      assertTrue(obj.json_data(i).mapname = obj.json_data(i).get_string, 'obj.json_data(i).mapname = obj.json_data(i).get_string, i = ' || i);
    end loop;
  end;
  
  -- put method with binary double number
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure test_put_double is
    obj pljson;
    tester varchar2(4000);
  begin
    obj := pljson();
    obj.put('I', 2.7182818284590452353602874713526624977e120);
    obj.put('J', 2.718281828459e210d);
    assertTrue(obj.get('I').get_number = 2.7182818284590452353602874713526624977e120, 'obj.get(''I'').get_number = 2.7182818284590452353602874713526624977e120');
    assertTrue(obj.get('J').get_double = 2.718281828459e210d, 'obj.get(''J'').get_double = 2.718281828459e210d');
    --obj.print;
  end;
  
  -- put method type
  procedure test_put_method_type is
    obj pljson;
    tester varchar2(4000);
  begin
    obj := pljson();
    obj.put('A', 'varchar2');
    obj.put('A', 2);
    obj.put('A', pljson_value(true));
    obj.put('A', pljson_value());
    obj.put('A', pljson());
    obj.put('A', pljson_list('[34,34]'));
    assertTrue(obj.count = 1, 'obj.count = 1');
    --obj.print;
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).mapindx = i, 'obj.json_data(i).mapindx = i = ' || i);
    end loop;
  end;
  
  -- remove method
  procedure test_remove_method is
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
    assertTrue(obj.count = 7, 'obj.count = 7');
    obj.remove('F');
    assertTrue(obj.count = 6, 'obj.count = 6');
    obj.remove('F');
    assertTrue(obj.count = 6, 'obj.count = 6');
    obj.remove('D');
    assertTrue(obj.count = 5, 'obj.count = 5');
    assertFalse(obj.exist('D'), 'obj.exist(''D'')');
    --obj.print;
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).mapindx = i, 'obj.json_data(i).mapindx = i = ' || i);
    end loop;
    obj := pljson();
    obj.put('A', 'A', 1);
    obj.remove('A');
    assertTrue(obj.count = 0, 'obj.count = 0');
    obj.remove('A');
    assertTrue(obj.count = 0, 'obj.count = 0');
    for i in 1 .. obj.count loop
      assertTrue(obj.json_data(i).mapindx = i, 'obj.json_data(i).mapindx = i = ' || i);
    end loop;
  end;
  
  -- get method
  procedure test_get_method is
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
    assertFalse(obj.get('A') is null, 'obj.get(''A'') is null');
    assertFalse(obj.get('B') is null, 'obj.get(''B'') is null');
    assertFalse(obj.get('C') is null, 'obj.get(''C'') is null');
    assertFalse(obj.get('D') is null, 'obj.get(''D'') is null');
    assertFalse(obj.get('E') is null, 'obj.get(''E'') is null');
    assertFalse(obj.get('F') is null, 'obj.get(''F'') is null');
    --obj.print;
    obj := pljson();
    assertTrue(obj.get('F') is null, 'obj.get(''F'') is null');
  end;
  
  -- insert null number
  procedure test_insert_null_number is
    obj pljson := pljson();
    x number := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertTrue(n.is_null, 'n.is_null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null varchar2
  procedure test_insert_null_varchar2 is
    obj pljson := pljson();
    x1 varchar2(20) := null;
    x2 varchar2(20) := '';
    test_name varchar2(100);
  begin
    obj.put('X1', x1);
    obj.put('X2', x2);
    begin
      test_name := 'x1 := obj.get(''X1'').get_string;';
      x1 := obj.get('X1').get_string;
      pass(test_name);
    exception
      when others then
        fail(test_name);
    end;
    begin
      test_name := 'x1 := obj.get(''X2'').get_string;';
      x2 := obj.get('X2').get_string;
      pass(test_name);
    exception
      when others then
        fail(test_name);
    end;
  end;
  
  -- insert null boolean
  procedure test_insert_null_boolean is
    obj pljson := pljson();
    x boolean := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null pljson_value
  procedure test_insert_null_pljson_value is
    obj pljson := pljson();
    x pljson_value := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null pljson
  procedure test_insert_null_pljson is
    obj pljson := pljson();
    x pljson := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null pljson_list
  procedure test_insert_null_pljson_list is
    obj pljson := pljson();
    x pljson_list := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null pair name
  procedure test_insert_null_pair_name is
    obj pljson := pljson();
    test_name varchar2(100);
  begin
    test_name := 'obj.put(null, ''test'');';
    obj.put(null, 'test');
    pass(test_name);
  exception
    when others then
      fail(test_name);
  end;
  
end ut_pljson_test;
/