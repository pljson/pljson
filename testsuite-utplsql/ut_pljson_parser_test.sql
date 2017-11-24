
create or replace package ut_pljson_parser_test is
  
  --%suite(pljson_parser test)
  --%suitepath(core)
  
  --%beforeall
  procedure set_json_strict;
  
  --%test(Test number starts with 0-9)
  procedure test_scanner_digits;
  
  --%test(Test digits in fraction)
  procedure test_digits_fraction;
  
  --%test(Test digits in exp)
  procedure test_digits_exp;
  
  --%test(Test string)
  procedure test_string;
  
  --%test(Test boolean)
  procedure test_boolean;
  
  --%test(Test null)
  procedure test_null;
  
  --%test(Test unexpected char line 226)
  procedure test_unexpected_char_l_266;
  
  --%test(Test unicode char - on UTF8 databases)
  procedure test_unicode_char;
  
  --%test(Test string ending)
  procedure test_string_ending;
  
  --%test(Test parser)
  procedure test_parser;
  
  --%test(Test object member)
  procedure test_object_member;
  
  --%test(Test object)
  procedure test_object;
  
  --%test(Test duplicates)
  procedure test_duplicates;
  
  --%test(Test issue #37)
  procedure test_issue_37;
  
end ut_pljson_parser_test;
/

create or replace package body ut_pljson_parser_test is
  
  scanner_exception exception;
  pragma exception_init(scanner_exception, -20100);
  parser_exception exception;
  pragma exception_init(parser_exception, -20101);
  
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
  
  procedure assertPass(json_str varchar2, test_name varchar2) as
    obj pljson;
  begin
    obj := pljson(json_str);
    --ut.expect(obj.to_char(spaces => false), testname).to_equal(json_str);
    pass(test_name);
  exception
    when others then
      fail(test_name);
      --ut.fail(test_name || EOL || dbms_utility.format_error_backtrace);
  end;
  
  procedure assertFail(json_str varchar2, test_name varchar2) as
    obj pljson;
  begin
    obj := pljson(json_str);
    fail(test_name);
    --ut.fail(test_name);
  exception
    when scanner_exception or parser_exception then
      pass(test_name);
    when others then
      fail(test_name);
      --ut.fail(test_name || EOL || dbms_utility.format_error_backtrace);
  end;
  
  procedure set_json_strict is
  begin
    pljson_parser.json_strict := true;
  end;
  
  -- number starts with 0-9
  procedure test_scanner_digits is
  begin
    assertFail('{ "a": .23 }','number test A');
  end;
  
  -- digits in fraction
  procedure test_digits_fraction is
  begin
    assertFail('{ "a": 23. }','digits test A');
    assertFail('{ "a": 23.h }','digits test B');
    assertPass('{ "a": 23.123 }','digits test C');
  end;
  
  -- digits in exp
  procedure test_digits_exp is
  begin
    assertPass('{ "a": 23.3e23 }','digits exp test A');
    assertPass('{ "a": 23.1e-23 }','digits exp test B');
    assertFail('{ "a": 23.3eg3 }','digits exp test C');
    assertFail('{ "a": 23.1e- }','digits exp test D');
  end;  
  
  -- string
  procedure test_string is
  begin
    assertPass('{ "a": "23.3e23" }','string test A');
    assertPass('{ "a": "\u34d6" }','unicode character test A');
    assertFail('{ "a": "\u345g" }','unicode character test A');
    assertFail('{ "a": "\u345" }','unicode character test B');
    assertPass('{ "a": "\" \\ \/ \b \f \n \r \t " }','escape character test A');
    assertFail('{ "a": "\3 " }','escape character test B');
  end;
  
  -- boolean
  procedure test_boolean is
  begin
    assertFail('{ "a": truE }','boolean test A');
    assertFail('{ "a": TRUE }','boolean test B');
    assertPass('{ "a": true }','boolean test C');
    assertFail('{ "a": falruE }','boolean test D');
    assertPass('{ "a": false }','boolean test E');
  end;
  
  -- null
  procedure test_null is
  begin
    assertFail('{ "a": nULL }','null test A');
    assertPass('{ "a": null }','null test B');
  end;
  
  -- unexpected char line 226
  procedure test_unexpected_char_l_266 is
  begin
    assertFail('{ "a": NULL }','unexpected char l.226');
  end;
  
  -- unicode char - on UTF8 databases
  procedure test_unicode_char is
  begin
    assertPass('{"æåø": "ÅÆØ"}','unicode char - on UTF8 databases');
  end;
  
  -- string ending
  procedure test_string_ending is
    tokens pljson_parser.ltokens;
    src pljson_parser.json_src;
    test_name varchar2(100) := 'string ending test';
  begin
    src := pljson_parser.preparevarchar2('"kbwkbwkbkb'); /* since 0.84 */
    tokens := pljson_parser.lexer(src);
    fail(test_name);
    --ut.fail('scanner exception not raised');
  exception
    when scanner_exception then
      ut.expect(sqlerrm).to_be_like('%string ending not found%');
      pass(test_name);
  end;
  
  -- parser
  procedure test_parser is
  begin
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
    
    --start parser
    assertFail(' "a" ','{ missing');
    assertFail('{','} missing');
    assertFail('{ "a": 1 "b": 2 }',', missing');
  end;
  
  -- object member
  procedure test_object_member is
  begin
    assertFail('{ "a": ,}}','wrong member start test');
    assertPass('{ "a": 2, "b": false, "c": 2}','normal members test');
    assertFail('{ "a": 2, "b": false, "a": true}','same membername in same scope test');--could yield error - specs doesn't say anything
  end;
  
  -- object
  procedure test_object is
  begin
    assertFail('{ "a" ','Object suddently ends');
    assertFail('{ "a" "lala" }','missing :');
    assertFail('{ "a" :','missing value');
    assertFail('{ "a" : true, }','another pair expected');
    assertFail('{ "a" : true','} not found');
    assertPass('{ "a" : {}}','empty object A');
    assertPass('{}','empty object B');
  end;
  
  -- duplicates
  procedure test_duplicates is
  begin
    assertFail('{
      "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz" : 52,
      "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz" : 52
    }', 'Duplicate 1');
    
    assertPass('{
      "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz1" : 53,
      "abcdefghijklmnopqrstuvxyzabcdefghijklmnopqrstuvxyz2" : 53
    }', 'Duplicate 2');
  end;
  
  -- issue37
  /*
    E.I.Sarmas (github.com/dsnz)   2016-04-12
    issue #37 test
    proposed by Borodulin Maxim (github.com/boriborm)
  */
  procedure test_issue_37 is
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
      ut.expect(substr(test_buff, i-3995+1, 1)).to_equal(pljson_parser.next_char(i, src));
    end loop;
    
    dbms_lob.freetemporary(test_clob);
    pass(test_name);
  exception
    when others then
      fail(test_name);
  end;
  
end ut_pljson_parser_test;
/