
/**
 * Test of JSON Path imple. in JSON_Ext by Jonas Krogsboell
 **/

set serveroutput on format wrapped

begin
  
  pljson_ut.testsuite('pljson_path test', 'pljson_path.test.sql');
  
  -- get simple
  pljson_ut.testcase('Test get simple');
  declare
    obj pljson;
  begin
    obj := pljson('{"a": true, "b": {"c": 123}, "d": {"e": 2.718281828459e210}}');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a').get_bool, 'pljson_ext.get_json_value(obj, ''a'').get_bool');
    pljson_ut.assertTrue(pljson_ext.get_json(obj, 'a') is null, 'pljson_ext.get_json(obj, ''a'') is null');
    pljson_ut.assertTrue(pljson_ext.get_json(obj, 'b') is not null, 'pljson_ext.get_json(obj, ''b'') is not null');
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, 'b.c'),0) = 123, 'nvl(pljson_ext.get_number(obj, ''b.c''),0) = 123');
    pljson_ut.assertTrue(pljson_ext.get_string(obj, 'b.c') is null, 'pljson_ext.get_string(obj, ''b.c'') is null');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ut.assertTrue(nvl(pljson_ext.get_double(obj, 'd.e'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''d.e''),0) = 2.718281828459e210d');
  end;
  
  -- get with arrays
  pljson_ut.testcase('Test get with arrays');
  declare
    obj pljson;
  begin
    obj := pljson('{"a": [1,[true,15, 2.718281828459e210]]}');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a').is_array, 'pljson_ext.get_json_value(obj, ''a'').is_array');
    pljson_ut.assertTrue(pljson_ext.get_json_list(obj, 'a') is not null, 'pljson_ext.get_json_list(obj, ''a'') is not null');
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, 'a[1]'),0) = 1, 'nvl(pljson_ext.get_number(obj, ''a[1]''),0) = 1');
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, 'a[2][2]'),0) = 15, 'nvl(pljson_ext.get_number(obj, ''a[2][2]''),0) = 15');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a[2][1]').get_bool, 'pljson_ext.get_json_value(obj, ''a[2][1]'').get_bool');
    --pljson_ut.assertFalse(nvl(pljson_ext.get_number(obj, 'a[0][13]'),0)=15, 'nvl(pljson_ext.get_number(obj, ''a[0][13]''),0)=15'); --will throw exception on invalid json path
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ut.assertTrue(nvl(pljson_ext.get_double(obj, 'a[2][3]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''a[2][3]''),0) = 2.718281828459e210d');
  end;
  
  -- get with mixed structures
  pljson_ut.testcase('Test get with mixed structures');
  declare
    obj pljson;
  begin
    obj := pljson('{"a": [1,[{"a":{"i":[{"A":2}, 2.718281828459e210]}},15] ] }');
    --obj.print;
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a').is_array, 'pljson_ext.get_json_value(obj, ''a'').is_array');
    pljson_ut.assertTrue(pljson_ext.get_json_list(obj, 'a') is not null, 'pljson_ext.get_json_list(obj, ''a'') is not null');
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, 'a[2][2]'),0) = 15, 'nvl(pljson_ext.get_number(obj, ''a[2][2]''),0) = 15');
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, 'a[2][1].a.i[1].A'),0) = 2, 'nvl(pljson_ext.get_number(obj, ''a[2][1].a.i[1].A''),0) = 2');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ut.assertTrue(nvl(pljson_ext.get_double(obj, 'a[2][1].a.i[2]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''a[2][1].a.i[2]''),0) = 2.718281828459e210d');
  end;
  
  -- get with spaces
  pljson_ut.testcase('Test get with spaces');
  declare
    obj pljson;
  begin
    obj := pljson('{" a ": true, "b     ":{" s  ":[{" 3 ":7913}]}}');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, ' a ').get_bool, 'pljson_ext.get_json_value(obj, '' a '').get_bool');
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, 'b     . s  [  1   ]. 3 '),0)=7913, 'nvl(pljson_ext.get_number(obj, ''b     . s  [  1   ]. 3 ''),0)=7913');
  end;
  
  -- get all types
  pljson_ut.testcase('Test get all types');
  declare
    obj pljson;
  begin
    obj := pljson('{"a": ["Str", 1, false, null, {}, [], "2009-08-31 12:34:56"] }');
    --obj.print;
    pljson_ut.assertTrue(pljson_ext.get_string(obj, 'a[1]') is not null, 'pljson_ext.get_string(obj, ''a[1]'') is not null');
    pljson_ut.assertTrue(pljson_ext.get_number(obj, 'a[2]') is not null, 'pljson_ext.get_number(obj, ''a[2]'') is not null');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a[3]').is_bool, 'pljson_ext.get_json_value(obj, ''a[3]'').is_bool');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a[4]').is_null, 'pljson_ext.get_json_value(obj, ''a[4]'').is_null');
    pljson_ut.assertTrue(pljson_ext.get_json(obj, 'a[5]') is not null, 'pljson_ext.get_json(obj, ''a[5]'') is not null');
    pljson_ut.assertTrue(pljson_ext.get_json_list(obj, 'a[6]') is not null, 'pljson_ext.get_json_list(obj, ''a[6]'') is not null');
    pljson_ut.assertTrue(pljson_ext.get_date(obj, 'a[7]') is not null, 'pljson_ext.get_date(obj, ''a[7]'') is not null');
  end;
  
  -- put simple
  pljson_ut.testcase('Test put simple');
  declare
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a', 'x');
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a'),'a') = 'x', 'nvl(pljson_ext.get_string(obj, ''a''),''a'') = ''x''');
    pljson_ext.put(obj, 'a', 'y');
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a'),'a') = 'y', 'nvl(pljson_ext.get_string(obj, ''a''),''a'') = ''y''');
  end;
  
  -- put array
  pljson_ut.testcase('Test put array');
  declare
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a', pljson_list('["x"]'));
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a[1]'),'a') = 'x', 'nvl(pljson_ext.get_string(obj, ''a[1]''),''a'') = ''x''');
    pljson_ext.put(obj, 'a[1]', 'y');
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a[1]'),'a') = 'y', 'nvl(pljson_ext.get_string(obj, ''a[1]''),''a'') = ''y''');
    pljson_ext.put(obj, 'a[3]', 'z');
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a[1]'),'a') = 'y', 'nvl(pljson_ext.get_string(obj, ''a[1]''),''a'') = ''y''');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a[2]') is not null, 'pljson_ext.get_json_value(obj, ''a[2]'') is not null');
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a[3]'),'a') = 'z', 'nvl(pljson_ext.get_string(obj, ''a[3]''),''a'') = ''z''');
    pljson_ext.put(obj, 'a[2]', pljson_ext.get_string(obj, 'a[1]'));
    pljson_ext.put(obj, 'a[1]', 'x');
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a[1]'),'a') = 'x', 'nvl(pljson_ext.get_string(obj, ''a[1]''),''a'') = ''x''');
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a[2]'),'a') = 'y', 'nvl(pljson_ext.get_string(obj, ''a[2]''),''a'') = ''y''');
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a[3]'),'a') = 'z', 'nvl(pljson_ext.get_string(obj, ''a[3]''),''a'') = ''z''');
  end;
  
  -- put advanced
  pljson_ut.testcase('Test put advanced');
  declare
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a.b[1].c', true);
    pljson_ut.assertTrue(pljson_ext.get_json_list(obj, 'a.b') is not null, 'pljson_ext.get_json_list(obj, ''a.b'') is not null');
    pljson_ext.put(obj, 'a.b[1].c', false);
    --dbms_output.put_line('Put false');
    --obj.print;
    pljson_ut.assertTrue(pljson_ext.get_json_list(obj, 'a.b') is not null, 'pljson_ext.get_json_list(obj, ''a.b'') is not null');
    pljson_ut.assertFalse(pljson_ext.get_json_value(obj, 'a.b[1].c').get_bool, 'pljson_ext.get_json_value(obj, ''a.b[1].c'').get_bool');
  end;
  
  -- put all types
  pljson_ut.testcase('Test put all types');
  declare
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a', true);
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a').get_bool, 'pljson_ext.get_json_value(obj, ''a'').get_bool');
    pljson_ext.put(obj, 'a', pljson_value.makenull);
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a').is_null, 'pljson_ext.get_json_value(obj, ''a'').is_null');
    pljson_ext.put(obj, 'a', 'string');
    pljson_ut.assertTrue(nvl(pljson_ext.get_string(obj, 'a'),'a') = 'string', 'nvl(pljson_ext.get_string(obj, ''a''),''a'') = ''string''');
    pljson_ext.put(obj, 'a', 123.456);
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, 'a'),0) = 123.456, 'nvl(pljson_ext.get_number(obj, ''a''),0) = 123.456');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ext.put(obj, 'a', 2.718281828459e210d);
    pljson_ut.assertTrue(nvl(pljson_ext.get_double(obj, 'a'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''a''),0) = 2.718281828459e210d');
  end;
  
  -- put build
  pljson_ut.testcase('Test put build');
  declare
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a[1][2][3].c.d', date '2009-08-31');
    pljson_ut.assertTrue(nvl(pljson_ext.get_date(obj, 'a[1][2][3].c.d'),date '2000-01-01') = date '2009-08-31', 'nvl(pljson_ext.get_date(obj, ''a[1][2][3].c.d''),date ''2000-01-01'') = date ''2009-08-31''');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a[1][2][2]').is_null, 'pljson_ext.get_json_value(obj, ''a[1][2][2]'').is_null');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a[1][2][1]').is_null, 'pljson_ext.get_json_value(obj, ''a[1][2][1]'').is_null');
    pljson_ut.assertTrue(pljson_ext.get_json_value(obj, 'a[1][1]').is_null, 'pljson_ext.get_json_value(obj, ''a[1][1]'').is_null');
    pljson_ext.put(obj, 'f[1]', pljson_list('[1,null,[[12, 2.718281828459e210],2],null]'));
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, 'f[1][3][1][1]'),0) = 12, 'nvl(pljson_ext.get_number(obj, ''f[1][3][1][1]''),0) = 12');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ut.assertTrue(nvl(pljson_ext.get_double(obj, 'f[1][3][1][2]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''f[1][3][1][2]''),0) = 2.718281828459e210d');
  end;
  
  -- put exceptions
  pljson_ut.testcase('Test put exceptions');
  declare
    obj pljson := pljson();
    test_name varchar2(100);
  begin
    --empty string
    --..
    --. end
    --. nonpositive int
    --. float as index
    --. string is index
    begin
      test_name := 'pljson_ext.put(obj, '''', date ''2009-08-31'')';
      pljson_ext.put(obj, '', date '2009-08-31');
      obj.print;
      pljson_ut.fail(test_name);
    exception
      when others then
        pljson_ut.pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''[2]..[3].c.d'', date ''2009-08-31'')';
      pljson_ext.put(obj, '[2]..[3].c.d', date '2009-08-31');
      obj.print;
      pljson_ut.fail(test_name);
    exception
      when others then
        pljson_ut.pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''a[1][2][3].c.d.'', date ''2009-08-31'')';
      pljson_ext.put(obj, 'a[1][2][3].c.d.', date '2009-08-31');
      obj.print;
      pljson_ut.fail(test_name);
    exception
      when others then
        pljson_ut.pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''a[0][2][3]'', date ''2009-08-31'')';
      pljson_ext.put(obj, 'a[0][2][3]', date '2009-08-31');
      pljson_ut.fail(test_name);
    exception
      when others then
        pljson_ut.pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''a[0][2][3]'', date ''2009-08-31'')';
      pljson_ext.put(obj, 'a[0][2][3]', date '2009-08-31');
      pljson_ut.fail(test_name);
    exception
      when others then
        pljson_ut.pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''a[0.3][2][3]'', date ''2009-08-31'')';
      pljson_ext.put(obj, 'a[0.3][2][3]', date '2009-08-31');
      pljson_ut.fail(test_name);
    exception
      when others then
        pljson_ut.pass(test_name);
    end;
  end;
  
  -- remove simple
  pljson_ut.testcase('Test remove simple');
  declare
    obj pljson := pljson('{"2":[1,2,3]}');
  begin
    pljson_ext.remove(obj, '2[2]');
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, '2[2]'),0) = 3, 'nvl(pljson_ext.get_number(obj, ''2[2]''),0) = 3');
    pljson_ext.remove(obj, '2');
    pljson_ut.assertTrue(obj.count = 0, 'obj.count = 0');
  end;
  
  -- remove advanced
  pljson_ut.testcase('Test remove advanced');
  declare
    obj pljson := pljson('{"a":true, "b":[[]]}');
  begin
    pljson_ext.remove(obj, 'a');
    pljson_ut.assertFalse(obj.exist('a'), 'obj.exist(''a'')');
    pljson_ut.assertTrue(obj.count = 1, 'obj.count = 1');
    pljson_ext.remove(obj, 'b[1]');
    pljson_ut.assertFalse(obj.exist('b'), 'obj.exist(''b'')');
  end;
  
  -- get with index
  pljson_ut.testcase('Test get with index');
  declare
    obj pljson := pljson('{"a": [1,[{"a":{"i":[{"A":2, "E": 2.718281828459e210}]}},15] ] }');
  begin
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, 'a[2][1].a.i[1].A'),0) = 2, 'nvl(pljson_ext.get_number(obj, ''a[2][1].a.i[1].A''),0) = 2');
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]'),0) = 2, 'nvl(pljson_ext.get_number(obj, ''[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]''),0) = 2');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ut.assertTrue(nvl(pljson_ext.get_double(obj, 'a[2][1].a.i[1].E'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''a[2][1].a.i[1].E''),0) = 2.718281828459e210d');
    pljson_ut.assertTrue(nvl(pljson_ext.get_double(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["E"]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''[ "a"  ][2][1 ] [ "a" ]["i"][1]["E"]''),0) = 2.718281828459e210d');
  end;
  
  -- put with index
  pljson_ut.testcase('Test put with index');
  declare
    obj pljson := pljson('{"a": [1,[{"a":{"i":[{"A":2}]}},15] ] }');
  begin
    pljson_ext.put(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]', 78);
    pljson_ut.assertTrue(nvl(pljson_ext.get_number(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]'),0) = 78, 'nvl(pljson_ext.get_number(obj, ''[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]''),0) = 78');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ext.put(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]', 2.718281828459e210d);
    pljson_ut.assertTrue(nvl(pljson_ext.get_double(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]''),0) = 2.718281828459e210d');
  end;
  
  pljson_ut.testsuite_report;
  
end;
/