/**
 * Test of PLSQL JSON Parser by Jonas Krogsboell
 **/
set serveroutput on format wrapped
declare
  obj json;
  pass_count number := 0;
  fail_count number := 0;
  total_count number := 0;
  
  scanner_exception exception;
  pragma exception_init(scanner_exception, -20100);
  parser_exception exception;
  pragma exception_init(parser_exception, -20101);
  
  /*
  procedure fail(text varchar2) as
  begin
    dbms_output.put_line('FAILED: '||text);
  end;
  procedure pass(text varchar2) as
  begin
    dbms_output.put_line('OK: '||text);
  end;
  */
  
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

  procedure assertFail(json_str varchar2, testname varchar2) as
    obj json;
  begin
    --total_count := total_count + 1;
    obj := json(json_str);
    --fail_count := fail_count + 1;
    fail(testname);
  exception
    when scanner_exception then
      --pass_count := pass_count + 1;
      pass(testname);
    when parser_exception then
      --pass_count := pass_count + 1;
      pass(testname);
    when others then
      --fail_count := fail_count + 1;
      fail(testname);
  end;
  
  procedure assertPass(json_str varchar2, testname varchar2) as
    obj json;
  begin
    --total_count := total_count + 1;
    obj := json(json_str);
  --  obj.print;
    --pass_count := pass_count + 1;
    pass(testname);
  exception
    when others then
      --fail_count := fail_count + 1;
      fail(testname);
      dbms_output.put_line(sqlerrm);
  end;

  procedure assertTrue(b boolean) as
  begin
    if(not b) then raise_application_error(-20111, 'Test error'); end if;
  end;

begin
  json_parser.json_strict := true;
  dbms_output.put_line('Scanner testing:');
  --number start with 0-9
  assertFail('{ "a": .23 }','number test A');
  --error described: no digits in fraction
  assertFail('{ "a": 23. }','digits test A');
  assertFail('{ "a": 23.h }','digits test B');
  assertPass('{ "a": 23.123 }','digits test C');
  --error described: no digits in exp
  assertPass('{ "a": 23.3e23 }','digits exp test A');
  assertPass('{ "a": 23.1e-23 }','digits exp test B');
  assertFail('{ "a": 23.3eg3 }','digits exp test C');
  assertFail('{ "a": 23.1e- }','digits exp test D');
  --error described: String tests
  assertPass('{ "a": "23.3e23" }','string test A');
  assertPass('{ "a": "\u34d6" }','unicode character test A');
  assertFail('{ "a": "\u345g" }','unicode character test A');
  assertFail('{ "a": "\u345" }','unicode character test B');
  assertPass('{ "a": "\" \\ \/ \b \f \n \r \t " }','escape character test A');
  assertFail('{ "a": "\3 " }','escape character test B');
  --boolean tests
  assertFail('{ "a": truE }','boolean test A');
  assertFail('{ "a": TRUE }','boolean test B');
  assertPass('{ "a": true }','boolean test C');
  assertFail('{ "a": falruE }','boolean test D');
  assertPass('{ "a": false }','boolean test E');
  --null tests
  assertFail('{ "a": nULL }','null test A');
  assertPass('{ "a": null }','null test B');
  --unexpected char line 226
  assertFail('{ "a": NULL }','unexpected char l.226');
  --unicode char test
  assertPass('{"æåø": "ÅÆØ"}','Unicode char test - on UTF8 databases');
  --string ending test
  declare
    tokens json_parser.lTokens;
    src json_parser.json_src;
  begin
    src := json_parser.prepareVarchar2('"kbwkbwkbkb'); /* since 0.84*/
    tokens := json_parser.lexer(src);
    fail('Lexer String ending test');
    null;
  exception
    when others then pass('Lexer String ending test');
  end;
  
  dbms_output.put_line('');
  dbms_output.put_line('Parser testing:');
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
  --object member tests:
  assertFail('{ "a": ,}}','wrong member start test');
  assertPass('{ "a": 2, "b": false, "c": 2}','normal members test');
  assertFail('{ "a": 2, "b": false, "a": true}','same membername in same scope test'); --could yield error - specs doesn't say anything
  --object testing
  assertFail('{ "a" ','Object suddently ends');
  assertFail('{ "a" "lala" }','missing :');
  assertFail('{ "a" :','missing value');
  assertFail('{ "a" : true, }','another pair expected');
  assertFail('{ "a" : true','} not found');
  assertPass('{ "a" : {}}','empty object A');
  assertPass('{}','empty object B');
  --start parser
  assertFail(' "a" ','{ missing');
  assertFail('{','} missing');
  assertFail('{ "a": 1 "b": 2 }',', missing');
  
  assertFail('{
    "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz" : 52,
    "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz" : 52
  }', 'Duplicate 1');

  assertPass('{
    "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz1" : 53,
    "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz2" : 53
  }', 'Duplicate 2');

  -- issue #37 test
  declare
    test_clob clob;
    test_buff varchar2(100);
    amount number;
    src json_parser.json_src;
    test_str varchar2(100) := 'issue #37';
  begin
    test_buff := 'abcdefghijklmnopqrstuvwxyz';
    dbms_lob.createtemporary(test_clob, false, DBMS_LOB.SESSION);
    amount := length(test_buff);
    dbms_lob.write(test_clob, amount, 3995, test_buff);
    
    src := json_parser.prepareClob(test_clob);
    for i in reverse 3995..4005 loop
      dbms_output.put_line('issue #37: '|| i ||' '|| substr(test_buff, i-3995+1, 1)|| ' - ' || json_parser.next_char(i, src));
      assertTrue(substr(test_buff, i-3995+1, 1) = json_parser.next_char(i, src));
    end loop;
    
    dbms_lob.freetemporary(test_clob);
    pass(test_str);
  exception
    when others then fail(test_str);
  end;
  
  dbms_output.put_line('');
  dbms_output.put_line('Passed '||pass_count||' of '||total_count||' tests.');
  dbms_output.put_line('Failed '||fail_count||' of '||total_count||' tests.');
  
  begin
    execute immediate 'insert into json_testsuite values (:1, :2, :3, :4, :5)' using
    'json_parser test', pass_count,fail_count,total_count,'json_parser_test.sql';
  exception
    when others then null;
  end;
  
end;
/
