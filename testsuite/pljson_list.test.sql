/**
 * Test of PLSQL JSON List by Jonas Krogsboell
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
  dbms_output.put_line('pljson_list test:');
  
  str := 'Empty list test';
  declare
    l pljson_list;
  begin
    l := pljson_list();
    assertTrue(l.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Empty list test and remove';
  declare
    l pljson_list;
  begin
    l := pljson_list();
    l.remove(3);
    l.remove_first;
    l.remove_last;
    assertTrue(l.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Empty list test and add element';
  declare
    l pljson_list;
  begin
    l := pljson_list();
    l.append('MyElem');
    assertTrue(l.count = 1);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'List parser constructor link test';
  declare
    l pljson_list; x number; obj pljson;
  begin
    l := pljson_list('[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]');
    assertTrue(15 = l.count);
    for i in 1 .. l.count loop
      assertTrue(i = l.get(i).get_number);
    end loop;
    l := pljson_list('[1, [], {"nest":true}]');
    assertTrue(l.count = 3);
    assertTrue(1 = l.get(1).get_number);
    obj := pljson(l.get(3));
    assertTrue(obj.exist('nest'));
    assertTrue(obj.count = 1);
    l := pljson_list(l.get(2));
    assertTrue(l.count = 0);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'List parser constructor link test 2';
  declare
    l pljson_list;
  begin
    l := pljson_list('[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15'); --missing end
    fail(str);
  exception
    when others then pass(str);
  end;
  
  str := 'Add different types test';
  declare
    l pljson_list; elem pljson_value;
  begin
    l := pljson_list();
    l.append('varchar2');
    l.append(13);
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    l.append(2.718281828459e210d);
    l.append(pljson_value(false));
    l.append(pljson_value.makenull);
    l.append(pljson_list('[1,2,3]'));
    assertTrue(l.count = 6);
    l.append(l.head);
    l.remove_first;
    for i in 1 .. l.count loop
      elem := l.head;
      assertFalse(elem is null);
      l.remove_first;
    end loop;
    
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Add with position';
  declare
    l pljson_list;
  begin
    l := pljson_list();
    l.append('1', 2); --should not throw an error
    l.append('3', 2);
    l.append('2', 2);
    l.append('0', 1);
    l.append('-1', -11);
    l.append('4', 6);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "3", "4"]'); --pretty printer must work this way
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Remove with position';
  declare
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "3", "4"]');
    l.remove(5);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "4"]');
    l.remove(5);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2"]');
    l.remove(5);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2"]');
    l.remove(-5);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2"]');
    l.remove(1);
    assertTrue(strip_eol(l.to_char) = '["0", "1", "2"]');
    l.remove(2);
    assertTrue(strip_eol(l.to_char) = '["0", "2"]');
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Remove First';
  declare
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    l.remove_first;
    assertTrue(strip_eol(l.to_char) = '["0", "1", "2", "3", "4"]');
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
--  exception
--    when others then fail(str);
  end;
  
  str := 'Remove Last';
  declare
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    l.remove_last;
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "3"]');
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
--  exception
--    when others then fail(str);
  end;
  
  str := 'Get elem with position';
  declare
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    assertTrue(l.get(-1) is null);
    assertTrue(l.get(0) is null);
    assertFalse(l.get(1) is null);
    assertFalse(l.get(2) is null);
    assertFalse(l.get(3) is null);
    assertFalse(l.get(4) is null);
    assertFalse(l.get(5) is null);
    assertTrue(l.get(6) is not null);
    assertTrue(l.get(7) is null);
    assertTrue(l.count = 6);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Get first and last';
  declare
    l pljson_list; n pljson_value;
  begin
    l := pljson_list();
    assertTrue(l.head is null);
    assertTrue(l.last is null);
    l := pljson_list('[]');
    assertTrue(l.head is null);
    assertTrue(l.last is null);
    l := pljson_list('[2]');
    assertFalse(l.head is null);
    assertFalse(l.last is null);
    l := pljson_list('[1,2]');
    n := l.head;
    assertTrue(1 = n.get_number);
    n := l.last;
    assertTrue(2 = n.get_number);
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Number null insert test';
  declare
    obj pljson_list := pljson_list();
    x number := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    assertFalse(n is null); --may seem odd -- but initialized vars are best!
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Varchar2 null insert test';
  declare
    obj pljson_list := pljson_list();
    x1 varchar2(20) := null;
    x2 varchar2(20) := '';
    n pljson_value;
  begin
    obj.append(x1);
    obj.append(x2);
    --n := obj.head;
    x1 := obj.head().get_string;
    n := obj.last;
    x2 := n.get_string;
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Bool null insert test';
  declare
    obj pljson_list := pljson_list();
    x boolean := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    assertFalse(n is null); --may seem odd -- but initialized vars are best!
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'Null null insert test';
  declare
    obj pljson_list := pljson_list();
    x pljson_value := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    assertFalse(n is null); --may seem odd -- but initialized vars are best!
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'pljson_list null insert test';
  declare
    obj pljson_list := pljson_list();
    x pljson_list := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    assertFalse(n is null); --may seem odd -- but initialized vars are best!
    pass(str);
  exception
    when others then fail(str);
  end;
  
  str := 'pljson_list replace test';
  declare
    obj pljson_list := pljson_list('[4,5,6]');
  begin
    obj.replace(1, 1);
    obj.replace(2, 2);
    obj.replace(3, 3);
    assertTrue(obj.to_char(false) = '[1,2,3]');
    obj.replace(-10, 3);
    assertTrue(obj.to_char(false) = '[1,2,3]');
    obj.replace(210, 4);
    assertTrue(obj.to_char(false) = '[1,2,3,4]');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    obj.replace(4, 2.718281828459e210d);
    assertTrue(obj.to_char(false) = '[1,2,3,2.7182818284589999E+210]'); -- double is approximate
    pass(str);
  exception
    when others then fail(str);
  end;
  
  begin
    execute immediate 'insert into pljson_testsuite values (:1, :2, :3, :4, :5)' using
    'pljson_list test', pass_count, fail_count, total_count, 'pljson_list_test.sql';
  exception
    when others then null;
  end;
end;
/