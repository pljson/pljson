
/**
 * Test of PLSQL JSON Parser by Jonas Krogsboell
 **/

 set serveroutput on format wrapped

declare
  
  scanner_exception exception;
  pragma exception_init(scanner_exception, -20100);
  parser_exception exception;
  pragma exception_init(parser_exception, -20101);
  
  procedure assertPass(json_str varchar2, test_name varchar2) as
    obj pljson;
  begin
    obj := pljson(json_str);
    pljson_ut.pass(test_name);
  exception
    when others then
      pljson_ut.fail(test_name);
      --dbms_output.put_line(sqlerrm);
  end;
  
  procedure assertFail(json_str varchar2, test_name varchar2) as
    obj pljson;
  begin
    obj := pljson(json_str);
    pljson_ut.fail(test_name);
  exception
    when scanner_exception or parser_exception then
      pljson_ut.pass(test_name);
    when others then
      pljson_ut.fail(test_name);
      --dbms_output.put_line(sqlerrm);
  end;
  
begin
  
  pljson_ut.testsuite('pljson_parser test', 'pljson_parser.test.sql');
  
  pljson_parser.json_strict := true;
  
  -- number starts with 0-9
  pljson_ut.testcase('Test number starts with 0-9');
  assertFail('{ "a": .23 }','number test A');
  
  -- digits in fraction
  pljson_ut.testcase('Test digits in fraction');
  assertFail('{ "a": 23. }','digits test A');
  assertFail('{ "a": 23.h }','digits test B');
  assertPass('{ "a": 23.123 }','digits test C');
  
  -- digits in exp
  pljson_ut.testcase('Test digits in exp');
  assertPass('{ "a": 23.3e23 }','digits exp test A');
  assertPass('{ "a": 23.1e-23 }','digits exp test B');
  assertFail('{ "a": 23.3eg3 }','digits exp test C');
  assertFail('{ "a": 23.1e- }','digits exp test D');
  
  -- string
  pljson_ut.testcase('Test string');
  assertPass('{ "a": "23.3e23" }','string test A');
  assertPass('{ "a": "\u34d6" }','unicode character test A');
  assertFail('{ "a": "\u345g" }','unicode character test A');
  assertFail('{ "a": "\u345" }','unicode character test B');
  assertPass('{ "a": "\" \\ \/ \b \f \n \r \t " }','escape character test A');
  assertFail('{ "a": "\3 " }','escape character test B');
  
  -- boolean
  pljson_ut.testcase('Test boolean');
  assertFail('{ "a": truE }','boolean test A');
  assertFail('{ "a": TRUE }','boolean test B');
  assertPass('{ "a": true }','boolean test C');
  assertFail('{ "a": falruE }','boolean test D');
  assertPass('{ "a": false }','boolean test E');
  
  -- null
  pljson_ut.testcase('Test null');
  assertFail('{ "a": nULL }','null test A');
  assertPass('{ "a": null }','null test B');
  
  -- unexpected char line 226
  pljson_ut.testcase('Test unexpected char line 226');
  assertFail('{ "a": NULL }','unexpected char l.226');
  
  -- unicode char - on UTF8 databases
  pljson_ut.testcase('Test unicode char - on UTF8 databases');
  assertPass('{"æåø": "ÅÆØ"}','unicode char - on UTF8 databases');
  
  -- string ending
  pljson_ut.testcase('Test string ending');
  declare
    tokens pljson_parser.lTokens;
    src pljson_parser.json_src;
    test_name varchar2(100) := 'string ending test';
  begin
    src := pljson_parser.prepareVarchar2('"kbwkbwkbkb'); /* since 0.84 */
    tokens := pljson_parser.lexer(src);
    pljson_ut.fail(test_name);
  exception
    when others then pljson_ut.pass(test_name);
  end;
  
  -- parser
  pljson_ut.testcase('Test parser');
  assertFail('{ "a": [}]}','array expecting value got }');
  assertFail('{ "a": [,]}','premature exit from array');
  assertFail('{ "a": [,','premature exit from array2');
  assertFail('{ "a": [2','premature exit from array3');
  assertFail('{ "a": [','premature exit from array4');
  assertFail('{ "a": [ 2 2 ]}','commas between values in array 1');
  assertPass('{ "a": [ 2, 2 ]}','commas between values in array 2');
  assertFail('{ "a": [ 2, 2 }','remember to end array');
  assertPass('{ "a": []}','empty array');
  assertPass('{ "a": [[]]}','empty array in array');
  assertPass('{ "a": [true, [true, false], "my fancy array", ["you could call it a list"]]}','wild array');
  
  -- start parser
  assertFail(' "a" ','{ missing');
  assertFail('{','} missing');
  assertFail('{ "a": 1 "b": 2 }',', missing');
  
  -- object member
  pljson_ut.testcase('Test object member');
  assertFail('{ "a": ,}}','wrong member start test');
  assertPass('{ "a": 2, "b": false, "c": 2}','normal members test');
  assertFail('{ "a": 2, "b": false, "a": true}','same membername in same scope test');--could yield error - specs doesn't say anything
  
  -- object
  pljson_ut.testcase('Test object');
  assertFail('{ "a" ','Object suddently ends');
  assertFail('{ "a" "lala" }','missing :');
  assertFail('{ "a" :','missing value');
  assertFail('{ "a" : true, }','another pair expected');
  assertFail('{ "a" : true','} not found');
  assertPass('{ "a" : {}}','empty object A');
  assertPass('{}','empty object B');

  -- duplicates
  pljson_ut.testcase('Test duplicates');
  assertFail('{
    "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz" : 52,
    "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz" : 52
  }', 'Duplicate 1');
  
  assertPass('{
    "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz1" : 53,
    "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz2" : 53
  }', 'Duplicate 2');
  
  -- issue37
  pljson_ut.testcase('Test issue #37');
  /*
    E.I.Sarmas (github.com/dsnz)   2016-04-12
    issue #37 test
    proposed by Borodulin Maxim (github.com/boriborm)
  */
  declare
    test_clob clob;
    test_buff varchar2(100);
    amount number;
    src pljson_parser.json_src;
    test_name varchar2(100) := 'issue #37';
  begin
    test_buff := 'abcdefghijklmnopqrstuvwxyz';
    dbms_lob.createtemporary(test_clob, false, DBMS_LOB.SESSION);
    amount := length(test_buff);
    dbms_lob.write(test_clob, amount, 3995, test_buff);
    
    src := pljson_parser.prepareClob(test_clob);
    for i in reverse 3995..4005 loop
      --dbms_output.put_line('issue #37: ' || i || ' ' ||
      --  substr(test_buff, i-3995+1, 1) || ' - ' || pljson_parser.next_char(i, src));
      pljson_ut.assertTrue(substr(test_buff, i-3995+1, 1) = pljson_parser.next_char(i, src));
    end loop;
    
    dbms_lob.freetemporary(test_clob);
    pljson_ut.pass(test_name);
  exception
    when others then pljson_ut.fail(test_name);
  end;
  
  pljson_ut.testsuite_report;
  
end;
/