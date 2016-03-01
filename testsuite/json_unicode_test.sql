/*
  set of 5 tests exercising correct Unicode support and big strings for both clob and varchar2 api versions
  test should not produce ORA-06502 error
  run with NLS_LANG='AMERICAN_AMERICA.AL32UTF8'
*/

PROMPT did you run with NLS_LANG='AMERICAN_AMERICA.AL32UTF8' ?

set serveroutput on format wrapped
declare
  test_json json;
  test_json_list json_list;
  clob_buf_1 clob;
  clob_buf_2 clob;
  var_buf_1 VARCHAR2(32767);
  var_buf_2 VARCHAR2(32767);
  json_clob clob;
  json_var VARCHAR2(32767);
  /* 64 chars */
  text_2_byte VARCHAR2(200) := 'αβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩάέήίόύώϊϋΆΈΉΊΌΎΏ';
  /* 62 chars */
  text_1_byte VARCHAR2(200) := '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  CLOB_MAX_SIZE NUMBER := 256 * 1024;
  VARCHAR2_1_BYTE_MAX_SIZE NUMBER := 32000; /* allow some space for json markup */
  VARCHAR2_2_CHAR_MAX_SIZE NUMBER := 5000;
  i NUMBER;
  k NUMBER;
  t_start timestamp;
  t_stop  timestamp;
  t_sec NUMBER;

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

  t_start := SYSTIMESTAMP;
  
  /* json with
  1 clob string of ~ 256K 1-byte chars
  1 clob string of ~ 256K 2-byte chars
  1 varchar2 string of 32767 1-byte chars
  1 varchar2 string of 5000  2-byte chars
  */
  /* buffer preparation */

  dbms_lob.createtemporary(clob_buf_1, TRUE, dbms_lob.SESSION);
  dbms_lob.trim(clob_buf_1, 0);
  k := length(text_1_byte);
  i := 0;
  while i + k < CLOB_MAX_SIZE loop
    dbms_lob.writeappend(clob_buf_1, k, text_1_byte);
    i := i + k;
  end loop;
  --dbms_output.put_line('clob_1 1-byte buffer, chars = ' || to_char(dbms_lob.getlength(clob_buf_1)));
  
  dbms_lob.createtemporary(clob_buf_2, TRUE, dbms_lob.SESSION);
  dbms_lob.trim(clob_buf_2, 0);
  k := length(text_2_byte);
  i := 0;
  while i + k < CLOB_MAX_SIZE loop
    dbms_lob.writeappend(clob_buf_2, k, text_2_byte);
    i := i + k;
  end loop;
  --dbms_output.put_line('clob_2 2-byte buffer, chars = ' || to_char(dbms_lob.getlength(clob_buf_2)));
  
  i := 0;
  k := lengthb(text_1_byte);
  while i + k < VARCHAR2_1_BYTE_MAX_SIZE loop
    var_buf_1 := var_buf_1 || text_1_byte;
    i := i + k;
  end loop;
  --dbms_output.put_line('var_1 1-byte buffer, bytes = ' || to_char(lengthb(var_buf_1)));
  
  i := 0;
  k := lengthc(text_2_byte);
  while i + k < VARCHAR2_2_CHAR_MAX_SIZE loop
    var_buf_2 := var_buf_2 || text_2_byte;
    i := i + k;
  end loop;
  --dbms_output.put_line('var_2 2-byte buffer, bytes = ' || to_char(lengthb(var_buf_2)));

  /* expected buffer sizes
  clob_1 1-byte buffer, chars = 262136
  clob_2 2-byte buffer, chars = 262080
  var_1 1-byte buffer, bytes = 31992
  var_2 2-byte buffer, bytes = 9984
  */
  
  /* json with
  1 clob string of ~ 256K 1-byte chars
  1 clob string of ~ 256K 2-byte chars
  1 varchar2 string of 32767 1-byte chars
  1 varchar2 string of 5000 2-byte chars
  */
  str := 'json with clob(s), varchar2(s) both 1-byte, 2-byte chars using to_clob()';
  begin
    test_json := json();
    test_json.put('publish', true);
    test_json.put('issueDate', to_char(sysdate, 'YYYY-MM-DD"T"HH24:MI:SS'));
    test_json.put('clob_1', json_value(clob_buf_1));
    test_json.put('clob_2', json_value(clob_buf_2));
    test_json.put('var_1', var_buf_1);
    test_json.put('var_2', var_buf_2);
  
    dbms_lob.createtemporary(json_clob, TRUE, dbms_lob.SESSION);
    dbms_lob.trim(json_clob, 0);
  
    test_json.to_clob(json_clob);
    assertTrue(dbms_lob.getlength(json_clob) = 1896666);

    --dbms_output.put_line('test all kinds of big strings, clob final chars = ' || to_char(dbms_lob.getlength(json_clob)));
    pass(str); 
    dbms_lob.freetemporary(json_clob);
  exception
    when others then
      fail(str);
      if dbms_lob.istemporary(json_clob) = 1 then
        dbms_lob.freetemporary(json_clob);
      end if;
  end;
  
  dbms_lob.freetemporary(clob_buf_1);
  dbms_lob.freetemporary(clob_buf_2);
  
  /* json with
  1 varchar2 string of 32767 1-byte chars
  */
  str := 'json with varchar2 string of 32767 1-byte chars using to_char()';
  begin
    test_json := json();
    test_json.put('var_1', var_buf_1);
    json_var := test_json.to_char();
    assertTrue(lengthb(json_var) = 32014);
  
    --dbms_output.put_line('test 1 varchar2 string of 32000 1-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
    pass(str); 
  exception
    when others then fail(str);
  end;
  
  /* json with
  1 varchar2 string of 5000  2-byte chars
  */
  str := 'json with varchar2 string of 5000 2-byte chars using to_char()';
  begin 
    test_json := json();
    test_json.put('var_2', var_buf_2);
    json_var := test_json.to_char();
    assertTrue(lengthb(json_var) = 29974);
  
    --dbms_output.put_line('test 1 varchar2 string of 5000 2-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
    pass(str); 
  exception
    when others then fail(str);
  end;
  
  /* json list with many small strings of 62 1-byte chars
     but up to 32767 bytes total
  */
  str := 'json list with many small strings of 62 1-byte chars using to_char()';
  begin
    test_json := json();
    test_json_list := json_list();
    --before commit 97d72ca with extra CR NL at end
    --for i in 1..496 loop
    for i in 1..480 loop
      test_json_list.append(json_value(text_1_byte));
    end loop;
    test_json.put('array', test_json_list);
    json_var := test_json.to_char();
    assertTrue(lengthb(json_var) = 32658);
  
    --dbms_output.put_line('test list of 1-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
    pass(str); 
  exception
    when others then fail(str);
  end;
  
  /* json list with many small strings of 64 2-byte chars
     but up to 32767 bytes total
  */
  str := 'json list with many small strings of 64 2-byte chars using to_char()';
  begin
    test_json := json();
    test_json_list := json_list();
    for i in 1..83 loop
      test_json_list.append(json_value(text_2_byte));
    end loop;
    test_json.put('array', test_json_list);
    json_var := test_json.to_char();
    assertTrue(lengthb(json_var) = 32388);
  
    --dbms_output.put_line('test list of 2-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
    pass(str); 
  exception
    when others then fail(str);
  end;
  
  t_stop := SYSTIMESTAMP;
  t_sec := extract(second from t_stop - t_start);
  dbms_output.put_line('total sec = ' || to_char(t_sec));
  
  /* 
  expected output

  clob_1 1-byte buffer, chars = 262136
  clob_2 2-byte buffer, chars = 262080
  var_1 1-byte buffer, bytes = 31992
  var_2 2-byte buffer, bytes = 9984
  test all kinds of big strings, clob final chars = 1896666
  test 1 varchar2 string of 32000 1-byte chars, varchar2 final bytes = 32014 -- was 32012 before commit 97d72ca
  test 1 varchar2 string of 5000 2-byte chars, varchar2 final bytes = 29974 -- was 29972 before commit 97d72ca
  test list of 1-byte chars, varchar2 final bytes = 32658 -- was 32754 before commit 97d72ca
  test list of 2-byte chars, varchar2 final bytes = 32388 -- was 32222 before commit 97d72ca
  total sec = [4.8 - 5.2 sec on old Pentium 2.80 GHz development machine]
  */
  begin
    execute immediate 'insert into json_testsuite values (:1, :2, :3, :4, :5)' using
    'json unicode test', pass_count,fail_count,total_count,'json_unicode_test.sql';
--  exception
--    when others then null;
  end;
end;
/
