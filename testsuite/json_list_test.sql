/**
 * Test of PLSQL JSON List by Jonas Krogsboell
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
  
  str := 'Empty list test';
  declare
    l json_list;
  begin
    l := json_list();
    assertTrue(l.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Empty list test and remove';
  declare
    l json_list;
  begin
    l := json_list();
    l.remove_elem(3);
    l.remove_first;
    l.remove_last;
    assertTrue(l.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Empty list test and add element';
  declare
    l json_list;
  begin
    l := json_list();
    l.add_elem('MyElem');
    assertTrue(l.count = 1);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'List parser constructor link test';
  declare
    l json_list; x number; obj json;
  begin
    l := json_list('[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]');
    assertTrue(15 = l.count);
    for i in 1 .. l.count loop
      assertTrue(i = l.get_elem(i).get_number);
    end loop;
    l := json_list('[1, [], {"nest":true}]');
    assertTrue(l.count = 3);
    assertTrue(1 = l.get_elem(1).get_number);
    obj := json(l.get_elem(3));
    assertTrue(obj.exist('nest'));
    assertTrue(obj.count = 1);
    l := json_list(l.get_elem(2));
    assertTrue(l.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'List parser constructor link test 2';
  declare
    l json_list;
  begin
    l := json_list('[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15'); --missing end
    fail(str);
  exception
    when others then pass(str);
  end;

  str := 'Add different types test';
  declare
    l json_list; elem json_value;
  begin
    l := json_list(); 
    l.add_elem('varchar2');
    l.add_elem(13);
    l.add_elem(json_value(false));
    l.add_elem(json_value.makenull);
    l.add_elem(json_list('[1,2,3]'));
    assertTrue(l.count = 5);
    l.add_elem(l.get_first);
    l.remove_first;
    for i in 1 .. l.count loop
      elem := l.get_first;
      assertFalse(elem is null);
      l.remove_first;
    end loop;
    
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Add with position';
  declare
    l json_list; 
  begin
    l := json_list(); 
    l.add_elem('1', 2); --should not throw an error
    l.add_elem('3', 2); 
    l.add_elem('2', 2); 
    l.add_elem('0', 1); 
    l.add_elem('-1', -11); 
    l.add_elem('4', 6); 
    assertTrue(l.to_char = '["-1", "0", "1", "2", "3", "4"]'); --pretty printer must work this way
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Remove with position';
  declare
    l json_list; 
  begin
    l := json_list('["-1", "0", "1", "2", "3", "4"]'); 
    assertTrue(l.to_char = '["-1", "0", "1", "2", "3", "4"]');
    l.remove_elem(5);
    assertTrue(l.to_char = '["-1", "0", "1", "2", "4"]');
    l.remove_elem(5);
    assertTrue(l.to_char = '["-1", "0", "1", "2"]');
    l.remove_elem(5);
    assertTrue(l.to_char = '["-1", "0", "1", "2"]');
    l.remove_elem(-5);
    assertTrue(l.to_char = '["-1", "0", "1", "2"]');
    l.remove_elem(1);
    assertTrue(l.to_char = '["0", "1", "2"]');
    l.remove_elem(2);
    assertTrue(l.to_char = '["0", "2"]');
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Remove First';
  declare
    l json_list; 
  begin
    l := json_list('["-1", "0", "1", "2", "3", "4"]'); 
    l.remove_first;
    assertTrue(l.to_char = '["0", "1", "2", "3", "4"]');
    l.remove_first;
    assertTrue(l.count = 4);
    l.remove_first;
    assertTrue(l.count = 3);
    l.remove_first;
    assertTrue(l.count = 2);
    l.remove_first;
    assertTrue(l.count = 1);
    l.remove_first;
    assertTrue(l.count = 0);
    l.remove_first;
    assertTrue(l.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Remove Last';
  declare
    l json_list; 
  begin
    l := json_list('["-1", "0", "1", "2", "3", "4"]'); 
    l.remove_last;
    assertTrue(l.to_char = '["-1", "0", "1", "2", "3"]');
    l.remove_last;
    assertTrue(l.count = 4);
    l.remove_last;
    assertTrue(l.count = 3);
    l.remove_last;
    assertTrue(l.count = 2);
    l.remove_last;
    assertTrue(l.count = 1);
    l.remove_last;
    assertTrue(l.count = 0);
    l.remove_last;
    assertTrue(l.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Get elem with position';
  declare
    l json_list; 
  begin
    l := json_list('["-1", "0", "1", "2", "3", "4"]'); 
    assertTrue(l.get_elem(-1) is null);
    assertTrue(l.get_elem(0) is null);
    assertFalse(l.get_elem(1) is null);
    assertFalse(l.get_elem(2) is null);
    assertFalse(l.get_elem(3) is null);
    assertFalse(l.get_elem(4) is null);
    assertFalse(l.get_elem(5) is null);
    assertTrue(l.get_elem(6) is not null);
    assertTrue(l.get_elem(7) is null);
    assertTrue(l.count = 6);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Get first and last';
  declare
    l json_list; n json_value;
  begin
    l := json_list(); 
    assertTrue(l.get_first is null);
    assertTrue(l.get_last is null);
    l := json_list('[]'); 
    assertTrue(l.get_first is null);
    assertTrue(l.get_last is null);
    l := json_list('[2]'); 
    assertFalse(l.get_first is null);
    assertFalse(l.get_last is null);
    l := json_list('[1,2]'); 
    n := l.get_first;
    assertTrue(1 = n.get_number);
    n := l.get_last;
    assertTrue(2 = n.get_number);
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Number null insert test';
  declare
    obj json_list := json_list();
    x number := null;
    n json_value;
  begin
    obj.add_elem(x);
    n := obj.get_first;
    assertFalse(n is null); --may seam odd -- but initialized vars are best! 
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Varchar2 null insert test';
  declare
    obj json_list := json_list();
    x1 varchar2(20) := null;
    x2 varchar2(20) := '';
    n json_value;
  begin
    obj.add_elem(x1);
    obj.add_elem(x2);
    --n := obj.get_first;
    x1 := obj.get_first().get_string;
    n := obj.get_last;
    x2 := n.get_string;
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Bool null insert test';
  declare
    obj json_list := json_list();
    x boolean := null;
    n json_value;
  begin
    obj.add_elem(x);
    n := obj.get_first;
    assertFalse(n is null); --may seam odd -- but initialized vars are best! 
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'Null null insert test';
  declare
    obj json_list := json_list();
    x json_value := null;
    n json_value;
  begin
    obj.add_elem(x);
    n := obj.get_first;
    assertFalse(n is null); --may seam odd -- but initialized vars are best! 
    pass(str);
  exception
    when others then fail(str);
  end;

  str := 'json_list null insert test';
  declare
    obj json_list := json_list();
    x json_list := null;
    n json_value;
  begin
    obj.add_elem(x);
    n := obj.get_first;
    assertFalse(n is null); --may seam odd -- but initialized vars are best! 
    pass(str);
  exception
    when others then fail(str);
  end;

  begin
    execute immediate 'insert into json_testsuite values (:1, :2, :3, :4, :5)' using
    'List testing', pass_count,fail_count,total_count,'json_list_test.sql';
  exception
    when others then null;
  end;
end;