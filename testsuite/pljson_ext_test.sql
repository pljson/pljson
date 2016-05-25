/**
 * Test of PLSQL JSON_Ext by Jonas Krogsboell
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
  
  /* use to pass tests even if json print output changes and produces extra/fewer eols(s) */
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
  
  str := 'Is Type Test';
  declare
    mylist pljson_list; --im lazy
  begin
    mylist := pljson_list('["abc", 23, {}, [], true, null]');
    assertTrue(mylist.get(1).is_string);
    assertTrue(mylist.get(2).is_number);
    assertTrue(mylist.get(3).is_object);
    assertTrue(mylist.get(4).is_array);
    assertTrue(mylist.get(5).is_bool);
    assertTrue(mylist.get(6).is_null);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Is Type Test 2 (integers)';
  declare
    mylist pljson_list; --im lazy
  begin
    mylist := pljson_list('[23, 2.1, 0.0, 120, 0.00000001]');
    assertTrue(mylist.get(1).is_number);
    assertTrue(mylist.get(2).is_number);
    assertTrue(mylist.get(3).is_number);
    assertTrue(mylist.get(4).is_number);
    assertTrue(mylist.get(5).is_number);
    
    assertTrue(pljson_ext.is_integer(mylist.get(1)));
    assertFalse(pljson_ext.is_integer(mylist.get(2)));
    assertTrue(pljson_ext.is_integer(mylist.get(3)));
    assertTrue(pljson_ext.is_integer(mylist.get(4)));
    assertFalse(pljson_ext.is_integer(mylist.get(5)));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Date interaction test 1';
  declare
    mylist pljson_list; --im lazy
    old_format_string varchar2(30) := pljson_ext.format_string; --backup
  begin
    pljson_ext.format_string := 'yyyy-mm-dd hh24:mi:ss';
    mylist := pljson_list('["2009-07-01 00:22:33", "2007-04-04hulubalulu", "09-07-08", "2009-07-01", "2007/Jan/03" ]');
    assertFalse(mylist.get(1).is_number); --why not
    
    assertTrue(pljson_ext.is_date(mylist.get(1)));
    assertFalse(pljson_ext.is_date(mylist.get(2)));
    assertTrue(pljson_ext.is_date(mylist.get(3))); --the format_string accept many formats
    assertTrue(pljson_ext.is_date(mylist.get(4)));
    assertTrue(pljson_ext.is_date(mylist.get(5))); --too many
        
    pass(str);
    pljson_ext.format_string := old_format_string;
  exception
    when others then
      fail(str);
      pljson_ext.format_string := old_format_string;
  end;
  
  str := 'Date interaction test 2';
  declare
    mylist pljson_list; --im lazy
    newinsert date := date '2009-08-08';
    old_format_string varchar2(30) := pljson_ext.format_string; --backup
  begin
    pljson_ext.format_string := 'yyyy-mm-dd hh24:mi:ss';
    mylist := pljson_list('["2009-07-01 00:22:33", "2007-04-04hulubalulu", "09-07-08", "2009-07-01", "2007/Jan/03" ]');
    --correct the dates
    mylist.append(pljson_ext.to_json_value(pljson_ext.to_date2(mylist.get(1))), 1);
    mylist.remove(2); --remove the old
    mylist.append(pljson_ext.to_json_value(newinsert), 2);
    mylist.remove(3); --remove the old falsy one
    mylist.append(pljson_ext.to_json_value(pljson_ext.to_date2(mylist.get(3))), 3);
    mylist.remove(4); --remove the old
    mylist.append(pljson_ext.to_json_value(pljson_ext.to_date2(mylist.get(4))), 4);
    mylist.remove(5); --remove the old
    mylist.append(pljson_ext.to_json_value(pljson_ext.to_date2(mylist.get(5))), 5);
    mylist.remove(6); --remove the old
    
    assertTrue(strip_eol(mylist.to_char) = '["2009-07-01 00:22:33", "2009-08-08 00:00:00", "0009-07-08 00:00:00", "2009-07-01 00:00:00", "2007-01-03 00:00:00"]');
    --we can see that 09-07-08 isn't a good idea when format_string doesn't match
    pass(str);
    pljson_ext.format_string := old_format_string;
  exception
    when others then
      fail(str);
      pljson_ext.format_string := old_format_string;
  end;
  
  str := 'Null date insert into pljson'; --apparently null dates work fine
  declare
    obj pljson := pljson();
    v_when date := null;
  begin
    obj.put('X', pljson_ext.to_json_value(v_when));
    v_when := pljson_ext.to_date2(obj.get('X'));
    assertTrue(v_when is null);
    assertTrue(pljson_ext.is_date(obj.get('X')));
    pass(str);
  exception
    when others then fail(str);
  end;
  
  begin
    execute immediate 'insert into pljson_testsuite values (:1, :2, :3, :4, :5)' using
    'pljson_ext test', pass_count, fail_count, total_count, 'pljson_ext_test.sql';
  exception
    when others then null;
  end;
end;
/
