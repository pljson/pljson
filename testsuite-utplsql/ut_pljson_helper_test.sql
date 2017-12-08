
create or replace package ut_pljson_helper_test is
  
  --%suite(pljson_helper test)
  --%suitepath(core)
  
  --%test(Test merge empty objects)
  procedure test_merge_empty;
  
  --%test(Test merge simple objects)  
  procedure test_merge_simple;
  
  --%test(Test merge overwrites values)  
  procedure test_merge_overwrites;
  
  --%test(Test merge nested objects) 
  procedure test_merge_nested;
  
  --%test(Test join empty lists)   
  procedure test_join_empty_lists;
  
  --%test(Test join simple lists)
  procedure test_join_simple_lists;
  
  --%test(Test join complex lists)
  procedure test_join_complex_lists;
  
  --%test(Test keep empty list)
  procedure test_keep_empty_list;
  
  --%test(Test keep simple list)
  procedure test_keep_simple_list;
  
  --%test(Test remove empty list)
  procedure test_remove_empty_list;
  
  --%test(Test remove simple list)
  procedure test_remove_simple_list;
  
  --%test(Test equals(pljson_value, pljson_value))
  procedure test_equals_value_value;
  
  --%test(Test equals(pljson_value, pljson_value) - empty constructor)
  procedure test_equals_value_value_empty;
  
  --%test(Test equals(pljson_value, pljson))
  procedure test_equals_value_pljson;
  
  --%test(Test equals(pljson_value, pljson_list))
  procedure test_equals_value_list;
  
  --%test(Test equals(pljson_value, number))
  procedure test_equals_value_number;
  
  --%test(Test equals(pljson_value, binary_double))
  procedure test_equals_value_double;
  
  --%test(Test equals(pljson_value, varchar2))
  procedure test_equals_value_varchar2;
  
  --%test(Test equals(pljson_value, varchar2) - empty string value)
  procedure test_equals_value_varchar2_nil;
  
  --%test(Test equals(pljson_value, boolean))
  procedure test_equals_value_boolean;
  
  --%test(Test equals(pljson_value, clob))
  procedure test_equals_value_clob;
  
  --%test(Test equals(pljson, pljson))
  procedure test_equals_pljson_order;
  
  --%test(Test equals(pljson, pljson) - order does not matter)
  procedure test_equals_pljson_no_order;
  
  --%test(Test equals(pljson_list, pljson_list))
  procedure test_equals_list_list_order;
  
  --%test(Test equals(pljson_list, pljson_list) - order sensitive)
  procedure test_equals_list_list_no_order;
  
  --%test(Test contains(pljson, pljson_value))
  procedure test_contains_value;
  
  --%test(Test contains(pljson, pljson))
  procedure test_contains_pljson;
  
  --%test(Test contains(pljson, pljson_list))
  procedure test_contains_list;
  
  --%test(Test contains(pljson, pljson_list) - sublist match exact)
  procedure test_contains_list_exact;
  
  --%test(Test contains(pljson, number))
  procedure test_contains_number;
  
  --%test(Test contains(pljson, binary_double))
  procedure test_contains_double;
  
  --%test(Test contains(pljson, varchar2))
  procedure test_contains_varchar2;
  
  --%test(Test contains(pljson, boolean))
  procedure test_contains_boolean;
  
  --%test(Test contains(pljson, clob))
  procedure test_contains_clob;
  
  --%test(Test contains(pljson_list, pljson_value))
  procedure test_contains_list_value;
  
  --%test(Test contains(pljson_list, pljson))
  procedure test_contains_list_pljson;
  
  --%test(Test contains(pljson_list, pljson_list))
  procedure test_contains_list_list;
  
  --%test(Test contains(pljson_list, pljson_list) - sublist match exact)
  procedure test_contains_list_list_exact;
  
  --%test(Test contains(pljson_list, number))
  procedure test_contains_list_number;
  
  --%test(Test contains(pljson_list, binary_double))
  procedure test_contains_list_double;
  
  --%test(Test contains(pljson_list, varchar2))
  procedure test_contains_list_varchar2;
  
  --%test(Test contains(pljson_list, boolean))
  procedure test_contains_list_boolean;
  
  --%test(Test contains(pljson_list, clob))
  procedure test_contains_list_clob;
  
