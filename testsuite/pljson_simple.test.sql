
/**
 * Test of PLSQL JSON Object by Jonas Krogsboell
 **/

set serveroutput on format wrapped

begin
  
  pljson_ut.testsuite('pljson simple test', 'pljson_simple.test.sql');
  
  -- Bool
  pljson_ut.testcase('Test Bool');
  declare
    obj pljson_value;
  begin
    obj := pljson_value(true);
    pljson_ut.assertTrue(obj.get_bool, 'obj.get_bool');
    pljson_ut.assertFalse(not obj.get_bool, 'not obj.get_bool');
    pljson_ut.assertTrue(pljson_printer.pretty_print_any(obj) = 'true', 'pljson_printer.pretty_print_any(obj) = ''true''');
    obj := pljson_value(false);
    pljson_ut.assertFalse(obj.get_bool, 'obj.get_bool');
    pljson_ut.assertTrue(not obj.get_bool, 'not obj.get_bool');
    pljson_ut.assertTrue(pljson_printer.pretty_print_any(obj) = 'false', 'pljson_printer.pretty_print_any(obj) = ''false''');
  end;
  
  -- Null
  pljson_ut.testcase('Test Null');
  declare
    obj pljson_value;
  begin
    obj := pljson_value();
    pljson_ut.assertTrue(obj is not null, 'obj is not null');
    pljson_ut.assertTrue(pljson_printer.pretty_print_any(obj) = 'null', 'pljson_printer.pretty_print_any(obj) = ''null''');
    --pljson_ut.assertTrue(obj.null_data is null, 'obj.null_data is null'); --doesnt matter really
  end;
  
  -- very small number, issue #69
  pljson_ut.testcase('Test very small number, issue #69');
  declare
    obj pljson_value;
  begin
    obj := pljson_value(0.5);
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    pljson_ut.assertTrue(pljson_printer.pretty_print_any(obj) = '0.5', 'pljson_printer.pretty_print_any(obj) = ''0.5''');
    
    obj := pljson_value(-0.5);
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    pljson_ut.assertTrue(pljson_printer.pretty_print_any(obj) = '-0.5', 'pljson_printer.pretty_print_any(obj) = ''-0.5''');
    
    obj := pljson_value(1.1E-63);
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    pljson_ut.assertTrue(pljson_printer.pretty_print_any(obj) = '1.1E-63', 'pljson_printer.pretty_print_any(obj) = ''1.1E-63''');
    
    obj := pljson_value(-1.1e-63d); -- test double too
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    pljson_ut.assertTrue(pljson_printer.pretty_print_any(obj) = '-1.1E-63', 'pljson_printer.pretty_print_any(obj) = ''-1.1E-63''');
    
    obj := pljson_value(3.141592653589793238462643383279e-63);
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    pljson_ut.assertTrue(pljson_printer.pretty_print_any(obj) = '3.141592653589793238462643383279E-63', 'pljson_printer.pretty_print_any(obj) = ''3.141592653589793238462643383279E-63''');
    
    obj := pljson_value(2.718281828459e-210d); -- test double too
    --dbms_output.put_line(pljson_printer.pretty_print_any(obj));
    pljson_ut.assertTrue(pljson_printer.pretty_print_any(obj) = '2.718281828459E-210', 'pljson_printer.pretty_print_any(obj) = ''2.718281828459E-210''');
  end;
  
  -- parser/printer number/binary_double handling, issue #70
  pljson_ut.testcase('Test parser/printer number/binary_double handling, issue #70');
  declare
    obj pljson_list;
  begin
    obj := pljson_list('[1.23456789012e-360]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e-308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = False, 'obj.get(1).is_number_repr_number = False');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.23456789012e-308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = False, 'obj.get(1).is_number_repr_number = False');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e-129]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False');
    
    obj := pljson_list('[1.23456789012e-129]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False'); -- false because double is approximate
    
    obj := pljson_list('[0]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False');
    
    obj := pljson_list('[1.23456789012]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False'); -- false because double is approximate
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e125]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = False, 'obj.get(1).is_number_repr_double = False');
    
    obj := pljson_list('[1.23456789012e125]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.234567890123456789012345678901234567890123e308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = False, 'obj.get(1).is_number_repr_number = False');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[1.23456789012e308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = False, 'obj.get(1).is_number_repr_number = False');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    
    obj := pljson_list('[9.23456789012e308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    pljson_ut.assertTrue(pljson_printer.pretty_print_list(obj) = '[1e309]', 'pljson_printer.pretty_print_list(obj) = ''[1e309]''');
    
    obj := pljson_list('[-9.23456789012e308]');
    --dbms_output.put_line(pljson_printer.pretty_print_list(obj));
    --dbms_output.put_line(case when obj.get(1).is_number_repr_number then 'number true' else 'number false' end);
    --dbms_output.put_line(case when obj.get(1).is_number_repr_double then 'double true' else 'double false' end);
    pljson_ut.assertTrue(obj.get(1).is_number_repr_number = True, 'obj.get(1).is_number_repr_number = True');
    pljson_ut.assertTrue(obj.get(1).is_number_repr_double = True, 'obj.get(1).is_number_repr_double = True');
    pljson_ut.assertTrue(pljson_printer.pretty_print_list(obj) = '[-1e309]', 'pljson_printer.pretty_print_list(obj) = ''[-1e309]''');
  end;
  
  pljson_ut.testsuite_report;
  
end;
/