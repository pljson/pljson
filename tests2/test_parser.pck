create or replace package test_parser is

  --%suite(pljson_parser tests)
  --%suitepath(core)
  
  --%beforeall
  procedure set_json_strict;
  
  --%test(Test number start with 0-9)
  procedure test_scanner_digits;
  
  --%test(Test digits in fraction)
  procedure test_digit_fraction;
  
  --%test(Test digits in exp)
  procedure test_digits_in_exp;
  
  --%test(String tests)
  procedure test_strings;
  
  --%test(Boolean tests)
  procedure test_bools;
  
  --%test(Null tests)
  procedure test_nulls;
  
  --%test(Test unexpected char line 226)
  procedure test_unexpected_char_l_266;
  
  --%test(Unicode char test - on UTF8 databases)
  procedure test_unicode_char;
  
  --%test(Object member tests)
  procedure test_object_member;
  
  --%test(Object testing)
  procedure test_objects;
  
  --%test(Test duplicates)
  procedure test_duplicates;
  
  --%test(Parser testing)
  procedure test_parser;
  
  --%test(Lexer String ending test)
  procedure test_string_ending;
  
  --%test(2016-04-12 Test for issue issue #37 by mbodorulin proposed by Borodulin Maxim github.com/boriborm)
  procedure test_issue_37;

end test_parser;
/
create or replace package body test_parser is

  scanner_exception exception;
  pragma exception_init(scanner_exception, -20100);
  parser_exception exception;
  pragma exception_init(parser_exception, -20101);
    
  procedure pass(str varchar2) as
  begin
    ut.expect(true,str).to_be_true;
    null;
  end;
    
  procedure assertFail(json_str varchar2, testname varchar2) as
    obj pljson;
  begin
    obj := pljson(json_str);
    ut.fail(testname);
  exception
    when scanner_exception or parser_exception then
      pass(testname);
    when others then
      ut.fail(testname||chr(13)||dbms_utility.format_error_backtrace);
  end;
    
  procedure assertPass(json_str varchar2, testname varchar2) as
    obj pljson;
  begin
    obj := pljson(json_str);
    --ut.expect(obj.to_char(spaces => false),testname).to_equal(json_str);
  exception
    when others then
      ut.fail(testname||chr(13)||dbms_utility.format_error_backtrace);
  end;
  
  procedure set_json_strict is
  begin
    pljson_parser.json_strict := true;
  end;
  
  procedure test_scanner_digits is
  begin
    assertFail('{ "a": .23 }','number test A');
  end;
  
  procedure test_digit_fraction is
  begin
    assertFail('{ "a": 23. }','digits test A');
    assertFail('{ "a": 23.h }','digits test B');
    assertPass('{ "a": 23.123 }','digits test C');
  end;
  
  procedure test_digits_in_exp is
  begin
    assertPass('{ "a": 23.3e23 }','digits exp test A');
    assertPass('{ "a": 23.1e-23 }','digits exp test B');
    assertFail('{ "a": 23.3eg3 }','digits exp test C');
    assertFail('{ "a": 23.1e- }','digits exp test D');
  end;  
  
  procedure test_strings is
  begin
    assertPass('{ "a": "23.3e23" }','string test A');
    assertPass('{ "a": "\u34d6" }','unicode character test A');
    assertFail('{ "a": "\u345g" }','unicode character test A');
    assertFail('{ "a": "\u345" }','unicode character test B');
    assertPass('{ "a": "\" \\ \/ \b \f \n \r \t " }','escape character test A');
    assertFail('{ "a": "\3 " }','escape character test B');
  end;
  
  procedure test_bools is
  begin
    assertFail('{ "a": truE }','boolean test A');
    assertFail('{ "a": TRUE }','boolean test B');
    assertPass('{ "a": true }','boolean test C');
    assertFail('{ "a": falruE }','boolean test D');
    assertPass('{ "a": false }','boolean test E');
  end;
  
  procedure test_nulls is
  begin
    assertFail('{ "a": nULL }','null test A');
    assertPass('{ "a": null }','null test B');
  end;
  
  procedure test_unexpected_char_l_266 is
    obj pljson;
  begin
    assertFail('{ "a": NULL }','unexpected char l.226');
  end;
  
  procedure test_unicode_char is
    obj pljson;
  begin
    obj := pljson('{"æåø": "ÅÆØ"}');
  end;
  
  procedure test_object_member is
  begin
    assertFail('{ "a": ,}}','wrong member start test');
    assertPass('{ "a": 2, "b": false, "c": 2}','normal members test');
    assertFail('{ "a": 2, "b": false, "a": true}','same membername in same scope test');--could yield error - specs doesn't say anything
  end;
  
  procedure test_objects is
  begin
    --object testing
    assertFail('{ "a" ','Object suddently ends');
    assertFail('{ "a" "lala" }','missing :');
    assertFail('{ "a" :','missing value');
    assertFail('{ "a" : true, }','another pair expected');
    assertFail('{ "a" : true','} not found');
    assertPass('{ "a" : {}}','empty object A');
    assertPass('{}','empty object B');
  end;
  
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
  
  procedure test_parser is
    obj pljson;
  begin
    pljson_parser.json_strict := true;  
  
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
  
  procedure test_string_ending is
    tokens pljson_parser.ltokens;
    src    pljson_parser.json_src;
  begin
    src    := pljson_parser.preparevarchar2('"kbwkbwkbkb'); /* since 0.84*/
    tokens := pljson_parser.lexer(src);
    ut.fail('scanner exception not raised');
  exception
    when scanner_exception then
      ut.expect(sqlerrm).to_be_like('%string ending not found%');
  end;
  
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
    test_str varchar2(100) := 'issue #37';
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
    pass(test_str);
  exception
    when others then ut.fail(test_str);
  end;
    
end test_parser;
/
