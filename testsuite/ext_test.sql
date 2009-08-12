/**
 * Test of PLSQL JSON_Ext by Jonas Krogsboell
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
  
  str := 'Is Type Test';
  declare
    mylist json_list; --im lazy
  begin
    mylist := json_list('["abc", 23, {}, [], true, null]');
    assertTrue(json_ext.is_varchar2(mylist.get_elem(1)));
    assertTrue(json_ext.is_number(mylist.get_elem(2)));
    assertTrue(json_ext.is_json(mylist.get_elem(3)));
    assertTrue(json_ext.is_json_list(mylist.get_elem(4)));
    assertTrue(json_ext.is_json_bool(mylist.get_elem(5)));
    assertTrue(json_ext.is_json_null(mylist.get_elem(6)));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Is Type Test 2 (integers)';
  declare
    mylist json_list; --im lazy
  begin
    mylist := json_list('[23, 2.1, 0.0, 120, 0.00000001]');
    assertTrue(json_ext.is_number(mylist.get_elem(1)));
    assertTrue(json_ext.is_number(mylist.get_elem(2)));
    assertTrue(json_ext.is_number(mylist.get_elem(3)));
    assertTrue(json_ext.is_number(mylist.get_elem(4)));
    assertTrue(json_ext.is_number(mylist.get_elem(5)));

    assertTrue(json_ext.is_integer(mylist.get_elem(1)));
    assertFalse(json_ext.is_integer(mylist.get_elem(2)));
    assertTrue(json_ext.is_integer(mylist.get_elem(3)));
    assertTrue(json_ext.is_integer(mylist.get_elem(4)));
    assertFalse(json_ext.is_integer(mylist.get_elem(5)));
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Date interaction test 1';
  declare
    mylist json_list; --im lazy
    old_format_string varchar2(30) := json_ext.format_string; --backup 
  begin
    json_ext.format_string := 'yyyy-mm-dd hh24:mi:ss';
    mylist := json_list('["2009-07-01 00:22:33", "2007-04-04hulubalulu", "09-07-08", "2009-07-01", "2007/Jan/03" ]');
    assertFalse(json_ext.is_number(mylist.get_elem(1))); --why not
    
    assertTrue(json_ext.is_date(mylist.get_elem(1)));
    assertFalse(json_ext.is_date(mylist.get_elem(2)));
    assertTrue(json_ext.is_date(mylist.get_elem(3))); --the format_string accept many formats
    assertTrue(json_ext.is_date(mylist.get_elem(4)));
    assertTrue(json_ext.is_date(mylist.get_elem(5))); --too many
        
    pass(str);
    json_ext.format_string := old_format_string;
  exception
    when others then 
      fail(str);
      json_ext.format_string := old_format_string;
  end;

  str := 'Date interaction test 2';
  declare
    mylist json_list; --im lazy
    newinsert date := date '2009-08-08';
    old_format_string varchar2(30) := json_ext.format_string; --backup 
  begin
    json_ext.format_string := 'yyyy-mm-dd hh24:mi:ss';
    mylist := json_list('["2009-07-01 00:22:33", "2007-04-04hulubalulu", "09-07-08", "2009-07-01", "2007/Jan/03" ]');
    --correct the dates
    mylist.add_elem(json_ext.to_anydata(json_ext.to_date2(mylist.get_elem(1))), 1);
    mylist.remove_elem(2); --remove the old
    mylist.add_elem(json_ext.to_anydata(newinsert), 2);
    mylist.remove_elem(3); --remove the old falsy one
    mylist.add_elem(json_ext.to_anydata(json_ext.to_date2(mylist.get_elem(3))), 3);
    mylist.remove_elem(4); --remove the old
    mylist.add_elem(json_ext.to_anydata(json_ext.to_date2(mylist.get_elem(4))), 4);
    mylist.remove_elem(5); --remove the old
    mylist.add_elem(json_ext.to_anydata(json_ext.to_date2(mylist.get_elem(5))), 5);
    mylist.remove_elem(6); --remove the old
    
    assertTrue(mylist.to_char = '["2009-07-01 00:22:33", "2009-08-08 00:00:00", "0009-07-08 00:00:00", "2009-07-01 00:00:00", "2007-01-03 00:00:00"]');
    --we can see that 09-07-08 isn't a good idea when format_string doesn't match
    pass(str);
    json_ext.format_string := old_format_string;
  exception
    when others then 
      fail(str);
      json_ext.format_string := old_format_string;
  end;

  begin
    execute immediate 'insert into json_testsuite values (:1, :2, :3, :4, :5)' using
    'JSON_Ext testing', pass_count,fail_count,total_count,'ext_test.sql';
  exception
    when others then null;
  end;
end;