end ut_pljson_helper_test;
/

create or replace package body ut_pljson_helper_test is
  
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
  
  /* useful for debugging to show clearly symbols for CR, NL (CR => '[', NL => '!') */
  function print_symbols(str varchar2) return varchar2 as
    eol constant varchar2(10) := CHR(13) || CHR(10);
  begin
    return replace(replace(replace(str, '\n', eol), CHR(13), '['), CHR(10), '!');
  end;
  
  /* use to pass tests even if json print output changes and produces extra/fewer eols(s) */
  function strip_eol(str varchar2) return varchar2 as
    eol constant varchar2(10) := CHR(13) || CHR(10);
  begin
    --dbms_output.put_line('string='||print_symbols(replace(str, '\n', eol)));
    return replace(str, eol, '');
  end;
  
  -- merge empty objects
  procedure test_merge_empty is
    obj pljson;
  begin
    obj := pljson('{}');
    obj := pljson_helper.merge(obj, obj);
    assertTrue(obj.count = 0, 'obj.count = 0');
    assertTrue(obj.to_char(false) = '{}', 'obj.to_char(false) = ''{}''');
  end;
  
  -- merge simple objects
  procedure test_merge_simple is
    obj pljson;
  begin
    obj := pljson_helper.merge(pljson('{"a":1,"b":"str","c":{}}'),pljson('{"d":2,"e":"x"}'));
    assertTrue(obj.count = 5, 'obj.count = 5');
    assertTrue(strip_eol(obj.to_char(false)) = '{"a":1,"b":"str","c":{},"d":2,"e":"x"}', 'strip_eol(obj.to_char(false)) = ''{"a":1,"b":"str","c":{},"d":2,"e":"x"}''');
  end;
  
  -- merge overwrites values
  procedure test_merge_overwrites is
    obj pljson;
  begin
    obj := pljson_helper.merge(pljson('{"a":1,"b":"x"}'),pljson('{"a":2,"c":"y"}'));
    assertTrue(obj.count = 3, 'obj.count = 3');
    assertTrue(obj.get('a').get_number = 2, 'obj.get(''a'').get_number = 2');
  end;
  
  -- merge nested objects
  procedure test_merge_nested is
    obj pljson;
    val pljson_value;
  begin
    obj := pljson_helper.merge(pljson('{"a":{"a1":1,"a2":{}}}'),pljson('{"a":{"a2":{"a2a":1},"a3":2}}'));
    val := obj.get('a');
    assertTrue(pljson(val).count = 3, 'pljson(val).count = 3');
    assertTrue(val.to_char(false) = '{"a1":1,"a2":{"a2a":1},"a3":2}', 'val.to_char(false) = ''{"a1":1,"a2":{"a2a":1},"a3":2}''');
  end;
  
  -- join empty lists
  procedure test_join_empty_lists is
    obj pljson_list;
  begin
    obj := pljson_helper.join(pljson_list('[]'),pljson_list('[]'));
    assertTrue(obj.count = 0, 'obj.count = 0');
  end;
  
  -- join simple lists
  procedure test_join_simple_lists is
    obj pljson_list;
  begin
    obj := pljson_helper.join(pljson_list('[1,2,3]'),pljson_list('[4,5,6]'));
    assertTrue(obj.count = 6, 'obj.count = 6');
    assertTrue(obj.to_char(false) = '[1,2,3,4,5,6]', 'obj.to_char(false) = ''[1,2,3,4,5,6]''');
  end;
  
  -- join complex lists
  procedure test_join_complex_lists is
    obj pljson_list;
  begin
    obj := pljson_helper.join(pljson_list('[1,"2",{"a":1}]'),pljson_list('[3,"4",{"b":2}]'));
    assertTrue(obj.count = 6, 'obj.count = 6');
    assertTrue(strip_eol(obj.to_char(false)) = '[1,"2",{"a":1},3,"4",{"b":2}]', 'strip_eol(obj.to_char(false)) = ''[1,"2",{"a":1},3,"4",{"b":2}]''');
  end;
  
  -- keep empty list
  procedure test_keep_empty_list is
    obj pljson;
  begin
    obj := pljson_helper.keep(pljson('{"a":1,"b":2,"c":{}}'),pljson_list('[]'));
    assertTrue(obj.count = 0, 'obj.count = 0');
    assertTrue(obj.to_char(false) = '{}', 'obj.to_char(false) = ''{}''');
  end;
  
  -- keep simple list
  procedure test_keep_simple_list is
    obj pljson;
  begin
    obj := pljson_helper.keep(pljson('{"a":1,"b":2,"c":3}'),pljson_list('["a","c"]'));
    assertTrue(obj.count = 2, 'obj.count = 2');
    assertTrue(obj.to_char(false) = '{"a":1,"c":3}', 'obj.to_char(false) = ''{"a":1,"c":3}''');
  end;
  
  -- remove empty list
  procedure test_remove_empty_list is
    obj pljson;
  begin
    obj := pljson_helper.remove(pljson('{"a":1,"b":2,"c":3}'),pljson_list('[]'));
    assertTrue(obj.count = 3, 'obj.count = 3');
    assertTrue(obj.to_char(false) = '{"a":1,"b":2,"c":3}', 'obj.to_char(false) = ''{"a":1,"b":2,"c":3}''');
  end;
  
  -- remove simple list
  procedure test_remove_simple_list is
    obj pljson;
  begin
    obj := pljson_helper.remove(pljson('{"a":1,"b":2,"c":3}'),pljson_list('["a","c"]'));
    assertTrue(obj.count = 1, 'obj.count = 1');
    assertTrue(obj.get('b').get_number = 2, 'obj.get(''b'').get_number = 2');
  end;
  
  -- equals(pljson_value, pljson_value)
  procedure test_equals_value_value is
  begin
    assertTrue(pljson_helper.equals(pljson_value(''),pljson_value('')), 'pljson_helper.equals(pljson_value(''''),pljson_value(''''))');
    assertTrue(pljson_helper.equals(pljson('{"a":1,"b":2}').to_json_value,pljson('{"a":1,"b":2}').to_json_value), 'pljson_helper.equals(pljson(''{"a":1,"b":2}'').to_json_value,pljson(''{"a":1,"b":2}'').to_json_value)');
  end;
  
  -- equals(pljson_value, pljson_value) - empty constructor
  procedure test_equals_value_value_empty is
  begin
    assertTrue(pljson_helper.equals(pljson_value(),pljson_value()), 'pljson_helper.equals(pljson_value(),pljson_value())');
  end;
  
  -- equals(pljson_value, pljson)
  procedure test_equals_value_pljson is
  begin
    assertTrue(pljson_helper.equals(pljson('{"a":1,"b":2}').to_json_value,pljson('{"a":1,"b":2}')), 'pljson_helper.equals(pljson(''{"a":1,"b":2}'').to_json_value,pljson(''{"a":1,"b":2}''))');
  end;
  
  -- equals(pljson_value, pljson_list)
  procedure test_equals_value_list is
  begin
    assertTrue(pljson_helper.equals(pljson_list('[1,2,3]').to_json_value,pljson_list('[1,2,3]')), 'pljson_helper.equals(pljson_list(''[1,2,3]'').to_json_value,pljson_list(''[1,2,3]''))');
  end;
  
  -- equals(pljson_value, number)
  procedure test_equals_value_number is
  begin
    assertTrue(pljson_helper.equals(pljson_value(2),2), 'pljson_helper.equals(pljson_value(2),2)');
  end;
  
  -- equals(pljson_value, binary_double)
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure test_equals_value_double is
  begin
    assertTrue(pljson_helper.equals(pljson_value(2.718281828459e210d), 2.718281828459e210d), 'pljson_helper.equals(pljson_value(2.718281828459e210d), 2.718281828459e210d)');
  end;
  
  -- equals(pljson_value, varchar2)
  procedure test_equals_value_varchar2 is
  begin
    assertTrue(pljson_helper.equals(pljson_value('xyz'),'xyz'), 'pljson_helper.equals(pljson_value(''xyz''),''xyz'')');
  end;
  
  -- equals(pljson_value, varchar2) - empty string value
  procedure test_equals_value_varchar2_nil is
  begin
    assertTrue(pljson_helper.equals(pljson_value(''),''), 'pljson_helper.equals(pljson_value(''''),'''')');
  end;
  
  -- equals(pljson_value, boolean)
  procedure test_equals_value_boolean is
  begin
    assertTrue(pljson_helper.equals(pljson_value(true),true), 'pljson_helper.equals(pljson_value(true),true)');
    assertTrue(pljson_helper.equals(pljson_value(false),false), 'pljson_helper.equals(pljson_value(false),false)');
  end;
  
  -- equals(pljson_value, clob)
  procedure test_equals_value_clob is
    lob clob := 'long string value';
  begin
    assertTrue(pljson_helper.equals(pljson_value(lob),lob), 'pljson_helper.equals(pljson_value(lob),lob)');
    assertTrue(pljson_helper.equals(pljson_value('long string value'),lob), 'pljson_helper.equals(pljson_value(''long string value''),lob)');
    assertFalse(pljson_helper.equals(pljson_value('not long string value'),lob), 'pljson_helper.equals(pljson_value(''not long string value''),lob)');
  end;
  
  -- equals(pljson, pljson)
  procedure test_equals_pljson_order is
  begin
    assertTrue(pljson_helper.equals(pljson('{}'),pljson('{}')), 'pljson_helper.equals(pljson(''{}''),pljson(''{}''))');
    assertTrue(pljson_helper.equals(pljson('{"a":1}'),pljson('{"a":1}')), 'pljson_helper.equals(pljson(''{"a":1}''),pljson(''{"a":1}''))');
    assertTrue(pljson_helper.equals(pljson('{"a":1,"b":{"b1":[1,2,3]}}'),pljson('{"a":1,"b":{"b1":[1,2,3]}}')), 'pljson_helper.equals(pljson(''{"a":1,"b":{"b1":[1,2,3]}}''),pljson(''{"a":1,"b":{"b1":[1,2,3]}}''))');
  end;
  
  -- equals(pljson, pljson) - order does not matter
  procedure test_equals_pljson_no_order is
  begin
    assertTrue(pljson_helper.equals(pljson('{"a":1,"b":2}'),pljson('{"b":2,"a":1}')), 'pljson_helper.equals(pljson(''{"a":1,"b":2}''),pljson(''{"b":2,"a":1}''))');
  end;
  
  -- equals(pljson_list, pljson_list)
  procedure test_equals_list_list_order is
  begin
    assertTrue(pljson_helper.equals(pljson_list('[1,2,3]'),pljson_list('[1,2,3]')), 'pljson_helper.equals(pljson_list(''[1,2,3]''),pljson_list(''[1,2,3]''))');
    assertFalse(pljson_helper.equals(pljson_list('[1,2,3]'),pljson_list('[1,2]')), 'pljson_helper.equals(pljson_list(''[1,2,3]''),pljson_list(''[1,2]''))');
  end;
  
  -- equals(pljson_list, pljson_list) - order sensitive
  procedure test_equals_list_list_no_order is
  begin
    assertFalse(pljson_helper.equals(pljson_list('[1,2,3]'),pljson_list('[1,3,2]')), 'pljson_helper.equals(pljson_list(''[1,2,3]''),pljson_list(''[1,3,2]''))');
    assertFalse(pljson_helper.equals(pljson_list('[1,2,3]'),pljson_list('[1,3,2]'),true), 'pljson_helper.equals(pljson_list(''[1,2,3]''),pljson_list(''[1,3,2]''),true)');
  end;
  
  -- contains(pljson, pljson_value)
  procedure test_contains_value is
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[1,2]').to_json_value), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3}''),pljson_list(''[1,2]'').to_json_value)');
  end;
  
  -- contains(pljson, pljson)
  procedure test_contains_pljson is
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson('{"a":[1,2]}')), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3}''),pljson(''{"a":[1,2]}''))');
  end;
  
  -- contains(pljson, pljson_list)
  procedure test_contains_list is
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[1,2]')), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3}''),pljson_list(''[1,2]''))');
  end;
  
  -- contains(pljson, pljson_list) - sublist match exact
  procedure test_contains_list_exact is
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[1]'),false), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3}''),pljson_list(''[1]''),false)');
    assertFalse(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[1]'),true), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3}''),pljson_list(''[1]''),true)');
    assertFalse(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[2]'),true), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3}''),pljson_list(''[2]''),true)');
  end;
  
  -- contains(pljson, number)
  procedure test_contains_number is
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),3), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3}''),3)');
    assertFalse(pljson_helper.contains(pljson('{"a":[1,2],"b":4}'),3), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":4}''),3)');
  end;
  
  -- contains(pljson, binary_double)
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure test_contains_double is
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":2.718281828459e210}'), 2.718281828459e210d), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":2.718281828459e210}''), 2.718281828459e210d)');
    assertFalse(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'), 2.718281828459e210d), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3}''), 2.718281828459e210d)');
  end;
  
  -- contains(pljson, varchar2)
  procedure test_contains_varchar2 is
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3,"c":"xyz"}'),'xyz'), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3,"c":"xyz"}''),''xyz'')');
    assertFalse(pljson_helper.contains(pljson('{"a":[1,2],"b":3,"c":"wxyz"}'),'xyz'), 'pljson_helper.contains(pljson(''{"a":[1,2],"b":3,"c":"wxyz"}''),''xyz'')');
  end;
  
  -- contains(pljson, boolean)
  procedure test_contains_boolean is
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":true,"b":3}'),true), 'pljson_helper.contains(pljson(''{"a":true,"b":3}''),true)');
    assertFalse(pljson_helper.contains(pljson('{"a":true,"b":3}'),false), 'pljson_helper.contains(pljson(''{"a":true,"b":3}''),false)');
  end;
  
  -- contains(pljson, clob)
  procedure test_contains_clob is
    lob clob := 'a long string';
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":1,"b":"a long string"}'),lob), 'pljson_helper.contains(pljson(''{"a":1,"b":"a long string"}''),lob)');
    assertFalse(pljson_helper.contains(pljson('{"a":1,"b":"not a long string"}'),lob), 'pljson_helper.contains(pljson(''{"a":1,"b":"not a long string"}''),lob)');
  end;
  
  -- contains(pljson_list, pljson_value)
  procedure test_contains_list_value is
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),pljson_value(3)), 'pljson_helper.contains(pljson_list(''[1,2,3,"xyz",[4,5],{"a":6}]''),pljson_value(3))');
  end;
  
  -- contains(pljson_list, pljson)
  procedure test_contains_list_pljson is
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),pljson('{"a":6}')), 'pljson_helper.contains(pljson_list(''[1,2,3,"xyz",[4,5],{"a":6}]''),pljson(''{"a":6}''))');
  end;
  
  -- contains(pljson_list, pljson_list)
  procedure test_contains_list_list is
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),pljson_list('[4,5]')), 'pljson_helper.contains(pljson_list(''[1,2,3,"xyz",[4,5],{"a":6}]''),pljson_list(''[4,5]''))');
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,7],{"a":6}]'),pljson_list('[4,5]')), 'pljson_helper.contains(pljson_list(''[1,2,3,"xyz",[4,7],{"a":6}]''),pljson_list(''[4,5]''))');
  end;
  
  -- contains(pljson_list, pljson_list) - sublist match exact
  procedure test_contains_list_list_exact is
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,[4,5,7]]'),pljson_list('[4,5]'),false), 'pljson_helper.contains(pljson_list(''[1,2,3,[4,5,7]]''),pljson_list(''[4,5]''),false)');
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,[4,5,7]]'),pljson_list('[4,5]'),true), 'pljson_helper.contains(pljson_list(''[1,2,3,[4,5,7]]''),pljson_list(''[4,5]''),true)');
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,[4,5,7]]'),pljson_list('[5,4]'),false), 'pljson_helper.contains(pljson_list(''[1,2,3,[4,5,7]]''),pljson_list(''[5,4]''),false)');
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,[4,5,7]]'),pljson_list('[5,4]'),true), 'pljson_helper.contains(pljson_list(''[1,2,3,[4,5,7]]''),pljson_list(''[5,4]''),true)');
  end;
  
  -- contains(pljson_list, number)
  procedure test_contains_list_number is
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),3), 'pljson_helper.contains(pljson_list(''[1,2,3,"xyz",[4,5],{"a":6}]''),3)');
    assertFalse(pljson_helper.contains(pljson_list('[1,2,7,"xyz",[4,5],{"a":6}]'),3), 'pljson_helper.contains(pljson_list(''[1,2,7,"xyz",[4,5],{"a":6}]''),3)');
  end;
  
  -- contains(pljson_list, binary_double)
  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure test_contains_list_double is
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,2.718281828459e210,"xyz",[4,5],{"a":6}]'), 2.718281828459e210d), 'pljson_helper.contains(pljson_list(''[1,2,2.718281828459e210,"xyz",[4,5],{"a":6}]''), 2.718281828459e210d)');
    assertFalse(pljson_helper.contains(pljson_list('[1,2,7,"xyz",[4,5],{"a":6}]'), 2.718281828459e210d), 'pljson_helper.contains(pljson_list(''[1,2,7,"xyz",[4,5],{"a":6}]''), 2.718281828459e210d)');
  end;
  
  -- contains(pljson_list, varchar2)
  procedure test_contains_list_varchar2 is
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),'xyz'), 'pljson_helper.contains(pljson_list(''[1,2,3,"xyz",[4,5],{"a":6}]''),''xyz'')');
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,"wxyz",[4,5],{"a":6}]'),'xyz'), 'pljson_helper.contains(pljson_list(''[1,2,3,"wxyz",[4,5],{"a":6}]''),''xyz'')');
  end;
  
  -- contains(pljson_list, boolean)
  procedure test_contains_list_boolean is
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],true]'),true), 'pljson_helper.contains(pljson_list(''[1,2,3,"xyz",[4,5],true]''),true)');
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],false]'),true), 'pljson_helper.contains(pljson_list(''[1,2,3,"xyz",[4,5],false]''),true)');
  end;
  
  -- contains(pljson_list, clob)
  procedure test_contains_list_clob is
    lob clob := 'a long string';
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"a long string",[4,5],{"a":6}]'),lob), 'pljson_helper.contains(pljson_list(''[1,2,3,"a long string",[4,5],{"a":6}]''),lob)');
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,"not a long string",[4,5],{"a":6}]'),lob), 'pljson_helper.contains(pljson_list(''[1,2,3,"not a long string",[4,5],{"a":6}]''),lob)');
  end;
  
end ut_pljson_helper_test;
/