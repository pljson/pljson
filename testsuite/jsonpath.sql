/**
 * Test of JSON Path imple. in JSON_Ext by Jonas Krogsboell
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
  
  str := 'Getters simple';
  declare
    obj json;
  begin
    obj := json('{"a": true, "b": {"c": 123}}');
    assertTrue(json_ext.get_json_value(obj, 'a').get_bool);
    assertTrue(json_ext.get_json(obj, 'a') is null);
    assertTrue(json_ext.get_json(obj, 'b') is not null);
    assertTrue(nvl(json_ext.get_number(obj, 'b.c'),0)=123);
    assertTrue(json_ext.get_string(obj, 'b.c') is null);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Getters with arrays';
  declare
    obj json;
  begin
    obj := json('{"a": [1,[true,15]]}');
    assertTrue(json_ext.get_json_value(obj, 'a').is_array);
    assertTrue(json_ext.get_json_list(obj, 'a') is not null);
    assertTrue(nvl(json_ext.get_number(obj, 'a[1]'),0)=1);
    assertTrue(nvl(json_ext.get_number(obj, 'a[2][2]'),0)=15);
    assertTrue(json_ext.get_json_value(obj, 'a[2][1]').get_bool);
--    assertFalse(nvl(json_ext.get_number(obj, 'a[0][13]'),0)=15); --will throw exception on invalid json path
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Getters with mixed structures';
  declare
    obj json;
  begin
    obj := json('{"a": [1,[{"a":{"i":[{"A":2}]}},15] ] }');
    --obj.print;
    assertTrue(json_ext.get_json_value(obj, 'a').is_array);
    assertTrue(json_ext.get_json_list(obj, 'a') is not null);
    assertTrue(nvl(json_ext.get_number(obj, 'a[2][2]'),0)=15);
    assertTrue(nvl(json_ext.get_number(obj, 'a[2][1].a.i[1].A'),0)=2);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Getters with spaces';
  declare
    obj json;
  begin
    obj := json('{" a ": true, "b     ":{" s  ":[{" 3 ":7913}]}}');
    assertTrue(json_ext.get_json_value(obj, ' a ').get_bool);
    assertTrue(nvl(json_ext.get_number(obj, 'b     . s  [  1   ]. 3 '),0)=7913);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Getter: all types';
  declare
    obj json;
  begin
    obj := json('{"a": ["Str", 1, false, null, {}, [], "2009-08-31 12:34:56"] }');
    --obj.print;
    assertTrue(json_ext.get_string(obj, 'a[1]') is not null);
    assertTrue(json_ext.get_number(obj, 'a[2]') is not null);
    assertTrue(json_ext.get_json_value(obj, 'a[3]').is_bool);
    assertTrue(json_ext.get_json_value(obj, 'a[4]').is_null);
    assertTrue(json_ext.get_json(obj, 'a[5]') is not null);
    assertTrue(json_ext.get_json_list(obj, 'a[6]') is not null);
    assertTrue(json_ext.get_date(obj, 'a[7]') is not null);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Putter simple';
  declare
    obj json := json();
  begin
    json_ext.put(obj, 'a', 'x');
    assertTrue(nvl(json_ext.get_string(obj, 'a'),'a') = 'x');
    json_ext.put(obj, 'a', 'y');
    assertTrue(nvl(json_ext.get_string(obj, 'a'),'a') = 'y');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Putter array';
  declare
    obj json := json();
  begin
    json_ext.put(obj, 'a', json_list('["x"]'));
    assertTrue(nvl(json_ext.get_string(obj, 'a[1]'),'a') = 'x');
    json_ext.put(obj, 'a[1]', 'y');
    assertTrue(nvl(json_ext.get_string(obj, 'a[1]'),'a') = 'y');
    json_ext.put(obj, 'a[3]', 'z');
    assertTrue(nvl(json_ext.get_string(obj, 'a[1]'),'a') = 'y');
    assertTrue(json_ext.get_json_value(obj, 'a[2]') is not null);
    assertTrue(nvl(json_ext.get_string(obj, 'a[3]'),'a') = 'z');
    json_ext.put(obj, 'a[2]', json_ext.get_string(obj, 'a[1]'));
    json_ext.put(obj, 'a[1]', 'x');
    assertTrue(nvl(json_ext.get_string(obj, 'a[1]'),'a') = 'x');
    assertTrue(nvl(json_ext.get_string(obj, 'a[2]'),'a') = 'y');
    assertTrue(nvl(json_ext.get_string(obj, 'a[3]'),'a') = 'z');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Putter advanced';
  declare
    obj json := json();
  begin
    json_ext.put(obj, 'a.b[1].c', true);
    assertTrue(json_ext.get_json_list(obj, 'a.b') is not null);
    json_ext.put(obj, 'a.b[1].c', false);
--    dbms_output.put_line('Put false');
--    obj.print;
    assertTrue(json_ext.get_json_list(obj, 'a.b') is not null);
    assertFalse(json_ext.get_json_value(obj, 'a.b[1].c').get_bool);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Putter: all types';
  declare
    obj json := json();
  begin
    json_ext.put(obj, 'a', true);
    assertTrue(json_ext.get_json_value(obj, 'a').get_bool);
    json_ext.put(obj, 'a', json_value.makenull);
    assertTrue(json_ext.get_json_value(obj, 'a').is_null);
    json_ext.put(obj, 'a', 'string');
    assertTrue(nvl(json_ext.get_string(obj, 'a'),'a') = 'string');
    json_ext.put(obj, 'a', 123.456);
    assertTrue(nvl(json_ext.get_number(obj, 'a'),0) = 123.456);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Putter build';
  declare
    obj json := json();
  begin
    json_ext.put(obj, 'a[1][2][3].c.d', date '2009-08-31');
    assertTrue(nvl(json_ext.get_date(obj, 'a[1][2][3].c.d'),date '2000-01-01') = date '2009-08-31');
    assertTrue(json_ext.get_json_value(obj, 'a[1][2][2]').is_null);
    assertTrue(json_ext.get_json_value(obj, 'a[1][2][1]').is_null);
    assertTrue(json_ext.get_json_value(obj, 'a[1][1]').is_null);
    json_ext.put(obj, 'f[1]', json_list('[1,null,[[12],2],null]'));
    assertTrue(nvl(json_ext.get_number(obj, 'f[1][3][1][1]'),0) = 12);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Putter exceptions';
  declare
    obj json := json();
    failure boolean := false;
  begin
    --empty string
    --..
    --. end
    --. nonpositive int
    --. float as index
    --. string is index
    begin
      json_ext.put(obj, '', date '2009-08-31');
      obj.print;
      failure := true;
    exception 
      when others then null;
    end;
    
    begin
      json_ext.put(obj, '[2]..[3].c.d', date '2009-08-31');
      obj.print;
      failure := true;
    exception 
      when others then null;
    end;

    begin
      json_ext.put(obj, 'a[1][2][3].c.d.', date '2009-08-31');
      obj.print;
      failure := true;
    exception 
      when others then null;
    end;

    begin
      json_ext.put(obj, 'a[0][2][3]', date '2009-08-31');
      failure := true;
    exception 
      when others then null;
    end;

    begin
      json_ext.put(obj, 'a[0][2][3]', date '2009-08-31');
      failure := true;
    exception 
      when others then null;
    end;

    begin
      json_ext.put(obj, 'a[0.3][2][3]', date '2009-08-31');
      failure := true;
    exception 
      when others then null;
    end;

    if(failure) then fail(str); else pass(str); end if;
  end;

  ---remove method
  str := 'Remove simple';
  declare
    obj json := json('{"2":[1,2,3]}');
  begin
    json_ext.remove(obj, '2[2]');
    assertTrue(nvl(json_ext.get_number(obj, '2[2]'),0) = 3);
    json_ext.remove(obj, '2');
    assertTrue(obj.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Remove advanced'; --puts json_null in place (only if path exists)
  declare
    obj json := json('{"a":true, "b":[[]]}');
  begin
    json_ext.remove(obj, 'a');
    assertFalse(obj.exist('a'));
    assertTrue(obj.count = 1);
    json_ext.remove(obj, 'b[1]');
    assertFalse(obj.exist('b'));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Getter index with [" "]';
  declare 
    obj json := json('{"a": [1,[{"a":{"i":[{"A":2}]}},15] ] }');
  begin
    assertTrue(nvl(json_ext.get_number(obj, 'a[2][1].a.i[1].A'),0) = 2);
    assertTrue(nvl(json_ext.get_number(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]'),0) = 2);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Putter index with [" "]';
  declare 
    obj json := json('{"a": [1,[{"a":{"i":[{"A":2}]}},15] ] }');
  begin
    json_ext.put(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]', 78);
    assertTrue(nvl(json_ext.get_number(obj, '[ "a"  ][2][1 ] [ "a" ]["i"][1]["A"]'),0)=78);
    pass(str);
  exception
    when others then fail(str);
  end;

  begin
    execute immediate 'insert into json_testsuite values (:1, :2, :3, :4, :5)' using
    'JSON_Path testing', pass_count,fail_count,total_count,'jsonpath.sql';
  exception
    when others then null;
  end;
end;
