/*
  E.I.Sarmas (github.com/dsnz)   2016-01-25
  
  set of 5 tests exercising correct Unicode support and big strings
  for both clob and varchar2 api versions
  test should not produce ORA-06502 error
  must run with NLS_LANG='AMERICAN_AMERICA.AL32UTF8'
*/

PROMPT did you run with NLS_LANG='AMERICAN_AMERICA.AL32UTF8' ?

set serveroutput on size 20000 format wrapped

declare
  test_json pljson;
  test_json_list pljson_list;
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
  
  ascii_output_saved_setting boolean;
  
  t_start timestamp;
  t_stop  timestamp;
  t_sec number;
  
  function time_diff(a timestamp, b timestamp) return number is 
  begin
    return extract (day    from (a-b))*24*60*60 +
           extract (hour   from (a-b))*60*60+
           extract (minute from (a-b))*60+
           extract (second from (a-b));
  end;
  
begin
  
  pljson_ut.testsuite('pljson_unicode test', 'pljson_unicode.test.sql');
  
  --%beforeall
  t_start := SYSTIMESTAMP;
  
  -- save ascii_output setting
  ascii_output_saved_setting := pljson_printer.ascii_output;
  -- default setting
  pljson_printer.ascii_output := true;
  
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
  -- json with clob(s), varchar2(s) both 1-byte, 2-byte chars using to_clob()
  pljson_ut.testcase('Test json with clob(s), varchar2(s) both 1-byte, 2-byte chars using to_clob()');
  begin
    test_json := pljson();
    test_json.put('publish', true);
    test_json.put('issueDate', to_char(sysdate, 'YYYY-MM-DD"T"HH24:MI:SS'));
    test_json.put('clob_1', pljson_value(clob_buf_1));
    test_json.put('clob_2', pljson_value(clob_buf_2));
    test_json.put('var_1', var_buf_1);
    test_json.put('var_2', var_buf_2);
    
    dbms_lob.createtemporary(json_clob, TRUE, dbms_lob.SESSION);
    dbms_lob.trim(json_clob, 0);
    
    test_json.to_clob(json_clob);
    --dbms_output.put_line('test all kinds of big strings, clob final chars = ' || to_char(dbms_lob.getlength(json_clob)));
    
    pljson_ut.assertTrue(dbms_lob.getlength(json_clob) = 1896656, 'dbms_lob.getlength(json_clob) = 1896656');
    
    dbms_lob.freetemporary(json_clob);
  end;
  
  dbms_lob.freetemporary(clob_buf_1);
  dbms_lob.freetemporary(clob_buf_2);
  
  /* json with
  1 varchar2 string of 32767 1-byte chars
  */
  -- json with varchar2 string of 32767 1-byte chars using to_char()
  pljson_ut.testcase('Test json with varchar2 string of 32767 1-byte chars using to_char()');
  begin
    test_json := pljson();
    test_json.put('var_1', var_buf_1);
    json_var := test_json.to_char();
    --dbms_output.put_line('test 1 varchar2 string of 32000 1-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
    
    pljson_ut.assertTrue(lengthb(json_var) = 32012, 'lengthb(json_var) = 32012');
  end;
  
  /* json with
  1 varchar2 string of 5000  2-byte chars
  */
  -- json with varchar2 string of 5000 2-byte chars using to_char()
  pljson_ut.testcase('Test json with varchar2 string of 5000 2-byte chars using to_char()');
  begin
    test_json := pljson();
    test_json.put('var_2', var_buf_2);
    json_var := test_json.to_char();
    --dbms_output.put_line('test 1 varchar2 string of 5000 2-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
    
    pljson_ut.assertTrue(lengthb(json_var) = 29972, 'lengthb(json_var) = 29972');
  end;
  
  /* json list with many small strings of 62 1-byte chars
     but up to 32767 bytes total
  */
  -- json list with many small strings of 62 1-byte chars using to_char()
  pljson_ut.testcase('Test json list with many small strings of 62 1-byte chars using to_char()');
  begin
    test_json := pljson();
    test_json_list := pljson_list();
    --before commit 97d72ca with extra CR NL at end
    --for i in 1..496 loop
    for i in 1..480 loop
      test_json_list.append(pljson_value(text_1_byte));
    end loop;
    test_json.put('array', test_json_list);
    json_var := test_json.to_char();
    --dbms_output.put_line('test list of 1-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
    
    pljson_ut.assertTrue(lengthb(json_var) = 31698, 'lengthb(json_var) = 31698');
  end;
  
  /* json list with many small strings of 64 2-byte chars
     but up to 32767 bytes total
  */
  -- json list with many small strings of 64 2-byte chars using to_char()
  pljson_ut.testcase('Test json list with many small strings of 64 2-byte chars using to_char()');
  begin
    test_json := pljson();
    test_json_list := pljson_list();
    for i in 1..83 loop
      test_json_list.append(pljson_value(text_2_byte));
    end loop;
    test_json.put('array', test_json_list);
    json_var := test_json.to_char();
    --dbms_output.put_line('test list of 2-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
    
    pljson_ut.assertTrue(lengthb(json_var) = 32222, 'lengthb(json_var) = 32222');
  end;
  
  -- creation of json from blob
  pljson_ut.testcase('Test creation of json from blob');
  declare
    json_char varchar2(4000) := '{"'||text_2_byte||'":"'||text_2_byte||'"}';
    json_raw varchar2(4000) := utl_i18n.string_to_raw(json_char,'AL32UTF8');
    b blob;
  begin
    dbms_lob.createtemporary(b, true);
    dbms_lob.writeappend(b, utl_raw.length(json_raw), json_raw);
    test_json := pljson(b);
    dbms_lob.freetemporary(b);
    
    --dbms_output.put_line(test_json.to_char(false));
    
    pljson_printer.ascii_output := false;
    pljson_ut.assertTrue(json_char = test_json.to_char(false), 'json_char = test_json.to_char(false)');
    -- default setting
    pljson_printer.ascii_output := true;
  end;
  
  --%afterall
  -- restore ascii_output setting
  pljson_printer.ascii_output := ascii_output_saved_setting;
  
  t_stop := SYSTIMESTAMP;
  t_sec := time_diff(t_stop, t_start);
  dbms_output.put_line('total sec = ' || to_char(t_sec));
  
  /*
  expected output
  
  clob_1 1-byte buffer, chars = 262136
  clob_2 2-byte buffer, chars = 262080
  var_1 1-byte buffer, bytes = 31992
  var_2 2-byte buffer, bytes = 9984
  test all kinds of big strings, clob final chars = 1896656
  test 1 varchar2 string of 32000 1-byte chars, varchar2 final bytes = 32012
  test 1 varchar2 string of 5000 2-byte chars, varchar2 final bytes = 29972
  test list of 1-byte chars, varchar2 final bytes = 31698
  test list of 2-byte chars, varchar2 final bytes = 32222
  total sec = [4.8 - 5.2 sec on old Pentium 2.80 GHz development machine]
  */
  
  pljson_ut.testsuite_report;
  
end;
/