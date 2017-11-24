
create or replace package ut_pljson_list_test is
  
  --%suite(pljson_list test)
  --%suitepath(core)
  
  --%test(Test empty list)
  procedure test_empty;
  
  --%test(Test empty list and remove)  
  procedure test_empty_and_remove;
  
  --%test(Test empty list and add element)  
  procedure test_empty_and_add;
  
  --%test(Test list parser constructor, 1) 
  procedure test_parser_1;
  
  --%test(Test list parser constructor, 2)   
  procedure test_parser_2;
  
  --%test(Test add different types)
  procedure test_add_types;
  
  --%test(Test add with position)
  procedure test_add_position;
  
  --%test(Test remove with position)
  procedure test_remove_position;
  
  --%test(Test remove first)
  procedure test_remove_first;
  
  --%test(Test remove last)
  procedure test_remove_last;
  
  --%test(Test get elem with position)
  procedure test_get_position;
  
  --%test(Test get first and last)
  procedure test_get_first_last;
  
  --%test(Test insert null number)
  procedure test_insert_null_number;
  
  --%test(Test insert null varchar2)
  procedure test_insert_null_varchar2;
  
  --%test(Test insert null boolean)
  procedure test_insert_null_boolean;
  
  --%test(Test insert null)
  procedure test_insert_null;
  
  --%test(Test insert null pljson_list)
  procedure test_insert_null_pljson_list;
  
  --%test(Test replace)
  procedure test_replace;
  
end ut_pljson_list_test;
/

