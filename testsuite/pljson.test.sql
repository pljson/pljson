
/**
 * Test of PLSQL JSON Object by Jonas Krogsboell
 **/

set serveroutput on format wrapped

begin
  
  pljson_ut.testsuite('pljson test', 'pljson.test.sql');
  
  -- empty pljson
  pljson_ut.testcase('Test empty pljson');
  declare
    obj pljson;
  begin
    obj := pljson();
    pljson_ut.assertTrue(obj.count = 0, 'obj.count = 0');
    pljson_ut.assertTrue(obj.to_char(false) = '{}', 'obj.to_char(false) = ''{}''');
    --obj.print;
    obj := pljson('{     }');
    pljson_ut.assertTrue(obj.count = 0, 'obj.count = 0');
    pljson_ut.assertTrue(obj.to_char(false) = '{}', 'obj.to_char(false) = ''{}''');
  end;
  
  -- put method
  pljson_ut.testcase('Test put method');
  declare
    obj pljson;
    tester varchar2(4000);
    temp varchar2(10); --indent
  begin
    obj := pljson();
    obj.put('A', 1);
    obj.put('B', 1);
    obj.put('C', 1);
    pljson_ut.assertTrue(obj.count = 3, 'obj.count = 3');
    obj.put('C', 2);
    pljson_ut.assertTrue(obj.count = 3, 'obj.count = 3');
    --obj.put('A', 'AAA');
    obj.put('A', 'E'); -- issue #32 test too
    pljson_ut.assertTrue(obj.count = 3, 'obj.count = 3');
    temp := pljson_printer.indent_string;
    pljson_printer.indent_string := '  ';
    tester := obj.to_char(false); --avoid newline problems
    pljson_printer.indent_string := temp;
    pljson_ut.assertTrue(substr(tester, 2, 3) = '"A"', 'substr(tester, 2, 3) = ''"A"''');
    pljson_ut.assertTrue(substr(tester, 6, 3) = '"E"', 'substr(tester, 6, 3) = ''"E"'''); -- issue #32 test too
  end;
  
  -- put method with position
  pljson_ut.testcase('Test put method with position');
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
    pljson_ut.assertTrue(obj.count = 7, 'obj.count = 7');
    --obj.print;
    for i in 1 .. obj.count loop
      pljson_ut.assertTrue(obj.json_data(i).mapindx = i, 'obj.json_data(i).mapindx = i = ' || i);
      pljson_ut.assertTrue(obj.json_data(i).mapname = obj.json_data(i).get_string, 'obj.json_data(i).mapname = obj.json_data(i).get_string, i = ' || i);
    end loop;
  end;
  
  -- put method with binary double number
  pljson_ut.testcase('Test put method with binary double number');
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  declare
    obj pljson;
    tester varchar2(4000);
  begin
    obj := pljson();
    obj.put('I', 2.7182818284590452353602874713526624977e120);
    obj.put('J', 2.718281828459e210d);
    pljson_ut.assertTrue(obj.get('I').get_number = 2.7182818284590452353602874713526624977e120, 'obj.get(''I'').get_number = 2.7182818284590452353602874713526624977e120');
    pljson_ut.assertTrue(obj.get('J').get_double = 2.718281828459e210d, 'obj.get(''J'').get_double = 2.718281828459e210d');
    --obj.print;
  end;
  
  -- put method type
  pljson_ut.testcase('Test put method type');
  declare
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
    pljson_ut.assertTrue(obj.count = 1, 'obj.count = 1');
    --obj.print;
    for i in 1 .. obj.count loop
      pljson_ut.assertTrue(obj.json_data(i).mapindx = i, 'obj.json_data(i).mapindx = i = ' || i);
    end loop;
  end;
  
  -- remove method
  pljson_ut.testcase('Test remove method');
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
    pljson_ut.assertTrue(obj.count = 7, 'obj.count = 7');
    obj.remove('F');
    pljson_ut.assertTrue(obj.count = 6, 'obj.count = 6');
    obj.remove('F');
    pljson_ut.assertTrue(obj.count = 6, 'obj.count = 6');
    obj.remove('D');
    pljson_ut.assertTrue(obj.count = 5, 'obj.count = 5');
    pljson_ut.assertFalse(obj.exist('D'), 'obj.exist(''D'')');
    --obj.print;
    for i in 1 .. obj.count loop
      pljson_ut.assertTrue(obj.json_data(i).mapindx = i, 'obj.json_data(i).mapindx = i = ' || i);
    end loop;
    obj := pljson();
    obj.put('A', 'A', 1);
    obj.remove('A');
    pljson_ut.assertTrue(obj.count = 0, 'obj.count = 0');
    obj.remove('A');
    pljson_ut.assertTrue(obj.count = 0, 'obj.count = 0');
    for i in 1 .. obj.count loop
      pljson_ut.assertTrue(obj.json_data(i).mapindx = i, 'obj.json_data(i).mapindx = i = ' || i);
    end loop;
  end;
  
  -- get method
  pljson_ut.testcase('Test get method');
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
    pljson_ut.assertFalse(obj.get('A') is null, 'obj.get(''A'') is null');
    pljson_ut.assertFalse(obj.get('B') is null, 'obj.get(''B'') is null');
    pljson_ut.assertFalse(obj.get('C') is null, 'obj.get(''C'') is null');
    pljson_ut.assertFalse(obj.get('D') is null, 'obj.get(''D'') is null');
    pljson_ut.assertFalse(obj.get('E') is null, 'obj.get(''E'') is null');
    pljson_ut.assertFalse(obj.get('F') is null, 'obj.get(''F'') is null');
    --obj.print;
    obj := pljson();
    pljson_ut.assertTrue(obj.get('F') is null, 'obj.get(''F'') is null');
  end;
  
  -- insert null number
  pljson_ut.testcase('Test insert null number');
  declare
    obj pljson := pljson();
    x number := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    pljson_ut.assertTrue(n.is_null, 'n.is_null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null varchar2
  pljson_ut.testcase('Test insert null varchar2');
  declare
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
      pljson_ut.pass(test_name);
    exception
      when others then
        pljson_ut.fail(test_name);
    end;
    begin
      test_name := 'x1 := obj.get(''X2'').get_string;';
      x2 := obj.get('X2').get_string;
      pljson_ut.pass(test_name);
    exception
      when others then
        pljson_ut.fail(test_name);
    end;
  end;
  
  -- insert null boolean
  pljson_ut.testcase('Test insert null boolean');
  declare
    obj pljson := pljson();
    x boolean := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    pljson_ut.assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null pljson_value
  pljson_ut.testcase('Test insert null pljson_value');
  declare
    obj pljson := pljson();
    x pljson_value := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    pljson_ut.assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null pljson
  pljson_ut.testcase('Test insert null pljson');
  declare
    obj pljson := pljson();
    x pljson := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    pljson_ut.assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null pljson_list
  pljson_ut.testcase('Test insert null pljson_list');
  declare
    obj pljson := pljson();
    x pljson_list := null;
    n pljson_value;
  begin
    obj.put('X', x);
    n := obj.get('X');
    pljson_ut.assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best
  end;
  
  -- insert null pair name
  pljson_ut.testcase('Test insert null pair name');
  declare
    obj pljson := pljson();
    test_name varchar2(100);
  begin
    test_name := 'obj.put(null, ''test'');';
    obj.put(null, 'test');
    pljson_ut.pass(test_name);
  exception
    when others then
      pljson_ut.fail(test_name);
  end;
  
  pljson_ut.testsuite_report;
  
end;
/