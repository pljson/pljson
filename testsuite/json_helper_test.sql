/**
 * Test of json_helper addon package
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
  
  str := 'merge empty objects';
  declare
    obj json;
  begin
    obj := json('{}');
    obj := json_helper.merge(obj, obj);
    assertTrue(obj.count = 0);
    assertTrue(obj.to_char(false) = '{}');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'merge simple objects';
  declare
    obj json;
  begin
    obj := json_helper.merge(json('{"a":1,"b":"str","c":{}}'),json('{"d":2,"e":"x"}'));
    assertTrue(obj.count = 5);
    assertTrue(obj.to_char(false) = '{"a":1,"b":"str","c":{},"d":2,"e":"x"}');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'merge overwrites values';
  declare
    obj json;
  begin
    obj := json_helper.merge(json('{"a":1,"b":"x"}'),json('{"a":2,"c":"y"}'));
    assertTrue(obj.count = 3);
    assertTrue(obj.get('a').get_number = 2);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'merge nested objects';
  declare
    obj json;
    val json_value;
  begin
    obj := json_helper.merge(json('{"a":{"a1":1,"a2":{}}}'),json('{"a":{"a2":{"a2a":1},"a3":2}}'));
    val := obj.get('a');
    assertTrue(json(val).count = 3);
    assertTrue(val.to_char(false) = '{"a1":1,"a2":{"a2a":1},"a3":2}');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'join empty lists';
  declare
    obj json_list;
  begin
    obj := json_helper.join(json_list('[]'),json_list('[]'));
    assertTrue(obj.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'join simple lists';
  declare
    obj json_list;
  begin
    obj := json_helper.join(json_list('[1,2,3]'),json_list('[4,5,6]'));
    assertTrue(obj.count = 6);
    assertTrue(obj.to_char(false) = '[1,2,3,4,5,6]');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'join complex lists';
  declare
    obj json_list;
  begin
    obj := json_helper.join(json_list('[1,"2",{"a":1}]'),json_list('[3,"4",{"b":2}]'));
    assertTrue(obj.count = 6);
    assertTrue(obj.to_char(false) = '[1,"2",{"a":1},3,"4",{"b":2}]');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'keep empty list';
  declare
    obj json;
  begin
    obj := json_helper.keep(json('{"a":1,"b":2,"c":{}}'),json_list('[]'));
    assertTrue(obj.count = 0);
    assertTrue(obj.to_char(false) = '{}');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'keep simple list';
  declare
    obj json;
  begin
    obj := json_helper.keep(json('{"a":1,"b":2,"c":3}'),json_list('["a","c"]'));
    assertTrue(obj.count = 2);
    assertTrue(obj.to_char(false) = '{"a":1,"c":3}');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'remove empty list';
  declare
    obj json;
  begin
    obj := json_helper.remove(json('{"a":1,"b":2,"c":3}'),json_list('[]'));
    assertTrue(obj.count = 3);
    assertTrue(obj.to_char(false) = '{"a":1,"b":2,"c":3}');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'remove simple list';
  declare
    obj json;
  begin
    obj := json_helper.remove(json('{"a":1,"b":2,"c":3}'),json_list('["a","c"]'));
    assertTrue(obj.count = 1);
    assertTrue(obj.get('b').get_number = 2);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_value, json_value)';
  begin
    assertTrue(json_helper.equals(json_value(''),json_value('')));
    assertTrue(json_helper.equals(json('{"a":1,"b":2}').to_json_value,json('{"a":1,"b":2}').to_json_value));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_value, json_value) - empty constructor';
  begin
    assertTrue(json_helper.equals(json_value(),json_value()));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_value, json)';
  begin
    assertTrue(json_helper.equals(json('{"a":1,"b":2}').to_json_value,json('{"a":1,"b":2}')));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_value, json_list)';
  begin
    assertTrue(json_helper.equals(json_list('[1,2,3]').to_json_value,json_list('[1,2,3]')));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_value, number)';
  begin
    assertTrue(json_helper.equals(json_value(2),2));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_value, varchar2)';
  begin
    assertTrue(json_helper.equals(json_value('xyz'),'xyz'));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_value, varchar2) - empty string value';
  begin
    assertTrue(json_helper.equals(json_value(''),''));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_value, boolean)';
  begin
    assertTrue(json_helper.equals(json_value(true),true));
    assertTrue(json_helper.equals(json_value(false),false));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_value, clob)';
  declare
    lob clob := 'long string value';
  begin
    assertTrue(json_helper.equals(json_value(lob),lob));
    assertTrue(json_helper.equals(json_value('long string value'),lob));
    assertFalse(json_helper.equals(json_value('not long string value'),lob));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json, json)';
  begin
    assertTrue(json_helper.equals(json('{}'),json('{}')));
    assertTrue(json_helper.equals(json('{"a":1}'),json('{"a":1}')));
    assertTrue(json_helper.equals(json('{"a":1,"b":{"b1":[1,2,3]}}'),json('{"a":1,"b":{"b1":[1,2,3]}}')));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json, json) - order does not matter';
  begin
    assertTrue(json_helper.equals(json('{"a":1,"b":2}'),json('{"b":2,"a":1}')));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_list, json_list)';
  begin
    assertTrue(json_helper.equals(json_list('[1,2,3]'),json_list('[1,2,3]')));
    assertFalse(json_helper.equals(json_list('[1,2,3]'),json_list('[1,2]')));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'equals(json_list, json_list) - order sensitive';
  begin
    assertFalse(json_helper.equals(json_list('[1,2,3]'),json_list('[1,3,2]')));
    assertFalse(json_helper.equals(json_list('[1,2,3]'),json_list('[1,3,2]'),true));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json, json_value)';
  begin
    assertTrue(json_helper.contains(json('{"a":[1,2],"b":3}'),json_list('[1,2]').to_json_value));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json, json)';
  begin
    assertTrue(json_helper.contains(json('{"a":[1,2],"b":3}'),json('{"a":[1,2]}')));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json, json_list)';
  begin
    assertTrue(json_helper.contains(json('{"a":[1,2],"b":3}'),json_list('[1,2]')));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json, json_list) - sublist match exact';
  begin
    assertTrue(json_helper.contains(json('{"a":[1,2],"b":3}'),json_list('[1]'),false));
    assertFalse(json_helper.contains(json('{"a":[1,2],"b":3}'),json_list('[1]'),true));
    assertFalse(json_helper.contains(json('{"a":[1,2],"b":3}'),json_list('[2]'),true));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json, number)';
  begin
    assertTrue(json_helper.contains(json('{"a":[1,2],"b":3}'),3));
    assertFalse(json_helper.contains(json('{"a":[1,2],"b":4}'),3));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json, varchar2)';
  begin
    assertTrue(json_helper.contains(json('{"a":[1,2],"b":3,"c":"xyz"}'),'xyz'));
    assertFalse(json_helper.contains(json('{"a":[1,2],"b":3,"c":"wxyz"}'),'xyz'));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json, boolean)';
  begin
    assertTrue(json_helper.contains(json('{"a":true,"b":3}'),true));
    assertFalse(json_helper.contains(json('{"a":true,"b":3}'),false));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json, clob)';
  declare
    lob clob := 'a long string';
  begin
    assertTrue(json_helper.contains(json('{"a":1,"b":"a long string"}'),lob));
    assertFalse(json_helper.contains(json('{"a":1,"b":"not a long string"}'),lob));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json_list, json_value)';
  begin
    assertTrue(json_helper.contains(json_list('[1,2,3,"xyz",[4,5],{"a":6}]'),json_value(3)));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json_list, json)';
  begin
    assertTrue(json_helper.contains(json_list('[1,2,3,"xyz",[4,5],{"a":6}]'),json('{"a":6}')));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json_list, json_list)';
  begin
    assertTrue(json_helper.contains(json_list('[1,2,3,"xyz",[4,5],{"a":6}]'),json_list('[4,5]')));
    assertFalse(json_helper.contains(json_list('[1,2,3,"xyz",[4,7],{"a":6}]'),json_list('[4,5]')));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json_list, json_list) - sublist match exact';
  begin
    assertTrue(json_helper.contains(json_list('[1,2,3,[4,5,7]]'),json_list('[4,5]'),false));
    assertFalse(json_helper.contains(json_list('[1,2,3,[4,5,7]]'),json_list('[4,5]'),true));
    assertFalse(json_helper.contains(json_list('[1,2,3,[4,5,7]]'),json_list('[5,4]'),false));
    assertFalse(json_helper.contains(json_list('[1,2,3,[4,5,7]]'),json_list('[5,4]'),true));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json_list, number)';
  begin
    assertTrue(json_helper.contains(json_list('[1,2,3,"xyz",[4,5],{"a":6}]'),3));
    assertFalse(json_helper.contains(json_list('[1,2,7,"xyz",[4,5],{"a":6}]'),3));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json_list, varchar2)';
  begin
    assertTrue(json_helper.contains(json_list('[1,2,3,"xyz",[4,5],{"a":6}]'),'xyz'));
    assertFalse(json_helper.contains(json_list('[1,2,3,"wxyz",[4,5],{"a":6}]'),'xyz'));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json_list, boolean)';
  begin
    assertTrue(json_helper.contains(json_list('[1,2,3,"xyz",[4,5],true]'),true));
    assertFalse(json_helper.contains(json_list('[1,2,3,"xyz",[4,5],false]'),true));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'contains(json_list, clob)';
  declare
    lob clob := 'a long string';
  begin
    assertTrue(json_helper.contains(json_list('[1,2,3,"a long string",[4,5],{"a":6}]'),lob));
    assertFalse(json_helper.contains(json_list('[1,2,3,"not a long string",[4,5],{"a":6}]'),lob));
    pass(str);
  exception
    when others then fail(str);
  end;

  begin
    execute immediate 'insert into json_testsuite values (:1, :2, :3, :4, :5)' using
    'json_helper test', pass_count,fail_count,total_count,'json_helper_test.sql';
  exception
    when others then null;
  end;
end;
/
