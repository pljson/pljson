/**
 * Test of pljson_helper addon package
 **/
set serveroutput on format wrapped
declare
  pass_count number := 0;
  fail_count number := 0;
  total_count number := 0;
  str varchar2(200);
  
  /* useful for debugging to show clearly symbols for CR, NL (CR => '[', NL => '!') */
  function print_symbols(str varchar2) return varchar2 as
    eol constant varchar2(10) := CHR(13) || CHR(10);
  begin
    return replace(replace(replace(str, '\n', eol), CHR(13), '['), CHR(10), '!');
  end;
  
  /* use to pass tests even if pljson print output changes and produces extra/fewer eols(s) */
  function strip_eol(str varchar2) return varchar2 as
    eol constant varchar2(10) := CHR(13) || CHR(10);
  begin
    --dbms_output.put_line('string='||print_symbols(replace(str, '\n', eol)));
    return replace(str, eol, '');
  end;
  
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
  
  str := 'merge empty objects';
  declare
    obj pljson;
  begin
    obj := pljson('{}');
    obj := pljson_helper.merge(obj, obj);
    assertTrue(obj.count = 0);
    assertTrue(obj.to_char(false) = '{}');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'merge simple objects';
  declare
    obj pljson;
  begin
    obj := pljson_helper.merge(pljson('{"a":1,"b":"str","c":{}}'),pljson('{"d":2,"e":"x"}'));
    assertTrue(obj.count = 5);
    assertTrue(strip_eol(obj.to_char(false)) = '{"a":1,"b":"str","c":{},"d":2,"e":"x"}');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'merge overwrites values';
  declare
    obj pljson;
  begin
    obj := pljson_helper.merge(pljson('{"a":1,"b":"x"}'),pljson('{"a":2,"c":"y"}'));
    assertTrue(obj.count = 3);
    assertTrue(obj.get('a').get_number = 2);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'merge nested objects';
  declare
    obj pljson;
    val pljson_value;
  begin
    obj := pljson_helper.merge(pljson('{"a":{"a1":1,"a2":{}}}'),pljson('{"a":{"a2":{"a2a":1},"a3":2}}'));
    val := obj.get('a');
    assertTrue(pljson(val).count = 3);
    assertTrue(val.to_char(false) = '{"a1":1,"a2":{"a2a":1},"a3":2}');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'join empty lists';
  declare
    obj pljson_list;
  begin
    obj := pljson_helper.join(pljson_list('[]'),pljson_list('[]'));
    assertTrue(obj.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'join simple lists';
  declare
    obj pljson_list;
  begin
    obj := pljson_helper.join(pljson_list('[1,2,3]'),pljson_list('[4,5,6]'));
    assertTrue(obj.count = 6);
    assertTrue(obj.to_char(false) = '[1,2,3,4,5,6]');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'join complex lists';
  declare
    obj pljson_list;
  begin
    obj := pljson_helper.join(pljson_list('[1,"2",{"a":1}]'),pljson_list('[3,"4",{"b":2}]'));
    assertTrue(obj.count = 6);
    assertTrue(strip_eol(obj.to_char(false)) = '[1,"2",{"a":1},3,"4",{"b":2}]');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'keep empty list';
  declare
    obj pljson;
  begin
    obj := pljson_helper.keep(pljson('{"a":1,"b":2,"c":{}}'),pljson_list('[]'));
    assertTrue(obj.count = 0);
    assertTrue(obj.to_char(false) = '{}');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'keep simple list';
  declare
    obj pljson;
  begin
    obj := pljson_helper.keep(pljson('{"a":1,"b":2,"c":3}'),pljson_list('["a","c"]'));
    assertTrue(obj.count = 2);
    assertTrue(obj.to_char(false) = '{"a":1,"c":3}');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'remove empty list';
  declare
    obj pljson;
  begin
    obj := pljson_helper.remove(pljson('{"a":1,"b":2,"c":3}'),pljson_list('[]'));
    assertTrue(obj.count = 3);
    assertTrue(obj.to_char(false) = '{"a":1,"b":2,"c":3}');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'remove simple list';
  declare
    obj pljson;
  begin
    obj := pljson_helper.remove(pljson('{"a":1,"b":2,"c":3}'),pljson_list('["a","c"]'));
    assertTrue(obj.count = 1);
    assertTrue(obj.get('b').get_number = 2);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_value, pljson_value)';
  begin
    assertTrue(pljson_helper.equals(pljson_value(''),pljson_value('')));
    assertTrue(pljson_helper.equals(pljson('{"a":1,"b":2}').to_json_value,pljson('{"a":1,"b":2}').to_json_value));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_value, pljson_value) - empty constructor';
  begin
    assertTrue(pljson_helper.equals(pljson_value(),pljson_value()));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_value, pljson)';
  begin
    assertTrue(pljson_helper.equals(pljson('{"a":1,"b":2}').to_json_value,pljson('{"a":1,"b":2}')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_value, pljson_list)';
  begin
    assertTrue(pljson_helper.equals(pljson_list('[1,2,3]').to_json_value,pljson_list('[1,2,3]')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_value, number)';
  begin
    assertTrue(pljson_helper.equals(pljson_value(2),2));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_value, varchar2)';
  begin
    assertTrue(pljson_helper.equals(pljson_value('xyz'),'xyz'));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_value, varchar2) - empty string value';
  begin
    assertTrue(pljson_helper.equals(pljson_value(''),''));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_value, boolean)';
  begin
    assertTrue(pljson_helper.equals(pljson_value(true),true));
    assertTrue(pljson_helper.equals(pljson_value(false),false));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_value, clob)';
  declare
    lob clob := 'long string value';
  begin
    assertTrue(pljson_helper.equals(pljson_value(lob),lob));
    assertTrue(pljson_helper.equals(pljson_value('long string value'),lob));
    assertFalse(pljson_helper.equals(pljson_value('not long string value'),lob));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson, pljson)';
  begin
    assertTrue(pljson_helper.equals(pljson('{}'),pljson('{}')));
    assertTrue(pljson_helper.equals(pljson('{"a":1}'),pljson('{"a":1}')));
    assertTrue(pljson_helper.equals(pljson('{"a":1,"b":{"b1":[1,2,3]}}'),pljson('{"a":1,"b":{"b1":[1,2,3]}}')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson, pljson) - order does not matter';
  begin
    assertTrue(pljson_helper.equals(pljson('{"a":1,"b":2}'),pljson('{"b":2,"a":1}')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_list, pljson_list)';
  begin
    assertTrue(pljson_helper.equals(pljson_list('[1,2,3]'),pljson_list('[1,2,3]')));
    assertFalse(pljson_helper.equals(pljson_list('[1,2,3]'),pljson_list('[1,2]')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'equals(pljson_list, pljson_list) - order sensitive';
  begin
    assertFalse(pljson_helper.equals(pljson_list('[1,2,3]'),pljson_list('[1,3,2]')));
    assertFalse(pljson_helper.equals(pljson_list('[1,2,3]'),pljson_list('[1,3,2]'),true));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson, pljson_value)';
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[1,2]').to_json_value));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson, pljson)';
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson('{"a":[1,2]}')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson, pljson_list)';
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[1,2]')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson, pljson_list) - sublist match exact';
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[1]'),false));
    assertFalse(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[1]'),true));
    assertFalse(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),pljson_list('[2]'),true));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson, number)';
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3}'),3));
    assertFalse(pljson_helper.contains(pljson('{"a":[1,2],"b":4}'),3));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson, varchar2)';
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":[1,2],"b":3,"c":"xyz"}'),'xyz'));
    assertFalse(pljson_helper.contains(pljson('{"a":[1,2],"b":3,"c":"wxyz"}'),'xyz'));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson, boolean)';
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":true,"b":3}'),true));
    assertFalse(pljson_helper.contains(pljson('{"a":true,"b":3}'),false));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson, clob)';
  declare
    lob clob := 'a long string';
  begin
    assertTrue(pljson_helper.contains(pljson('{"a":1,"b":"a long string"}'),lob));
    assertFalse(pljson_helper.contains(pljson('{"a":1,"b":"not a long string"}'),lob));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson_list, pljson_value)';
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),pljson_value(3)));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson_list, pljson)';
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),pljson('{"a":6}')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson_list, pljson_list)';
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),pljson_list('[4,5]')));
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,7],{"a":6}]'),pljson_list('[4,5]')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson_list, pljson_list) - sublist match exact';
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,[4,5,7]]'),pljson_list('[4,5]'),false));
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,[4,5,7]]'),pljson_list('[4,5]'),true));
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,[4,5,7]]'),pljson_list('[5,4]'),false));
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,[4,5,7]]'),pljson_list('[5,4]'),true));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson_list, number)';
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),3));
    assertFalse(pljson_helper.contains(pljson_list('[1,2,7,"xyz",[4,5],{"a":6}]'),3));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson_list, varchar2)';
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],{"a":6}]'),'xyz'));
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,"wxyz",[4,5],{"a":6}]'),'xyz'));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson_list, boolean)';
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],true]'),true));
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,"xyz",[4,5],false]'),true));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'contains(pljson_list, clob)';
  declare
    lob clob := 'a long string';
  begin
    assertTrue(pljson_helper.contains(pljson_list('[1,2,3,"a long string",[4,5],{"a":6}]'),lob));
    assertFalse(pljson_helper.contains(pljson_list('[1,2,3,"not a long string",[4,5],{"a":6}]'),lob));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  begin
    execute immediate 'insert into pljson_testsuite values (:1, :2, :3, :4, :5)' using
    'pljson_helper test', pass_count, fail_count, total_count, 'pljson_helper_test.sql';
  exception
    when others then null;
  end;
end;
/
