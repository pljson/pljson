
create or replace package ut_pljson_path_test is
  
  --%suite(pljson_path test)
  --%suitepath(core)
  
  --%test(Test get simple)
  procedure test_get_simple;
  
  --%test(Test get with arrays)  
  procedure test_get_arrays;
  
  --%test(Test get with mixed structures)  
  procedure test_get_mixed;
  
  --%test(Test get with spaces) 
  procedure test_get_spaces;
  
  --%test(Test get all types)   
  procedure test_get_all_types;
  
  --%test(Test put simple)
  procedure test_put_simple;
  
  --%test(Test put array)
  procedure test_put_array;
  
  --%test(Test put advanced)
  procedure test_put_advanced;
  
  --%test(Test put all types)
  procedure test_put_all_types;
  
  --%test(Test put build)
  procedure test_put_build;
  
  --%test(Test put exceptions)
  procedure test_put_exceptions;
  
  --%test(Test remove simple)
  procedure test_remove_simple;
  
  --%test(Test remove advanced)
  procedure test_remove_advanced;
  
  --%test(Test get with index)
  procedure test_get_index;
  
  --%test(Test put with index)
  procedure test_put_index;
  
end ut_pljson_path_test;
/

create or replace package body ut_pljson_path_test is
  
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
  
  -- get simple
  procedure test_get_simple is
    obj pljson;
  begin
    obj := pljson('{"a": true, "b": {"c": 123}, "d": {"e": 2.718281828459e210}}');
    assertTrue(pljson_ext.get_json_value(obj, 'a').get_bool, 'pljson_ext.get_json_value(obj, ''a'').get_bool');
    assertTrue(pljson_ext.get_json(obj, 'a') is null, 'pljson_ext.get_json(obj, ''a'') is null');
    assertTrue(pljson_ext.get_json(obj, 'b') is not null, 'pljson_ext.get_json(obj, ''b'') is not null');
    assertTrue(nvl(pljson_ext.get_number(obj, 'b.c'),0) = 123, 'nvl(pljson_ext.get_number(obj, ''b.c''),0) = 123');
    assertTrue(pljson_ext.get_string(obj, 'b.c') is null, 'pljson_ext.get_string(obj, ''b.c'') is null');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    assertTrue(nvl(pljson_ext.get_double(obj, 'd.e'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''d.e''),0) = 2.718281828459e210d');
  end;
  
  -- get with arrays
  procedure test_get_arrays is
    obj pljson;
  begin
    obj := pljson('{"a": [1,[true,15, 2.718281828459e210]]}');
    assertTrue(pljson_ext.get_json_value(obj, 'a').is_array, 'pljson_ext.get_json_value(obj, ''a'').is_array');
    assertTrue(pljson_ext.get_json_list(obj, 'a') is not null, 'pljson_ext.get_json_list(obj, ''a'') is not null');
    assertTrue(nvl(pljson_ext.get_number(obj, 'a[1]'),0) = 1, 'nvl(pljson_ext.get_number(obj, ''a[1]''),0) = 1');
    assertTrue(nvl(pljson_ext.get_number(obj, 'a[2][2]'),0) = 15, 'nvl(pljson_ext.get_number(obj, ''a[2][2]''),0) = 15');
    assertTrue(pljson_ext.get_json_value(obj, 'a[2][1]').get_bool, 'pljson_ext.get_json_value(obj, ''a[2][1]'').get_bool');
    --assertFalse(nvl(pljson_ext.get_number(obj, 'a[0][13]'),0)=15, 'nvl(pljson_ext.get_number(obj, ''a[0][13]''),0)=15'); --will throw exception on invalid json path
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    assertTrue(nvl(pljson_ext.get_double(obj, 'a[2][3]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''a[2][3]''),0) = 2.718281828459e210d');
  end;
  
  -- get with mixed structures
  procedure test_get_mixed is
    obj pljson;
  begin
    obj := pljson('{"a": [1,[{"a":{"i":[{"A":2}, 2.718281828459e210]}},15] ] }');
    --obj.print;
    assertTrue(pljson_ext.get_json_value(obj, 'a').is_array, 'pljson_ext.get_json_value(obj, ''a'').is_array');
    assertTrue(pljson_ext.get_json_list(obj, 'a') is not null, 'pljson_ext.get_json_list(obj, ''a'') is not null');
    assertTrue(nvl(pljson_ext.get_number(obj, 'a[2][2]'),0) = 15, 'nvl(pljson_ext.get_number(obj, ''a[2][2]''),0) = 15');
    assertTrue(nvl(pljson_ext.get_number(obj, 'a[2][1].a.i[1].A'),0) = 2, 'nvl(pljson_ext.get_number(obj, ''a[2][1].a.i[1].A''),0) = 2');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    assertTrue(nvl(pljson_ext.get_double(obj, 'a[2][1].a.i[2]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''a[2][1].a.i[2]''),0) = 2.718281828459e210d');
  end;
  
  -- get with spaces
  procedure test_get_spaces is
    obj pljson;
  begin
    obj := pljson('{" a ": true, "b     ":{" s  ":[{" 3 ":7913}]}}');
    assertTrue(pljson_ext.get_json_value(obj, ' a ').get_bool, 'pljson_ext.get_json_value(obj, '' a '').get_bool');
    assertTrue(nvl(pljson_ext.get_number(obj, 'b     . s  [  1   ]. 3 '),0)=7913, 'nvl(pljson_ext.get_number(obj, ''b     . s  [  1   ]. 3 ''),0)=7913');
  end;
  
  -- get all types
  procedure test_get_all_types is
    obj pljson;
  begin
    obj := pljson('{"a": ["Str", 1, false, null, {}, [], "2009-08-31 12:34:56"] }');
    --obj.print;
    assertTrue(pljson_ext.get_string(obj, 'a[1]') is not null, 'pljson_ext.get_string(obj, ''a[1]'') is not null');
    assertTrue(pljson_ext.get_number(obj, 'a[2]') is not null, 'pljson_ext.get_number(obj, ''a[2]'') is not null');
    assertTrue(pljson_ext.get_json_value(obj, 'a[3]').is_bool, 'pljson_ext.get_json_value(obj, ''a[3]'').is_bool');
    assertTrue(pljson_ext.get_json_value(obj, 'a[4]').is_null, 'pljson_ext.get_json_value(obj, ''a[4]'').is_null');
    assertTrue(pljson_ext.get_json(obj, 'a[5]') is not null, 'pljson_ext.get_json(obj, ''a[5]'') is not null');
    assertTrue(pljson_ext.get_json_list(obj, 'a[6]') is not null, 'pljson_ext.get_json_list(obj, ''a[6]'') is not null');
    assertTrue(pljson_ext.get_date(obj, 'a[7]') is not null, 'pljson_ext.get_date(obj, ''a[7]'') is not null');
  end;
  
  -- put simple
  procedure test_put_simple is
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a', 'x');
    assertTrue(nvl(pljson_ext.get_string(obj, 'a'),'a') = 'x', 'nvl(pljson_ext.get_string(obj, ''a''),''a'') = ''x''');
    pljson_ext.put(obj, 'a', 'y');
    assertTrue(nvl(pljson_ext.get_string(obj, 'a'),'a') = 'y', 'nvl(pljson_ext.get_string(obj, ''a''),''a'') = ''y''');
  end;
  
  -- put array
  procedure test_put_array is
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a', pljson_list('["x"]'));
    assertTrue(nvl(pljson_ext.get_string(obj, 'a[1]'),'a') = 'x', 'nvl(pljson_ext.get_string(obj, ''a[1]''),''a'') = ''x''');
    pljson_ext.put(obj, 'a[1]', 'y');
    assertTrue(nvl(pljson_ext.get_string(obj, 'a[1]'),'a') = 'y', 'nvl(pljson_ext.get_string(obj, ''a[1]''),''a'') = ''y''');
    pljson_ext.put(obj, 'a[3]', 'z');
    assertTrue(nvl(pljson_ext.get_string(obj, 'a[1]'),'a') = 'y', 'nvl(pljson_ext.get_string(obj, ''a[1]''),''a'') = ''y''');
    assertTrue(pljson_ext.get_json_value(obj, 'a[2]') is not null, 'pljson_ext.get_json_value(obj, ''a[2]'') is not null');
    assertTrue(nvl(pljson_ext.get_string(obj, 'a[3]'),'a') = 'z', 'nvl(pljson_ext.get_string(obj, ''a[3]''),''a'') = ''z''');
    pljson_ext.put(obj, 'a[2]', pljson_ext.get_string(obj, 'a[1]'));
    pljson_ext.put(obj, 'a[1]', 'x');
    assertTrue(nvl(pljson_ext.get_string(obj, 'a[1]'),'a') = 'x', 'nvl(pljson_ext.get_string(obj, ''a[1]''),''a'') = ''x''');
    assertTrue(nvl(pljson_ext.get_string(obj, 'a[2]'),'a') = 'y', 'nvl(pljson_ext.get_string(obj, ''a[2]''),''a'') = ''y''');
    assertTrue(nvl(pljson_ext.get_string(obj, 'a[3]'),'a') = 'z', 'nvl(pljson_ext.get_string(obj, ''a[3]''),''a'') = ''z''');
  end;
  
  -- put advanced
  procedure test_put_advanced is
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a.b[1].c', true);
    assertTrue(pljson_ext.get_json_list(obj, 'a.b') is not null, 'pljson_ext.get_json_list(obj, ''a.b'') is not null');
    pljson_ext.put(obj, 'a.b[1].c', false);
    --dbms_output.put_line('Put false');
    --obj.print;
    assertTrue(pljson_ext.get_json_list(obj, 'a.b') is not null, 'pljson_ext.get_json_list(obj, ''a.b'') is not null');
    assertFalse(pljson_ext.get_json_value(obj, 'a.b[1].c').get_bool, 'pljson_ext.get_json_value(obj, ''a.b[1].c'').get_bool');
  end;
  
  -- put all types
  procedure test_put_all_types is
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a', true);
    assertTrue(pljson_ext.get_json_value(obj, 'a').get_bool, 'pljson_ext.get_json_value(obj, ''a'').get_bool');
    pljson_ext.put(obj, 'a', pljson_value.makenull);
    assertTrue(pljson_ext.get_json_value(obj, 'a').is_null, 'pljson_ext.get_json_value(obj, ''a'').is_null');
    pljson_ext.put(obj, 'a', 'string');
    assertTrue(nvl(pljson_ext.get_string(obj, 'a'),'a') = 'string', 'nvl(pljson_ext.get_string(obj, ''a''),''a'') = ''string''');
    pljson_ext.put(obj, 'a', 123.456);
    assertTrue(nvl(pljson_ext.get_number(obj, 'a'),0) = 123.456, 'nvl(pljson_ext.get_number(obj, ''a''),0) = 123.456');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ext.put(obj, 'a', 2.718281828459e210d);
    assertTrue(nvl(pljson_ext.get_double(obj, 'a'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''a''),0) = 2.718281828459e210d');
  end;
  
  -- put build
  procedure test_put_build is
    obj pljson := pljson();
  begin
    pljson_ext.put(obj, 'a[1][2][3].c.d', date '2009-08-31');
    assertTrue(nvl(pljson_ext.get_date(obj, 'a[1][2][3].c.d'),date '2000-01-01') = date '2009-08-31', 'nvl(pljson_ext.get_date(obj, ''a[1][2][3].c.d''),date ''2000-01-01'') = date ''2009-08-31''');
    assertTrue(pljson_ext.get_json_value(obj, 'a[1][2][2]').is_null, 'pljson_ext.get_json_value(obj, ''a[1][2][2]'').is_null');
    assertTrue(pljson_ext.get_json_value(obj, 'a[1][2][1]').is_null, 'pljson_ext.get_json_value(obj, ''a[1][2][1]'').is_null');
    assertTrue(pljson_ext.get_json_value(obj, 'a[1][1]').is_null, 'pljson_ext.get_json_value(obj, ''a[1][1]'').is_null');
    pljson_ext.put(obj, 'f[1]', pljson_list('[1,null,[[12, 2.718281828459e210],2],null]'));
    assertTrue(nvl(pljson_ext.get_number(obj, 'f[1][3][1][1]'),0) = 12, 'nvl(pljson_ext.get_number(obj, ''f[1][3][1][1]''),0) = 12');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    assertTrue(nvl(pljson_ext.get_double(obj, 'f[1][3][1][2]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''f[1][3][1][2]''),0) = 2.718281828459e210d');
  end;
  
  -- put exceptions
  procedure test_put_exceptions is
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
      fail(test_name);
    exception
      when others then
        pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''[2]..[3].c.d'', date ''2009-08-31'')';
      pljson_ext.put(obj, '[2]..[3].c.d', date '2009-08-31');
      obj.print;
      fail(test_name);
    exception
      when others then
        pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''a[1][2][3].c.d.'', date ''2009-08-31'')';
      pljson_ext.put(obj, 'a[1][2][3].c.d.', date '2009-08-31');
      obj.print;
      fail(test_name);
    exception
      when others then
        pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''a[0][2][3]'', date ''2009-08-31'')';
      pljson_ext.put(obj, 'a[0][2][3]', date '2009-08-31');
      fail(test_name);
    exception
      when others then
        pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''a[0][2][3]'', date ''2009-08-31'')';
      pljson_ext.put(obj, 'a[0][2][3]', date '2009-08-31');
      fail(test_name);
    exception
      when others then
        pass(test_name);
    end;
    
    begin
      test_name := 'pljson_ext.put(obj, ''a[0.3][2][3]'', date ''2009-08-31'')';
      pljson_ext.put(obj, 'a[0.3][2][3]', date '2009-08-31');
      fail(test_name);
    exception
      when others then
        pass(test_name);
    end;
  end;
  
  -- remove simple
  procedure test_remove_simple is
    obj pljson := pljson('{"2":[1,2,3]}');
  begin
    pljson_ext.remove(obj, '2[2]');
    assertTrue(nvl(pljson_ext.get_number(obj, '2[2]'),0) = 3, 'nvl(pljson_ext.get_number(obj, ''2[2]''),0) = 3');
    pljson_ext.remove(obj, '2');
    assertTrue(obj.count = 0, 'obj.count = 0');
  end;
   
  -- remove advanced
  -- puts json_null in place (only if path exists)
  procedure test_remove_advanced is
    obj pljson := pljson('{"a":true, "b":[[]]}');
  begin
    pljson_ext.remove(obj, 'a');
    assertFalse(obj.exist('a'), 'obj.exist(''a'')');
    assertTrue(obj.count = 1, 'obj.count = 1');
    pljson_ext.remove(obj, 'b[1]');
    assertFalse(obj.exist('b'), 'obj.exist(''b'')');
  end;
  
  -- get with index
  procedure test_get_index is
    obj pljson := pljson('{"a": [1,[{"a":{"i":[{"A":2, "E": 2.718281828459e210}]}},15] ] }');
  begin
    assertTrue(nvl(pljson_ext.get_number(obj, 'a[2][1].a.i[1].A'),0) = 2, 'nvl(pljson_ext.get_number(obj, ''a[2][1].a.i[1].A''),0) = 2');
    assertTrue(nvl(pljson_ext.get_number(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]'),0) = 2, 'nvl(pljson_ext.get_number(obj, ''[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]''),0) = 2');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    assertTrue(nvl(pljson_ext.get_double(obj, 'a[2][1].a.i[1].E'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''a[2][1].a.i[1].E''),0) = 2.718281828459e210d');
    assertTrue(nvl(pljson_ext.get_double(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["E"]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''[ "a"  ][2][1 ] [ "a" ]["i"][1]["E"]''),0) = 2.718281828459e210d');
  end;
  
  -- put with index
  procedure test_put_index is
    obj pljson := pljson('{"a": [1,[{"a":{"i":[{"A":2}]}},15] ] }');
  begin
    pljson_ext.put(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]', 78);
    assertTrue(nvl(pljson_ext.get_number(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]'),0) = 78, 'nvl(pljson_ext.get_number(obj, ''[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]''),0) = 78');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ext.put(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]', 2.718281828459e210d);
    assertTrue(nvl(pljson_ext.get_double(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]'),0) = 2.718281828459e210d, 'nvl(pljson_ext.get_double(obj, ''[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]''),0) = 2.718281828459e210d');
  end;
  
end ut_pljson_path_test;
/