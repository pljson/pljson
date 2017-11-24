
/**
 * Test of PLSQL JSON List by Jonas Krogsboell
 **/

set serveroutput on format wrapped

declare
  
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
  
begin
  
  pljson_ut.testsuite('pljson_list test', 'pljson_list.test.sql');
  
  -- empty list
  pljson_ut.testcase('Test empty list');
  declare
    l pljson_list;
  begin
    l := pljson_list();
    pljson_ut.assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- empty list and remove
  pljson_ut.testcase('Test empty list and remove');
  declare
    l pljson_list;
  begin
    l := pljson_list();
    l.remove(3);
    l.remove_first;
    l.remove_last;
    pljson_ut.assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- empty list and add element
  pljson_ut.testcase('Test empty list and add element');
  declare
    l pljson_list;
  begin
    l := pljson_list();
    l.append('MyElem');
    pljson_ut.assertTrue(l.count = 1, 'l.count = 1');
  end;
  
  -- list parser constructor, 1
  pljson_ut.testcase('Test list parser constructor, 1');
  declare
    l pljson_list; x number; obj pljson;
  begin
    l := pljson_list('[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]');
    pljson_ut.assertTrue(15 = l.count, '15 = l.count');
    for i in 1 .. l.count loop
      pljson_ut.assertTrue(i = l.get(i).get_number, i || ' = i = l.get(i).get_number');
    end loop;
    l := pljson_list('[1, [], {"nest":true}]');
    pljson_ut.assertTrue(l.count = 3, 'l.count = 3');
    pljson_ut.assertTrue(1 = l.get(1).get_number, '1 = l.get(1).get_number');
    obj := pljson(l.get(3));
    pljson_ut.assertTrue(obj.exist('nest'), 'obj.exist(''nest'')');
    pljson_ut.assertTrue(obj.count = 1, 'obj.count = 1');
    l := pljson_list(l.get(2));
    pljson_ut.assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- list parser constructor, 2
  pljson_ut.testcase('Test list parser constructor, 2');
  declare
    l pljson_list;
    test_name varchar2(100);
  begin
    test_name := '[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15';
    l := pljson_list('[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15'); --missing end
    pljson_ut.fail(test_name);
  exception
    when others then pljson_ut.pass(test_name);
  end;
  
  -- add different types
  pljson_ut.testcase('Test add different types');
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
    pljson_ut.assertTrue(l.count = 6, 'l.count = 6');
    l.append(l.head);
    l.remove_first;
    for i in 1 .. l.count loop
      elem := l.head;
      pljson_ut.assertFalse(elem is null, 'i = ' || i || ' elem is null');
      l.remove_first;
    end loop;
  end;
  
  -- add with position
  pljson_ut.testcase('Test add with position');
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
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "3", "4"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2", "3", "4"]'''); --pretty printer must work this way
  end;
  
  -- remove with position
  pljson_ut.testcase('Test remove with position');
  declare
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "3", "4"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2", "3", "4"]''');
    l.remove(5);
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "4"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2", "4"]''');
    l.remove(5);
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2"]''');
    l.remove(5);
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2"]''');
    l.remove(-5);
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2"]''');
    l.remove(1);
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["0", "1", "2"]', 'strip_eol(l.to_char) = ''["0", "1", "2"]''');
    l.remove(2);
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["0", "2"]', 'strip_eol(l.to_char) = ''["0", "2"]''');
  end;
  
  -- remove first
  pljson_ut.testcase('Test remove first');
  declare
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    l.remove_first;
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["0", "1", "2", "3", "4"]', 'strip_eol(l.to_char) = ''["0", "1", "2", "3", "4"]''');
    l.remove_first;
    pljson_ut.assertTrue(l.count = 4, 'l.count = 4');
    l.remove_first;
    pljson_ut.assertTrue(l.count = 3, 'l.count = 3');
    l.remove_first;
    pljson_ut.assertTrue(l.count = 2, 'l.count = 2');
    l.remove_first;
    pljson_ut.assertTrue(l.count = 1, 'l.count = 1');
    l.remove_first;
    pljson_ut.assertTrue(l.count = 0, 'l.count = 0');
    l.remove_first;
    pljson_ut.assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- remove last
  pljson_ut.testcase('Test remove last');
  declare
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    l.remove_last;
    pljson_ut.assertTrue(strip_eol(l.to_char) = '["-1", "0", "1", "2", "3"]', 'strip_eol(l.to_char) = ''["-1", "0", "1", "2", "3"]''');
    l.remove_last;
    pljson_ut.assertTrue(l.count = 4, 'l.count = 4');
    l.remove_last;
    pljson_ut.assertTrue(l.count = 3, 'l.count = 3');
    l.remove_last;
    pljson_ut.assertTrue(l.count = 2, 'l.count = 2');
    l.remove_last;
    pljson_ut.assertTrue(l.count = 1, 'l.count = 1');
    l.remove_last;
    pljson_ut.assertTrue(l.count = 0, 'l.count = 0');
    l.remove_last;
    pljson_ut.assertTrue(l.count = 0, 'l.count = 0');
  end;
  
  -- get elem with position
  pljson_ut.testcase('Test get elem with position');
  declare
    l pljson_list;
  begin
    l := pljson_list('["-1", "0", "1", "2", "3", "4"]');
    pljson_ut.assertTrue(l.get(-1) is null, 'l.get(-1) is null');
    pljson_ut.assertTrue(l.get(0) is null, 'l.get(0) is null');
    pljson_ut.assertFalse(l.get(1) is null, 'l.get(1) is null');
    pljson_ut.assertFalse(l.get(2) is null, 'l.get(2) is null');
    pljson_ut.assertFalse(l.get(3) is null, 'l.get(3) is null');
    pljson_ut.assertFalse(l.get(4) is null, 'l.get(4) is null');
    pljson_ut.assertFalse(l.get(5) is null, 'l.get(5) is null');
    pljson_ut.assertTrue(l.get(6) is not null, 'l.get(6) is not null');
    pljson_ut.assertTrue(l.get(7) is null, 'l.get(7) is null');
    pljson_ut.assertTrue(l.count = 6, 'l.count = 6');
  end;
  
  -- get first and last
  pljson_ut.testcase('Test get first and last');
  declare
    l pljson_list; n pljson_value;
  begin
    l := pljson_list();
    pljson_ut.assertTrue(l.head is null, 'l.head is null');
    pljson_ut.assertTrue(l.last is null, 'l.last is null');
    l := pljson_list('[]');
    pljson_ut.assertTrue(l.head is null, 'l.head is null');
    pljson_ut.assertTrue(l.last is null, 'l.last is null');
    l := pljson_list('[2]');
    pljson_ut.assertFalse(l.head is null, 'l.head is null');
    pljson_ut.assertFalse(l.last is null, 'l.last is null');
    l := pljson_list('[1,2]');
    n := l.head;
    pljson_ut.assertTrue(1 = n.get_number, '1 = n.get_number');
    n := l.last;
    pljson_ut.assertTrue(2 = n.get_number, '2 = n.get_number');
  end;
  
  -- insert null number
  pljson_ut.testcase('Test insert null number');
  declare
    obj pljson_list := pljson_list();
    x number := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    pljson_ut.assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null varchar2
  pljson_ut.testcase('Test insert null varchar2');
  declare
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
    pljson_ut.pass(test_name);
  exception
    when others then pljson_ut.fail(test_name);
  end;
  
  -- insert null boolean
  pljson_ut.testcase('Test insert null boolean');
  declare
    obj pljson_list := pljson_list();
    x boolean := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    pljson_ut.assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null
  pljson_ut.testcase('Test insert null');
  declare
    obj pljson_list := pljson_list();
    x pljson_value := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    pljson_ut.assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- insert null pljson_list
  pljson_ut.testcase('Test insert null pljson_list');
  declare
    obj pljson_list := pljson_list();
    x pljson_list := null;
    n pljson_value;
  begin
    obj.append(x);
    n := obj.head;
    pljson_ut.assertFalse(n is null, 'n is null'); --may seem odd -- but initialized vars are best!
  end;
  
  -- replace
  pljson_ut.testcase('Test replace');
  declare
    obj pljson_list := pljson_list('[4,5,6]');
  begin
    obj.replace(1, 1);
    obj.replace(2, 2);
    obj.replace(3, 3);
    pljson_ut.assertTrue(obj.to_char(false) = '[1,2,3]', 'obj.to_char(false) = ''[1,2,3]''');
    obj.replace(-10, 3);
    pljson_ut.assertTrue(obj.to_char(false) = '[1,2,3]', 'obj.to_char(false) = ''[1,2,3]''');
    obj.replace(210, 4);
    pljson_ut.assertTrue(obj.to_char(false) = '[1,2,3,4]', 'obj.to_char(false) = ''[1,2,3,4]''');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    obj.replace(4, 2.718281828459e210d);
    pljson_ut.assertTrue(obj.to_char(false) = '[1,2,3,2.7182818284589999E+210]', 'obj.to_char(false) = ''[1,2,3,2.7182818284589999E+210]'''); -- double is approximate
  end;
  
  pljson_ut.testsuite_report;
  
end;
/