create or replace package body ut_pljson_list_test is
    
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
  
  -- empty list
  procedure test_empty is
    l pljson_list;
  begin
    l := pljson_list();
    assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- empty list and remove
  procedure test_empty_and_remove is
    l pljson_list;
  begin
    l := pljson_list();
    l.remove(3);
    l.remove_first;
    l.remove_last;
    assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- empty list and add element
  procedure test_empty_and_add is
    l pljson_list;
  begin
    l := pljson_list();
    l.append('MyElem');
    assertTrue(l.count = 1, 'l.count = 1');
  end;
  
  -- list parser constructor, 1
  procedure test_parser_1 is
    l pljson_list; x number; obj pljson;
  begin
    l := pljson_list('[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]');
    assertTrue(15 = l.count, '15 = l.count');
    for i in 1 .. l.count loop
      assertTrue(i = l.get(i).get_number, i || ' = i = l.get(i).get_number');
    end loop;
    l := pljson_list('[1, [], {"nest":true}]');
    assertTrue(l.count = 3, 'l.count = 3');
    assertTrue(1 = l.get(1).get_number, '1 = l.get(1).get_number');
    obj := pljson(l.get(3));
    assertTrue(obj.exist('nest'), 'obj.exist(''nest'')');
    assertTrue(obj.count = 1, 'obj.count = 1');
    l := pljson_list(l.get(2));
    assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- list parser constructor, 2
  procedure test_parser_2 is
    l pljson_list;
    test_name varchar2(100);
  begin
    test_name := '[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15';
    l := pljson_list('[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15'); --missing end
    fail(test_name);
  exception
    when others then pass(test_name);
  end;
  
  -- add different types
  procedure test_add_types is
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
    assertTrue(l.count = 6, 'l.count = 6');
    l.append(l.head);
    l.remove_first;
    for i in 1 .. l.count loop
      elem := l.head;
      assertFalse(elem is null, 'i = ' || i || ' elem is null');
      l.remove_first;
    end loop;
  end;
  
  -- add with position
  procedure test_add_position is
    l pljson_list;
  begin
    l := pljson_list();
    l.append('1', 2); --should not throw an error
    l.append('3', 2);
    l.append('2', 2);
    l.append('0', 1);
    l.append('-1', -11);
    l.append('4', 6);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "3", "4"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2", "3", "4"]'''); --pretty printer must work this way
  end;
  
  -- remove with position
  procedure test_remove_position is
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "3", "4"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2", "3", "4"]''');
    l.remove(5);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "4"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2", "4"]''');
    l.remove(5);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2"]''');
    l.remove(5);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2"]''');
    l.remove(-5);
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2"]''');
    l.remove(1);
    assertTrue(strip_eol(l.to_char) = '["0", "1", "2"]', 'strip_eol(l.to_char) = ''["0", "1", "2"]''');
    l.remove(2);
    assertTrue(strip_eol(l.to_char) = '["0", "2"]', 'strip_eol(l.to_char) = ''["0", "2"]''');
  end;
  
  -- remove first
  procedure test_remove_first is
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    l.remove_first;
    assertTrue(strip_eol(l.to_char) = '["0", "1", "2", "3", "4"]', 'strip_eol(l.to_char) = ''["0", "1", "2", "3", "4"]''');
    l.remove_first;
    assertTrue(l.count = 4, 'l.count = 4');
    l.remove_first;
    assertTrue(l.count = 3, 'l.count = 3');
    l.remove_first;
    assertTrue(l.count = 2, 'l.count = 2');
    l.remove_first;
    assertTrue(l.count = 1, 'l.count = 1');
    l.remove_first;
    assertTrue(l.count = 0, 'l.count = 0');
    l.remove_first;
    assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- remove last
  procedure test_remove_last is
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    l.remove_last;
    assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "3"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2", "3"]''');
    l.remove_last;
    assertTrue(l.count = 4, 'l.count = 4');
    l.remove_last;
    assertTrue(l.count = 3, 'l.count = 3');
    l.remove_last;
    assertTrue(l.count = 2, 'l.count = 2');
    l.remove_last;
    assertTrue(l.count = 1, 'l.count = 1');
    l.remove_last;
    assertTrue(l.count = 0, 'l.count = 0');
    l.remove_last;
    assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- get elem with position
  procedure test_get_position is
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    assertTrue(l.get(-1) is null, 'l.get(-1) is null');
    assertTrue(l.get(0) is null, 'l.get(0) is null');
    assertFalse(l.get(1) is null, 'l.get(1) is null');
    assertFalse(l.get(2) is null, 'l.get(2) is null');
    assertFalse(l.get(3) is null, 'l.get(3) is null');
    assertFalse(l.get(4) is null, 'l.get(4) is null');
    assertFalse(l.get(5) is null, 'l.get(5) is null');
    assertTrue(l.get(6) is not null, 'l.get(6) is not null');
    assertTrue(l.get(7) is null, 'l.get(7) is null');
    assertTrue(l.count = 6, 'l.count = 6');
  end;
  
  -- get first and last
  procedure test_get_first_last is
    l pljson_list; n pljson_value;
  begin
    l := pljson_list();
    assertTrue(l.head is null, 'l.head is null');
    assertTrue(l.last is null, 'l.last is null');
    l := pljson_list('[]');
    assertTrue(l.head is null, 'l.head is null');
    assertTrue(l.last is null, 'l.last is null');
    l := pljson_list('[2]');
    assertFalse(l.head is null, 'l.head is null');
    assertFalse(l.last is null, 'l.last is null');
    l := pljson_list('[1,2]');
    n := l.head;
    assertTrue(1 = n.get_number, '1 = n.get_number');
    n := l.last;
    assertTrue(2 = n.get_number, '2 = n.get_number');
  end;
  
  -- insert null number
  procedure test_insert_null_number is
    obj pljson_list := pljson_list();
    x number := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null varchar2
  procedure test_insert_null_varchar2 is
    obj pljson_list := pljson_list();
    x1 varchar2(20) := null;
    x2 varchar2(20) := '';
    n pljson_value;
    test_name varchar2(100);
  begin
    test_name := '.get_string()';
    obj.append(x1);
    obj.append(x2);
    --n := obj.head;
    x1 := obj.head().get_string;
    n := obj.last;
    x2 := n.get_string;
    pass(test_name);
  exception
    when others then fail(test_name);
  end;
  
  -- insert null boolean
  procedure test_insert_null_boolean is
    obj pljson_list := pljson_list();
    x boolean := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null
  procedure test_insert_null is
    obj pljson_list := pljson_list();
    x pljson_value := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null pljson_list
  procedure test_insert_null_pljson_list is
    obj pljson_list := pljson_list();
    x pljson_list := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- replace
  procedure test_replace is
    obj pljson_list := pljson_list('[4,5,6]');
  begin
    obj.replace(1, 1);
    obj.replace(2, 2);
    obj.replace(3, 3);
    assertTrue(obj.to_char(false) = '[1,2,3]', 'obj.to_char(false) = ''[1,2,3]''');
    obj.replace(-10, 3);
    assertTrue(obj.to_char(false) = '[1,2,3]', 'obj.to_char(false) = ''[1,2,3]''');
    obj.replace(210, 4);
    assertTrue(obj.to_char(false) = '[1,2,3,4]', 'obj.to_char(false) = ''[1,2,3,4]''');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    obj.replace(4, 2.718281828459e210d);
    assertTrue(obj.to_char(false) = '[1,2,3,2.7182818284589999E+210]', 'obj.to_char(false) = ''[1,2,3,2.7182818284589999E+210]'''); -- double is approximate
  end;
end ut_pljson_list_test;
/