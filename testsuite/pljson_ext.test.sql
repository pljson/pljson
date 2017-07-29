
/**
 * Test of PLSQL JSON_Ext by Jonas Krogsboell
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
  
  pljson_ut.testsuite('pljson_ext test', 'pljson_ext.test.sql');
  
  -- is type
  pljson_ut.testcase('Test is type');
  declare
    mylist pljson_list;
  begin
    mylist := pljson_list('["abc", 23, {}, [], true, null]');
    pljson_ut.assertTrue(mylist.get(1).is_string, 'mylist.get(1).is_string');
    pljson_ut.assertTrue(mylist.get(2).is_number, 'mylist.get(2).is_number');
    pljson_ut.assertTrue(mylist.get(3).is_object, 'mylist.get(3).is_object');
    pljson_ut.assertTrue(mylist.get(4).is_array, 'mylist.get(4).is_array');
    pljson_ut.assertTrue(mylist.get(5).is_bool, 'mylist.get(5).is_bool');
    pljson_ut.assertTrue(mylist.get(6).is_null, 'mylist.get(6).is_null');
  end;
  
  -- is type 2 (integers)
  pljson_ut.testcase('Test is type 2 (integers)');
  declare
    mylist pljson_list;
  begin
    mylist := pljson_list('[23, 2.1, 0.0, 120, 0.00000001, 2.718281828459e-210, 2718281828459e210]');
    pljson_ut.assertTrue(mylist.get(1).is_number, 'mylist.get(1).is_number');
    pljson_ut.assertTrue(mylist.get(2).is_number, 'mylist.get(2).is_number');
    pljson_ut.assertTrue(mylist.get(3).is_number, 'mylist.get(3).is_number');
    pljson_ut.assertTrue(mylist.get(4).is_number, 'mylist.get(4).is_number');
    pljson_ut.assertTrue(mylist.get(5).is_number, 'mylist.get(5).is_number');
    pljson_ut.assertTrue(mylist.get(6).is_number, 'mylist.get(6).is_number');
    pljson_ut.assertTrue(mylist.get(7).is_number, 'mylist.get(7).is_number');
    
    pljson_ut.assertTrue(pljson_ext.is_integer(mylist.get(1)), 'pljson_ext.is_integer(mylist.get(1))');
    pljson_ut.assertFalse(pljson_ext.is_integer(mylist.get(2)), 'pljson_ext.is_integer(mylist.get(2))');
    pljson_ut.assertTrue(pljson_ext.is_integer(mylist.get(3)), 'pljson_ext.is_integer(mylist.get(3))');
    pljson_ut.assertTrue(pljson_ext.is_integer(mylist.get(4)), 'pljson_ext.is_integer(mylist.get(4))');
    pljson_ut.assertFalse(pljson_ext.is_integer(mylist.get(5)), 'pljson_ext.is_integer(mylist.get(5))');
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    pljson_ut.assertFalse(pljson_ext.is_integer(mylist.get(6)), 'pljson_ext.is_integer(mylist.get(6))');
    pljson_ut.assertTrue(pljson_ext.is_integer(mylist.get(7)), 'pljson_ext.is_integer(mylist.get(7))');
  end;
  
  -- date interaction 1
  pljson_ut.testcase('Test date interaction 1');
  declare
    mylist pljson_list;
    old_format_string varchar2(30) := pljson_ext.format_string; --backup
  begin
    pljson_ext.format_string := 'yyyy-mm-dd hh24:mi:ss';
    mylist := pljson_list('["2009-07-01 00:22:33", "2007-04-04hulubalulu", "09-07-08", "2009-07-01", "2007/Jan/03" ]');
    pljson_ut.assertFalse(mylist.get(1).is_number, 'mylist.get(1).is_number'); --why not
    
    pljson_ut.assertTrue(pljson_ext.is_date(mylist.get(1)), 'pljson_ext.is_date(mylist.get(1))');
    pljson_ut.assertFalse(pljson_ext.is_date(mylist.get(2)), 'pljson_ext.is_date(mylist.get(2))');
    --the format_string accept many formats
    pljson_ut.assertTrue(pljson_ext.is_date(mylist.get(3)), 'pljson_ext.is_date(mylist.get(3))');
    pljson_ut.assertTrue(pljson_ext.is_date(mylist.get(4)), 'pljson_ext.is_date(mylist.get(4))');
    --too many
    pljson_ut.assertTrue(pljson_ext.is_date(mylist.get(5)), 'pljson_ext.is_date(mylist.get(5))');
    
    pljson_ext.format_string := old_format_string;
  end;
  
  -- date interaction 2
  pljson_ut.testcase('Test date interaction 2');
  declare
    mylist pljson_list;
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
    
    pljson_ut.assertTrue(strip_eol(mylist.to_char) = '["2009-07-01 00:22:33", "2009-08-08 00:00:00", "0009-07-08 00:00:00", "2009-07-01 00:00:00", "2007-01-03 00:00:00"]', 'strip_eol(mylist.to_char) = ''["2009-07-01 00:22:33", "2009-08-08 00:00:00", "0009-07-08 00:00:00", "2009-07-01 00:00:00", "2007-01-03 00:00:00"]''');
    --we can see that 09-07-08 isn't a good idea when format_string doesn't match
    
    pljson_ext.format_string := old_format_string;
  end;
  
  -- null date insert into pljson
  pljson_ut.testcase('Test null date insert into pljson');
  --apparently null dates work fine
  declare
    obj pljson := pljson();
    v_when date := null;
  begin
    obj.put('X', pljson_ext.to_json_value(v_when));
    v_when := pljson_ext.to_date2(obj.get('X'));
    pljson_ut.assertTrue(v_when is null, 'v_when is null');
    pljson_ut.assertTrue(pljson_ext.is_date(obj.get('X')), 'pljson_ext.is_date(obj.get(''X''))');
  end;
  
  pljson_ut.testsuite_report;
  
end;
/