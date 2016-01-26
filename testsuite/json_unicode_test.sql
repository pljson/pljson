/*
  set of 5 tests exercising correct Unicode support and big strings for both clob and varchar2 api versions
  test should not produce ORA-06502 error
*/
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
  VARCHAR2_2_BYTE_MAX_SIZE NUMBER := 10000; /* allow some space for json markup */
  i NUMBER;
  k NUMBER;
  t_start timestamp;
  t_stop  timestamp;
  t_sec NUMBER;
begin

  t_start := SYSTIMESTAMP;
  
  /* json with
  1 clob string of ~ 256K 1-byte chars
  1 clob string of ~ 256K 2-byte chars
  1 varchar2 string of 32767 1-byte chars
  1 varchar2 string of 5000  2-byte chars
  */
  dbms_lob.createtemporary(clob_buf_1, TRUE, dbms_lob.SESSION);
  dbms_lob.trim(clob_buf_1, 0);
  k := length(text_1_byte);
  i := 0;
  while i + k < CLOB_MAX_SIZE loop
    dbms_lob.writeappend(clob_buf_1, k, text_1_byte);
    i := i + k;
  end loop;
  dbms_output.put_line('clob_1 1-byte buffer, chars = ' || to_char(dbms_lob.getlength(clob_buf_1)));
  
  dbms_lob.createtemporary(clob_buf_2, TRUE, dbms_lob.SESSION);
  dbms_lob.trim(clob_buf_2, 0);
  k := length(text_2_byte);
  i := 0;
  while i + k < CLOB_MAX_SIZE loop
    dbms_lob.writeappend(clob_buf_2, k, text_2_byte);
    i := i + k;
  end loop;
  dbms_output.put_line('clob_2 2-byte buffer, chars = ' || to_char(dbms_lob.getlength(clob_buf_2)));
  
  i := 0;
  k := lengthb(text_1_byte);
  while i + k < VARCHAR2_1_BYTE_MAX_SIZE loop
    var_buf_1 := var_buf_1 || text_1_byte;
    i := i + k;
  end loop;
  dbms_output.put_line('var_1 1-byte buffer, bytes = ' || to_char(lengthb(var_buf_1)));
  
  i := 0;
  k := lengthb(text_2_byte);
  while i + k < VARCHAR2_2_BYTE_MAX_SIZE loop
    var_buf_2 := var_buf_2 || text_2_byte;
    i := i + k;
  end loop;
  dbms_output.put_line('var_2 2-byte buffer, bytes = ' || to_char(lengthb(var_buf_2)));
  
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
  dbms_output.put_line('test all kinds of big strings, clob final chars = ' || to_char(dbms_lob.getlength(json_clob)));
    
  dbms_lob.freetemporary(clob_buf_1);
  dbms_lob.freetemporary(clob_buf_2);
  dbms_lob.freetemporary(json_clob);
  
  /* json with
  1 varchar2 string of 32767 1-byte chars
  */
  
  test_json := json();
  test_json.put('var_1', var_buf_1);

  json_var := test_json.to_char();
  
  dbms_output.put_line('test 1 varchar2 string of 32000 1-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
  
  /* json with
  1 varchar2 string of 5000 2-byte chars
  */
  
  test_json := json();
  test_json.put('var_2', var_buf_2);

  json_var := test_json.to_char();
  
  dbms_output.put_line('test 1 varchar2 string of 5000 2-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
  
  /* json list with many small strings of 62 1-byte characters
     but up to 32767 bytes total
  */
  test_json := json();
  test_json_list := json_list();
  for i in 1..496 loop
    test_json_list.append(json_value(text_1_byte));
  end loop;
  test_json.put('array', test_json_list);
  json_var := test_json.to_char();
  
  dbms_output.put_line('test list of 1-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
  
  /* json list with many small strings of 64 2-byte characters
     but up to 32767 bytes total
  */
  test_json := json();
  test_json_list := json_list();
  for i in 1..83 loop
    test_json_list.append(json_value(text_2_byte));
  end loop;
  test_json.put('array', test_json_list);
  json_var := test_json.to_char();
  
  dbms_output.put_line('test list of 2-byte chars, varchar2 final bytes = ' || to_char(lengthb(json_var)));
  
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
  test 1 varchar2 string of 32000 1-byte chars, varchar2 final bytes = 32012
  test 1 varchar2 string of 5000 2-byte chars, varchar2 final bytes = 29972
  test list of 1-byte chars, varchar2 final bytes = 32754
  test list of 2-byte chars, varchar2 final bytes = 32222
  total sec = [4.8 - 5.2 sec on old Pentium 2.80 GHz development machine]

  */
end;
/
